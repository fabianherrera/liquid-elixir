defmodule Liquid.Translators.Markup do
  @moduledoc """
  Transform AST to String
  """

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
  def literal({_, value}), do: literal(value)
  def literal(elem), do: "#{elem}"
end
