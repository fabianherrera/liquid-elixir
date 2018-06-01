defmodule Liquid.NimbleRender do
  @moduledoc """
  Intermediate Render Liquid module, it serves as render-nimble_parse interface
  """
  alias Liquid.{
    Template,
    Render,
    Context,
    Block,
    Registers,
    Variable,
    Tag,
    Expression,
    RangeLookup,
    Condition,
    ForElseCondition
  }

  @doc """
  Function that converts passed nimble_parser AST into valid intermediate render's template and context to string
  """
  def render({:ok, [""]}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def render({:ok, [literal_text]}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def render({:ok, nodelist}) when is_list(nodelist) do
    me = self()

    list =
      nodelist
      |> Enum.map(fn elem ->
        spawn_link(fn -> send(me, {self(), process_node(elem)}) end)
      end)
      |> Enum.map(fn pid ->
        receive do
          {^pid, result} -> result
        end
      end)

    %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  # When the element its a string literal text
  defp process_node(elem) when is_bitstring(elem) do
    elem
  end

  # When the element its one string literal text inside a list
  defp process_node([elem]) when is_bitstring(elem) do
    elem
  end

  # When the element its a tuple
  # defp process_node([elem]) when is_tuple(elem) do
  # elem
  # end

  # When the element its a list
  defp process_node(nodelist) when is_list(nodelist) do
    me = self()

    nodelist
    |> Enum.map(fn elem ->
      spawn_link(fn -> send(me, {self(), process_node(elem)}) end)
    end)
    |> Enum.map(fn pid ->
      receive do
        {^pid, result} -> result
      end
    end)
  end

  defp process_node({:variable, markup}) do
    parts = variable_parts(markup)
    name = variable_to_string(parts)
    %Liquid.Variable{name: name, parts: parts}
  end

  defp process_node({:increment, markup}) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :increment, markup: "#{variable_name}"}
  end

  defp process_node({:decrement, markup}) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: "#{variable_name}"}
  end

  defp process_node({:capture, markup}) do
    variable_name = Keyword.get(markup, :variable_name)
    capture_sentences = Keyword.get(markup, :capture_sentences)
    nodelist = process_node(capture_sentences)
    %Liquid.Block{name: :capture, markup: variable_name, blank: true, nodelist: nodelist}
  end

  defp process_node({:cycle, markup}) do
    value = Enum.join(markup, ", ")
    {name, values} = Liquid.Cycle.get_name_and_values(value)
    %Liquid.Tag{name: :cycle, markup: value, parts: [name | values]}
  end

  defp process_node({:assign, markup}) do
    cond do
      length(markup) == 2 ->
        value = Keyword.get(markup, :value)
        variable_name = Keyword.get(markup, :variable_name)

        if is_tuple(value) do
          variable = value |> elem(1)
          string_variable = variable_parts(variable) |> variable_to_string()

          %Liquid.Tag{
            name: :assign,
            markup: "#{variable_name} = #{string_variable}",
            blank: true
          }
        else
          %Liquid.Tag{name: :assign, markup: "#{variable_name} = #{value}", blank: true}
        end

      length(markup) > 2 ->
        value = Keyword.get(markup, :value)
        variable_name = Keyword.get(markup, :variable_name)
        variable = value |> elem(1)
        string_variable = variable_parts(variable) |> variable_to_string()

        filters =
          Keyword.get_values(markup, :filter)
          |> Enum.map(&filters_to_string(&1))
          |> List.to_string()

        %Liquid.Tag{
          name: :assign,
          markup: "#{variable_name} = #{string_variable} #{filters}",
          blank: true
        }
    end
  end

  defp process_node({:include, markup}) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: "#{variable_name}"}
  end

  defp process_node({:comment, _markup}) do
    %Liquid.Block{name: :comment, blank: true, strict: false}
  end

  defp process_node({:for, [for_collection: for_collection, for_body: for_body, else: else_body]}) do
    markup = process_markup(for_collection)

    %Liquid.Block{
      elselist: fixer_for_types_no_list(process_node(else_body)),
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(process_node(for_body))
    }
  end

  defp process_node({:for, [for_collection: for_collection, for_body: for_body]}) do
    markup = process_markup(for_collection)

    %Liquid.Block{
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(process_node(for_body))
    }
  end

  defp process_node(any) do
    any
  end

  def variable_to_string(variable_in_parts) do
    Enum.join(variable_in_parts, ".")
    |> String.replace(".[", "[")
  end

  defp variable_parts(list) do
    Enum.map(list, &variable_in_parts(&1))
  end

  def variable_in_parts(value) do
    cond do
      is_binary(value) == true ->
        "#{value}"

      is_tuple(value) == true ->
        position = value |> elem(1)
        "[#{position}]"

      is_float(value) == true ->
        "#{value}"

      is_integer(value) == true ->
        "#{value}"
    end
  end

  defp filters_to_string([filter_name]) do
    "| #{filter_name} "
  end

  defp filters_to_string([filter_name, filter_atom]) do
    filter_param_value = filter_atom |> elem(1)
    value = Keyword.get(filter_param_value, :value) |> variable_parts() |> variable_to_string()
    "| #{filter_name}: #{value}"
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

  defp process_markup(for_collection) do
    variable = Keyword.get(for_collection, :variable_name)
    value = concat_for_value_in_markup(Keyword.get(for_collection, :value))
    range_value = concat_for_value_in_markup(Keyword.get(for_collection, :range_value))
    for_param = concat_for_params_in_markup(for_collection)
    "#{variable} in #{value}#{range_value}" <> for_param
  end

  defp concat_for_value_in_markup(value) when is_nil(value), do: ""

  defp concat_for_value_in_markup({:variable, values}) do
    parts = Enum.map(values, &variable_in_parts(&1))
    value_string = variable_to_string(parts)
    value_string
  end

  defp concat_for_value_in_markup(start: start_range, end: end_range) do
    "(#{to_string(start_range)}..#{to_string(end_range)})"
  end

  defp concat_for_params_in_markup(for_collection) do
    offset_param = Keyword.get(for_collection, :offset_param)
    limit_param = Keyword.get(for_collection, :limit_param)
    reversed_param = Keyword.get(for_collection, :reversed_param)

    offset_string =
      if is_nil(offset_param), do: "", else: " offset:#{to_string(List.first(offset_param))}"

    limit_string =
      if is_nil(limit_param), do: "", else: " limit:#{to_string(List.first(limit_param))}"

    reversed_string = if is_nil(reversed_param), do: "", else: " reversed"
    "#{reversed_string}#{offset_string}#{limit_string}"
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_no_list(element) do
    if is_list(element), do: List.first(element), else: element
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end
end
