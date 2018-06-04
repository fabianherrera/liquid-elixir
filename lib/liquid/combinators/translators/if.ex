defmodule Liquid.Combinators.Translators.If do
  alias Liquid.Combinators.Translators.General

  def translate(if_condition: if_condition, body: body) do
    nodelist = Enum.filter(body, &not_open_if(&1))
    else_list = Enum.filter(body, &is_else/1)
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

  defp if_markup_to_string(if_list) do
    Enum.map(if_list, fn x ->
      case x do
        {:variable, [parts: parts]} ->
          parts = General.variable_in_parts(parts)
          variable_name = General.variable_to_string(parts)
          variable_name

        {:logical, values} ->
          logical_to_string(values)

        {:condition, value} ->
          condition_to_string(value)

        value ->
          General.values_to_string(value)
      end
    end)
  end

  defp is_else({:else, _}), do: true
  defp is_else({:elsif, _}), do: true
  defp is_else(_), do: false

  defp not_open_if({:if_condition, _}), do: false
  defp not_open_if({:else, _}), do: false
  defp not_open_if({:else_if, _}), do: false
  defp not_open_if(_), do: true

  defp condition_to_string({left, operator, right}) do
    left_var = General.values_to_string(left)
    right_var = General.values_to_string(right)
    left_var <> " #{operator} " <> right_var
  end

  defp logical_to_string([logical_op, logical_statement]) do
    logical_string =
      case logical_statement do
        {:variable, variable_parts: _} = variable ->
          General.values_to_string(variable)

        {:condition, value} ->
          condition_to_string(value)

        any ->
          General.values_to_string(any)
      end

    " #{logical_op} #{logical_string}"
  end
end
