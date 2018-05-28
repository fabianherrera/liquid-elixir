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
  def render({:ok, [""], _rest, _, _, _}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def render({:ok, [literal_text], _rest, _, _, _}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def render({:ok, nodelist, _rest, _, _, _}) when is_list(nodelist) do
    me = self()

    # |> remove_empty_items()
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

    # |> remove_empty_items()
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

  defp process_node({:raw, markup}) do
    value = markup |> hd
    %Liquid.Block{name: :raw, nodelist: value, strict: false}
  end

  defp process_node({:comment, markup}) do
    ""
  end

  defp process_node(any) do
    any
  end

  # defp remove_empty_items(nodelist) do
  #   nodelist
  #   |> Enum.filter(fn x -> x != "" end)
  # end

  defp variable_to_string(variable_in_parts) do
    Enum.join(variable_in_parts, ".")
    |> String.replace(".[", "[")
  end

  defp variable_parts(list) do
    Enum.map(list, &variable_in_parts(&1))
  end

  defp variable_in_parts(value) do
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
    value = Keyword.get(filter_param_value, :value)
    "| #{filter_name}: #{value}"
  end
end
