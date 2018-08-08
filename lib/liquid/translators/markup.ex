defmodule Liquid.Translators.Markup do
  @moduledoc """
  Transform AST to String
  """

  def literal(elem) when is_list(elem) do
    elem
    |> Enum.map(&literal/1)
    |> Enum.join()
  end

  def literal({_, value}), do: literal(value)
  def literal(elem), do: elem
end
