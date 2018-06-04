defmodule Liquid.Combinators.Translators.General do
  @moduledoc false

  @doc """
  Returns a corresponding type value:

  Simple Value Type:
  {variable: [parts: [part: "i"]]} -> "i"
  {variable: [parts: [part: "products", part: "tittle"]]} -> "product.tittle"
  {variable: [parts: [part: "product", part: "tittle", index: 0]]} -> "product.tittle[0]"
   "string_value" -> "'string_value'"
    2 -> "2"

  Complex Value Type:
  {:range, [start: "any_simple_type", end: "any_simple_type"]} -> "(any_simple_type..any_simple_type)"

  """
  # @spec values_to_string(value :: binary() | list() | string() | integer()) :: string.t()
  def values_to_string(value) when is_bitstring(value) do
    "'#{value}'"
  end

  def values_to_string(value) when is_number(value) do
    to_string(value)
  end

  def values_to_string(value) when is_boolean(value) do
    to_string(value)
  end

  def values_to_string({:range, [start: start_range, end: end_range]}) do
    start_range_string = values_to_string(start_range)
    end_range_string = values_to_string(end_range)
    "(#{to_string(start_range_string)}..#{to_string(end_range_string)})"
  end

  def values_to_string({:variable, [parts: parts]}) do
    value_parts = variable_in_parts(parts)
    value_string = variable_to_string(value_parts)
    value_string
  end

  def values_to_string([value]) when is_number(value) do
    to_string(value)
  end

  def values_to_string(value) do
    if value == nil do
      "null"
    else
      "#{value}"
    end
  end

  def variable_in_parts(variable) do
     Enum.map(variable, fn {key, value} ->
       case key do
        :part ->  "#{value}"
        :index -> "[#{values_to_string(value)}]"
        _ -> "[#{value}]"
       end
       end)
  end

  def variable_to_string(parts) do
    parts |> Enum.join(".") |> String.replace(".[", "[")
  end

  def filters_to_string({:filter, [name]}) when is_binary(name) do
    "| " <> name <> " "
  end

  def filters_to_string({:filter, [name, {:params, values}]}) do
    if length(values) > 1 do
      value_list = Enum.map(values, &filter_param_values_to_string(&1))
      value = Enum.join(value_list, ", ")
      "| " <> name <> ": #{value}"
    else
      [{_key, value}] = values

      cond do
        is_bitstring(value) -> "| " <> name <> ": '#{value}'"
        true -> "| " <> name <> ": #{value}"
      end
    end
  end

  defp filter_param_values_to_string({_key, value}) do
    to_string(value)
  end

  def if_markup_to_string(if_list) do
    Enum.map(if_list, fn x ->
      case x do
        {:variable, [parts: _]} = variable ->
          values_to_string(variable)

        {:logical, values} ->
          logical_to_string(values)

        {:condition, value} ->
          condition_to_string(value)

        value ->
          values_to_string(value)
      end
    end)
  end

  def is_else({:else, _}), do: true
  def is_else({:elsif, _}), do: true
  def is_else(_), do: false

  def not_open_if({:if_condition, _}), do: false
  def not_open_if({:else, _}), do: false
  def not_open_if({:else_if, _}), do: false
  def not_open_if(_), do: true

  defp condition_to_string({left, operator, right}) do
    left_var = values_to_string(left)
    right_var = values_to_string(right)
    left_var <> " #{operator} " <> right_var
  end

  defp logical_to_string([logical_op, logical_statement]) do
    logical_string =
      case logical_statement do
        {:variable, variable_parts: _} = variable ->
          values_to_string(variable)

        {:condition, value} ->
          condition_to_string(value)

        any ->
          values_to_string(any)
      end

    " #{logical_op} #{logical_string}"
  end
end
