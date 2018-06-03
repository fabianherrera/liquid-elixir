defmodule Liquid.Combinators.Translators.General do
  @moduledoc false
  def variable_in_parts(variable) do
    Enum.map(variable, fn {key, value} ->
      if key == :part, do: "#{value}", else: "[#{value}]"
    end)
  end

  def variable_to_string(parts) do
    parts |> Enum.join() |> String.replace(".[", "[")
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