defmodule Liquid.Translators.Markup do
  @moduledoc """
  Transform AST to String
  """

  @doc """
  Takes the New (NimbleParser) AST and creates a String and use it as a markup for the old AST
  """
  @spec literal(list() | tuple()) :: String.t()
  def literal(elem, join_with) when is_list(elem) do
    elem
    |> Enum.map(&literal/1)
    |> Enum.join(join_with)
  end

  def literal({:parts, value}) do
    value |> literal(".") |> String.replace(".[", "[")
  end

  def literal(elem) when is_list(elem), do: literal(elem, "")
  def literal({:index, value}) when is_binary(value), do: "[\"#{literal(value)}\"]"
  def literal({:index, value}), do: "[#{literal(value)}]"
  def literal({:value, value}) when is_binary(value), do: "\"#{literal(value)}\""
  def literal({:filters, value}), do: " | " <> literal(value, " | ")
  def literal({:params, value}), do: ": " <> literal(value, ", ")
  def literal({:assignment, [name | value]}), do: "#{name}: #{literal(value)}"

  def literal({:logical, [operator, value]}), do: " #{operator} #{literal(value)}"

  def literal({:condition, {left, op, right}}),
    do: "#{normalize_value(left)} #{op} #{normalize_value(right)}"

  def literal({:conditions, [nil]}), do: "null"
  def literal({:conditions, [value]}) when is_bitstring(value), do: "\"#{literal(value)}\""

  def literal({predicate, value}) when predicate in [:for, :with],
    do: "#{predicate} #{literal(value)}"

  def literal({:start, value}), do: "(#{literal(value)}."

  def literal({:end, value}), do: ".#{literal(value)})"

  def literal({parameter, value}) when parameter in [:offset, :limit, :cols],
    do: " #{parameter}: #{literal(value)}"

  def literal({:reversed, _value}), do: " reversed"

  def literal({_, nil}), do: "null"

  def literal({_, value}), do: literal(value)
  def literal(elem), do: "#{elem}"

  # This is to manage the strings and nulls to string
  defp normalize_value(value) when is_nil(value), do: {:null, nil}
  defp normalize_value(value) when is_bitstring(value), do: "\"#{literal(value)}\""
  defp normalize_value(value), do: value
end
