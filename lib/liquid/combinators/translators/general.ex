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
      if key == :part, do: "#{value}", else: "[#{value}]"
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
end
