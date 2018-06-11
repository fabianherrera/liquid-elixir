defmodule Liquid.Combinators.Translators.Cycle do
  alias Liquid.Combinators.Translators.General

  def translate(cycle_values: cycle_values) do
    parts = Enum.map(cycle_values, &cycle_to_string/1)
    markup = Enum.join(parts, ", ")
    %Liquid.Tag{name: :cycle, markup: markup, parts: [markup | parts]}
  end

  def translate(cycle_group: [cycle_group_value], cycle_values: cycle_values) do
    cycle_value_in_parts = Enum.map(cycle_values, &cycle_to_string/1)
    markup = cycle_group_value <> ": " <> Enum.join(cycle_value_in_parts, ", ")
    parts = [cycle_group_value | cycle_value_in_parts]

    %Liquid.Tag{name: :cycle, markup: markup, parts: parts}
  end

  defp cycle_to_string(value) when is_bitstring(value), do: "'#{value}'"
  defp cycle_to_string(nil), do: "null"
  defp cycle_to_string(value), do: "#{value}"
end
