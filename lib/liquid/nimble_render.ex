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

  defp process_node({:if, markup}) do
    list = process_node(markup)

    case list do
      [condition, nodelist] ->
        cond do
          is_tuple(condition) == true ->
            condition_struct = condition |> elem(0)
            condition_markup = condition |> elem(1)

          is_map(condition) ->
            %Liquid.Variable{name: name} = condition
            condition_markup = name
            condition_struct = %Liquid.Condition{left: condition}

          true ->
            condition_markup = "#{condition}"
            variable = %Liquid.Variable{name: "#{condition}", literal: condition}
            condition_struct = %Liquid.Condition{left: variable}
        end

        %Liquid.Block{
          name: :if,
          markup: condition_markup,
          nodelist: [nodelist],
          condition: condition_struct
        }

      [condition, nodelist, else_tag] ->
        if is_tuple(condition) do
          condition_struct = condition |> elem(0)
          condition_markup = condition |> elem(1)
        else
          condition_markup = "#{condition}"
          variable = %Liquid.Variable{name: "#{condition}", literal: condition}
          condition_struct = %Liquid.Condition{left: variable}
        end

        %Liquid.Block{
          name: :if,
          markup: condition_markup,
          nodelist: [nodelist],
          condition: condition_struct,
          elselist: else_tag |> elem(1)
        }
    end

    # if [condition, nodelist] = list do
    #   if is_tuple(condition) do
    #     condition_struct = condition |> elem(0)
    #     condition_markup = condition |> elem(1)
    #   else
    #     condition_markup = "#{condition}"
    #     variable = %Liquid.Variable{name: "#{condition}", literal: condition}
    #     condition_struct = %Liquid.Condition{left: variable}
    #   end

    #   %Liquid.Block{
    #     name: :if,
    #     markup: condition_markup,
    #     nodelist: [nodelist],
    #     condition: condition_struct
    #   }
    # else
    # [condition, nodelist, else_tag] = list
    # else_tag

    # if is_tuple(condition) do
    #   condition_struct = condition |> elem(0)
    #   condition_markup = condition |> elem(1)
    # else
    #   condition_markup = "#{condition}"
    #   variable = %Liquid.Variable{name: "#{condition}", literal: condition}
    #   condition_struct = %Liquid.Condition{left: variable}

    #   %Liquid.Block{
    #     name: :if,
    #     markup: condition_markup,
    #     nodelist: [nodelist],
    #     condition: condition_struct,
    #     elselist: "culo"
    #   }
    # end
    # end
  end

  defp process_node({:condition, markup}) do
    {left, operator, right} = markup

    if is_tuple(left) do
      left_value = process_node(left)
      variable_value = left |> elem(1)
      variable_in_string = variable_to_string(variable_value)
    else
      left_value = %Liquid.Variable{name: "'#{left}'", literal: left}
      name_left = "'#{left}'"
    end

    if is_tuple(right) do
      right_value = process_node(right)
      name = right
    else
      right_value = %Liquid.Variable{name: "'#{right}'", literal: right}
      name = "'#{right}'"
    end

    {%Liquid.Condition{left: left_value, right: right_value, operator: operator},
     "#{variable_in_string} #{operator} #{name}"}
  end

  defp process_node(:else, markup) do
    markup
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
end
