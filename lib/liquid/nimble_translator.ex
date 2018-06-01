defmodule Liquid.NimbleTranslator do
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

  defp process_node({:liquid_variable, markup}) do
    literal = markup |> hd

    if is_tuple(literal) do
      {key, value} = literal
      literal_have_filters = Enum.any?(value, fn x -> have_filters(x) end)

      if literal_have_filters == true do
        variable_list = literal |> elem(1)
        variable_name = variable_list |> hd
        filters_list = Enum.filter(variable_list, fn x -> is_tuple(x) == true end)
        filters = transform_filters(filters_list)
        %Liquid.Variable{name: variable_name, parts: [variable_name], filters: filters}
      else
        variable_list = literal |> elem(1)
        filters = transform_filters(markup)
        parts = Enum.map(variable_list, &variable_in_parts(&1))
        name = variable_to_string(parts)
        %Liquid.Variable{name: name, parts: parts, filters: filters}
      end
    else
      if is_number(literal) or is_boolean(literal) do
        variable_name = "#{literal}"
      else
        variable_name = "'#{literal}'"
      end

      filters_list = Enum.filter(markup, fn x -> is_tuple(x) == true end)
      filters = transform_filters(filters_list)
      %Liquid.Variable{name: variable_name, literal: literal, filters: filters}
    end
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
        [variable, value] = markup
        variable_name = variable |> elem(1)
        variable_tuple = value |> elem(1)

        if is_tuple(variable_tuple) do
          variable_value = variable_tuple |> elem(1)
          string_variable = variable_value |> hd
          filters_list = Enum.filter(variable_value, fn x -> is_tuple(x) == true end)

          filters =
            Keyword.get_values(filters_list, :filter)
            |> Enum.map(&filters_to_string(&1))
            |> List.to_string()

          %Liquid.Tag{
            name: :assign,
            markup: "#{variable_name} = #{string_variable} #{filters}",
            blank: true
          }
        else
          if is_number(variable_tuple) or is_boolean(variable_tuple) do
            %Liquid.Tag{
              name: :assign,
              markup: "#{variable_name} = #{variable_tuple}",
              blank: true
            }
          else
            %Liquid.Tag{
              name: :assign,
              markup: "#{variable_name} = '#{variable_tuple}'",
              blank: true
            }
          end
        end

      length(markup) > 2 ->
        variable_name = Keyword.get(markup, :variable_name)
        value = Keyword.get(markup, :value)

        filters =
          Keyword.get_values(markup, :filter)
          |> Enum.map(&filters_to_string(&1))
          |> List.to_string()

        %Liquid.Tag{
          name: :assign,
          markup: "#{variable_name} = #{value} #{filters}",
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

  defp process_node({:if, [if_condition: if_condition, body: body]}) do
    nodelist = Enum.filter(body, &not_open_if(&1))

    else_list =
      Enum.filter(body, fn x ->
        (is_tuple(x) and x |> elem(0) == :elsif) or (is_tuple(x) and x |> elem(0) == :else)
      end)

    markup_list = if_markup_to_string(if_condition)
    markup_string = List.to_string(markup_list)

    block = %Liquid.Block{
      name: :if,
      markup: markup_string,
      nodelist: process_node(nodelist),
      elselist: process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end

  defp process_node({:variable, markup}) do
    filters_list = Enum.filter(markup, fn x -> have_filters(x) == true end)
    filters = transform_filters(filters_list)
    variable_list = Enum.filter(markup, fn x -> have_filters(x) == false end)
    parts = Enum.map(variable_list, &variable_in_parts(&1))
    name = variable_to_string(parts)
    %Liquid.Variable{name: name, parts: parts, filters: filters}
  end

  defp process_node({:elsif, [if_condition: if_condition, body: body]}) do
    nodelist = Enum.filter(body, &not_open_if(&1))

    else_list =
      Enum.filter(body, fn x ->
        (is_tuple(x) and x |> elem(0) == :elsif) or (is_tuple(x) and x |> elem(0) == :else)
      end)

    markup_list = if_markup_to_string(if_condition)
    markup_string = List.to_string(markup_list)

    block = %Liquid.Block{
      name: :if,
      markup: markup_string,
      nodelist: process_node(nodelist),
      elselist: process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end

  defp process_node({:else, markup}) do
    process_node(markup)
  end

  defp process_node({:include, markup}) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: "#{variable_name}"}
  end

  defp process_node({:comment, _markup}) do
    %Liquid.Block{name: :comment, blank: true, strict: false}
  end

  defp process_node({:include, markup}) do
    markup = process_include_markup(markup)
    Liquid.Include.parse(%Tag{markup: markup, name: :include})
  end

  defp process_node({:for, [for_collection: for_collection, for_body: for_body, else: else_body]}) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      elselist: fixer_for_types_no_list(process_node(else_body)),
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(process_node(for_body))
    }
  end

  defp process_node({:for, [for_collection: for_collection, for_body: for_body]}) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(process_node(for_body))
    }
  end

  def variable_to_string(variable_in_parts) do
    Enum.join(variable_in_parts, ".")
    |> String.replace(".[", "[")
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

  defp filters_to_string({filter_name}) do
    "| #{filter_name} "
  end

  defp filters_to_string({filter_name, filter_param}) do
    filter_param_value = filter_param |> elem(1)
    value = Keyword.get(filter_param_value, :value)
    "| #{filter_name}: '#{value}'"
  end

  defp transform_filters(filters_list) do
    Keyword.get_values(filters_list, :filter)
    |> Enum.map(&filters_to_list(&1))
  end

  defp filters_to_list({filter_name}) do
    [String.to_atom(filter_name), []]
  end

  defp filters_to_list({filter_name, filter_param}) do
    filter_param_value = filter_param |> elem(1)
    value = Keyword.get(filter_param_value, :value)
    [String.to_atom(filter_name), ["#{value}"]]
  end

  defp have_filters(value) when is_binary(value) or is_number(value) or is_boolean(value) do
    false
  end

  defp have_filters(value) when is_tuple(value) do
    if value |> elem(0) == :filter do
      true
    else
      false
    end
  end

  defp not_open_if(value) when is_binary(value) or is_number(value) or is_boolean(value) do
    true
  end

  defp not_open_if(value) when is_tuple(value) do
    if value |> elem(0) == :if_condition or value |> elem(0) == :else or
         value |> elem(0) == :elsif do
      false
    else
      true
    end
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

  defp process_for_markup(for_collection) do
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

  defp if_markup_to_string(if_list) do
    Enum.map(if_list, fn x ->
      case x do
        {:variable, value} ->
          parts = Enum.map(value, &variable_in_parts(&1))
          variable_name = variable_to_string(parts)
          variable_name

        {:logical, values} ->
          [logical_op, content] = values

          if is_tuple(content) do
            variable_name = content |> elem(1)
            variable_name
          else
            variable_name = "#{content}"
          end

          " #{logical_op} #{variable_name}"

        {:condition, {left, operator, right}} ->
          if is_tuple(left) do
            variable_list_left = left |> elem(1)
            parts_left = Enum.map(variable_list_left, &variable_in_parts(&1))
            variable_name_left = variable_to_string(parts_left)
          else
            variable_name_left = "#{left}"
          end

          if is_tuple(right) do
            variable_list_right = right |> elem(1)
            parts_right = Enum.map(variable_list_right, &variable_in_parts(&1))
            variable_name_right = variable_to_string(parts_right)
          else
            variable_name_right = "#{right}"
          end

          "#{variable_name_left} #{operator} #{variable_name_right}"

        value ->
          " #{value}"
      end
    end)
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_no_list(element) do
    if is_list(element), do: List.first(element), else: element
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end

  def process_include_markup(snippet: [snippet]), do: snippet

  def process_include_markup(snippet: [snippet], with_param: [variable: [variable]]),
    do: "#{snippet} with #{variable}"

  def process_include_markup(snippet: [snippet], for_param: [variable: [variable]]),
    do: "#{snippet} for #{variable}"

  def process_include_markup(snippet: [snippet], variables: variables) do
    parts = Enum.map(variables, &concat_include_variables_in_markup(&1))
    variables = Enum.join(parts, ", ")
    "#{snippet}, #{variables}"
  end

  defp concat_include_variables_in_markup({:variable, [variable_name: [variable], value: value]}),
    do: "#{variable} '#{value}'"

