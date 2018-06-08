defimpl String.Chars, for: Tuple do
  def to_string(elem), do: to_markup(elem)

  defp to_markup({:variable, value}), do: Enum.join(value)

  defp to_markup({:parts, value}) do
    value |> Enum.join(".") |> String.replace(".[", "[")
  end

  defp to_markup({:index, value}) when is_binary(value), do: "[\"#{value}\"]"

  defp to_markup({:index, value}), do: "[#{value}]"

  defp to_markup({:filters, _}), do: ""

  defp to_markup({:value, value}) when is_binary(value), do: "\"#{value}\""

  defp to_markup({:assignments, value}), do: Enum.join(value, ", ")

  defp to_markup({:assignment, value}), do: Enum.join(value)

  defp to_markup({predicate, value}) when predicate in [:for, :with], do: "#{predicate} #{Enum.join(value)}"

  defp to_markup({_, value}), do: "#{value}"
end
