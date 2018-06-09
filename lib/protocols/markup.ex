defimpl String.Chars, for: Tuple do
  def to_string(elem), do: to_markup(elem)

  defp to_markup({:variable, value}), do: Enum.join(value)

  defp to_markup({:parts, value}) do
    value |> Enum.join(".") |> String.replace(".[", "[")
  end

  defp to_markup({:index, value}) when is_binary(value), do: "[\"#{value}\"]"

  defp to_markup({:index, value}), do: "[#{value}]"

  defp to_markup({:value, value}) when is_binary(value), do: "\"#{value}\""

  defp to_markup({:assignments, value}), do: Enum.join(value, ", ")

  defp to_markup({:filters, value}), do: " | " <> Enum.join(value, " | ")

  defp to_markup({:filter, value}), do: Enum.join(value)

  defp to_markup({:params, value}), do: ": " <> Enum.join(value, ", ")

  defp to_markup({:assignment, value}), do: Enum.join(value)

  defp to_markup({:logical, [key, value]}), do: " #{key} #{normalize_value(value)} "

  defp to_markup({:condition, {left, op, right}}),
    do: "#{normalize_value(left)} #{op} #{normalize_value(right)}"

  defp to_markup({:evaluation, [nil]}), do: "null"

  defp to_markup({:evaluation, [value]}) when is_bitstring(value), do: "\"#{value}\""

  defp to_markup({:evaluation, value}), do: Enum.join(value)

  defp to_markup({predicate, value}) when predicate in [:for, :with],
    do: "#{predicate} #{Enum.join(value)}"

  defp to_markup({_, nil}), do: "null"
  defp to_markup({_, value}), do: "#{value}"

  # This is to manage the strings and nulls to string 
  defp normalize_value(value) when is_nil(value) do
    {:null, nil}
  end

  defp normalize_value(value) when is_bitstring(value) do
    "\"#{value}\""
  end

  defp normalize_value(value) do
    value
  end
end
