defimpl String.Chars, for: Tuple do
  def to_string(elem), do: to_markup(elem)

  # copied
  defp to_markup({:parts, value}) do
    value |> Enum.join(".") |> String.replace(".[", "[")
  end


  # copied
  defp to_markup({:index, value}) when is_binary(value), do: "[\"#{value}\"]"


  # copied
  defp to_markup({:index, value}), do: "[#{value}]"

  # copied
  defp to_markup({:value, value}) when is_binary(value), do: "\"#{value}\""

  # copied
  defp to_markup({:filters, value}), do: " | " <> Enum.join(value, " | ")

  # copied
  defp to_markup({:params, value}), do: ": " <> Enum.join(value, ", ")

  defp to_markup({:logical, [key, value]}), do: " #{key} #{normalize_value(value)} "

  # copied
  defp to_markup({:assignment, [name | value]}), do: "#{name}: #{Enum.join(value)}"

  defp to_markup({:condition, {left, op, right}}),
    do: "#{normalize_value(left)} #{op} #{normalize_value(right)}"

  defp to_markup({:conditions, [nil]}), do: "null"

  defp to_markup({:conditions, [value]}) when is_bitstring(value), do: "\"#{value}\""

  defp to_markup({predicate, value}) when predicate in [:for, :with],
    do: "#{predicate} #{Enum.join(value)}"

  defp to_markup({:start, value}), do: "(#{value}."

  defp to_markup({:end, value}), do: ".#{value})"

  defp to_markup({parameter, value}) when parameter in [:offset, :limit, :cols],
    do: " #{parameter}: #{Enum.join(value)}"

  defp to_markup({:reversed, _value}), do: " reversed"

  defp to_markup({_, nil}), do: "null"

  defp to_markup({_, value}) when is_list(value), do: Enum.join(value)

  # copied
  defp to_markup({_, value}), do: "#{value}"

  # This is to manage the strings and nulls to string
  defp normalize_value(value) when is_nil(value), do: {:null, nil}
  defp normalize_value(value) when is_bitstring(value), do: "\"#{value}\""
  defp normalize_value(value), do: value
end
