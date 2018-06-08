defimpl String.Chars, for: Tuple do
  def to_string(elem), do: to_markup(elem)

  defp to_markup({:variable, value}), do: Enum.join(value)

  defp to_markup({:parts, value}) do
    value |> Enum.join(".") |> String.replace(".[", "[")
  end

  defp to_markup({:part, value}), do: "#{value}"

  defp to_markup({:index, value}) when is_binary(value), do: "[\"#{value}\"]"

  defp to_markup({:index, value}), do: "[#{value}]"

  defp to_markup({:filters, value}), do: ""

  defp to_markup({:name, value}), do: "#{value}:"

  defp to_markup({:value, value}) when is_binary(value), do: "\"#{value}\""

  defp to_markup({:value, value}), do: "#{value}"

  defp to_markup({:with_include, value}), do: "with #{Enum.join(value)}"

  defp to_markup({:for_include, value}), do: "for #{Enum.join(value)}"

  defp to_markup({:attributes, value}), do: Enum.join(value, ", ")

  defp to_markup({:assignment, value}), do: Enum.join(value)

  defp to_markup({_, value}), do: "#{value}"
end