<<<<<<< HEAD:lib/liquid/nimble_render.ex
  defp concat_include_variables_in_markup(
         {:variable, [variable_name: [variable], value: {:variable, [value]}]}
       ),
       do: "#{variable} #{value}"
=======
  defp process_node({:if, [if_condition: if_condition, body: body]}) do
    nodelist = Enum.filter(body, &not_open_if(&1))

    else_list =
      Enum.filter(body, fn x ->
        (is_tuple(x) and x |> elem(0) == :elsif) or (is_tuple(x) and x |> elem(0) == :else)
      end)

    markup_list = if_markup_to_string(if_condition)
    markup_string = List.to_string(markup_list)

    block = %Liquid.Block{
      name: :if,
      markup: markup_string,
      nodelist: process_node(nodelist),
      elselist: process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end

  defp process_node({:elsif, [if_condition: if_condition, body: body]}) do
    nodelist = Enum.filter(body, &not_open_if(&1))

    else_list =
      Enum.filter(body, fn x ->
        (is_tuple(x) and x |> elem(0) == :elsif) or (is_tuple(x) and x |> elem(0) == :else)
      end)

    markup_list = if_markup_to_string(if_condition)
    markup_string = List.to_string(markup_list)

    block = %Liquid.Block{
      name: :if,
      markup: markup_string,
      nodelist: process_node(nodelist),
      elselist: process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end

  defp process_node({:else, markup}) do
    process_node(markup)
  end

  defp not_open_if(value) when is_binary(value) or is_number(value) or is_boolean(value) do
    true
  end

  defp not_open_if(value) when is_tuple(value) do
    if value |> elem(0) == :if_condition or value |> elem(0) == :else or
    value |> elem(0) == :elsif do
      false
    else
      true
    end
  end

  defp process_node({:liquid_variable, markup}) do
    literal = markup |> hd

    if is_tuple(literal) do
      {key, value} = literal
      literal_have_filters = Enum.any?(value, fn x -> have_filters(x) end)

      if literal_have_filters == true do
        variable_list = literal |> elem(1)
        variable_name = variable_list |> hd
        filters_list = Enum.filter(variable_list, fn x -> is_tuple(x) == true end)
        filters = transform_filters(filters_list)
        %Liquid.Variable{name: variable_name, parts: [variable_name], filters: filters}
      else
        variable_list = literal |> elem(1)
        filters = transform_filters(markup)
        parts = Enum.map(variable_list, &variable_in_parts(&1))
        name = variable_to_string(parts)
        %Liquid.Variable{name: name, parts: parts, filters: filters}
      end
    else
      if is_number(literal) or is_boolean(literal) do
        variable_name = "#{literal}"
      else
        variable_name = "'#{literal}'"
      end

      filters_list = Enum.filter(markup, fn x -> is_tuple(x) == true end)
      filters = transform_filters(filters_list)
      %Liquid.Variable{name: variable_name, literal: literal, filters: filters}
    end
  end

  defp if_markup_to_string(if_list) do
    Enum.map(if_list, fn x ->
      case x do
        {:variable, value} ->
          parts = Enum.map(value, &variable_in_parts(&1))
          variable_name = variable_to_string(parts)
          variable_name

        {:logical, values} ->
          [logical_op, content] = values

          if is_tuple(content) do
            variable_name = content |> elem(1)
            variable_name
          else
            variable_name = "#{content}"
          end

          " #{logical_op} #{variable_name}"

        {:condition, {left, operator, right}} ->
          if is_tuple(left) do
            variable_list_left = left |> elem(1)
            parts_left = Enum.map(variable_list_left, &variable_in_parts(&1))
            variable_name_left = variable_to_string(parts_left)
          else
            variable_name_left = "#{left}"
          end

          if is_tuple(right) do
            variable_list_right = right |> elem(1)
            parts_right = Enum.map(variable_list_right, &variable_in_parts(&1))
            variable_name_right = variable_to_string(parts_right)
          else
            variable_name_right = "#{right}"
          end

          "#{variable_name_left} #{operator} #{variable_name_right}"

        value ->
          " #{value}"
      end
    end)
  end

  defp have_filters(value) when is_binary(value) or is_number(value) or is_boolean(value) do
    false
  end

  defp have_filters(value) when is_tuple(value) do
    if value |> elem(0) == :filter do
      true
    else
      false
    end
  end

  defp transform_filters(filters_list) do
    Keyword.get_values(filters_list, :filter)
    |> Enum.map(&filters_to_list(&1))
  end

  defp filters_to_list({filter_name}) do
    [String.to_atom(filter_name), []]
  end

  defp filters_to_list({filter_name, filter_param}) do
    filter_param_value = filter_param |> elem(1)
    value = Keyword.get(filter_param_value, :value)
    [String.to_atom(filter_name), ["#{value}"]]
  end

  defp process_node(any) do
    any
  end
>>>>>>> upstream/WIP:lib/liquid/nimble_translator.ex
end
