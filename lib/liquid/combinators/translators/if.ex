defmodule Liquid.Combinators.Translators.If do
  alias Liquid.Combinators.Translators.General

  def translate(if_condition: if_condition, body: body) do
    nodelist = Enum.filter(body, &not_open_if(&1))

    else_list =
      Enum.filter(body, fn x ->
        (is_tuple(x) and elem(x, 0) == :elsif) or (is_tuple(x) and elem(x, 0) == :else)
      end)

    markup_list = if_markup_to_string(if_condition)
    markup_string = List.to_string(markup_list)

    block = %Liquid.Block{
      name: :if,
      markup: markup_string,
      nodelist: Liquid.NimbleTranslator.process_node(nodelist),
      elselist: Liquid.NimbleTranslator.process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end

  defp not_open_if({:if_condition, _}), do: false
  defp not_open_if({:else, _}), do: false
  defp not_open_if({:else_if, _}), do: false
  defp not_open_if(_), do: true

  defp if_markup_to_string(if_list) do
    Enum.map(if_list, fn x ->
      case x do
        {:variable, value} ->
          parts = Enum.map(value, &General.variable_in_parts/1)
          variable_name = General.variable_to_string(parts)
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
            parts_left = Enum.map(variable_list_left, &General.variable_in_parts/1)
            variable_name_left = General.variable_to_string(parts_left)
          else
            variable_name_left = "#{left}"
          end

          if is_tuple(right) do
            variable_list_right = right |> elem(1)
            parts_right = Enum.map(variable_list_right, &General.variable_in_parts/1)
            variable_name_right = General.variable_to_string(parts_right)
          else
            variable_name_right = "#{right}"
          end

          "#{variable_name_left} #{operator} #{variable_name_right}"

        value ->
          " #{value}"
      end
    end)
  end
end
