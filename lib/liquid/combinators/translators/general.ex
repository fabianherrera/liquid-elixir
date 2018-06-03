defmodule Liquid.Combinators.Translators.General do
  @moduledoc false

  def variable(markup) do
    parts = Enum.map(markup, &variable_in_parts/1)
    name = variable_to_string(parts)
    %Liquid.Variable{name: name, parts: parts}
  end

  def variable_in_parts(tuple) do
    {key, value} = tuple

    cond do
      key == :part ->
        "#{value}"

      key == :index ->
        "[#{value}]"
    end
  end

  def variable_to_string(variable_in_parts) do
    Enum.join(variable_in_parts, ".")
    |> String.replace(".[", "[")
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
