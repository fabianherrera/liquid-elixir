defmodule Liquid.Translators.General do
  @moduledoc false

  @doc """
  Returns a corresponding type value:

  Simple Value Type:
  {variable: [parts: [part: "i"]]} -> "i"
  {variable: [parts: [part: "products", part: "tittle"]]} -> "product.tittle"
  {variable: [parts: [part: "product", part: "tittle", index: 0]]} -> "product.tittle[0]"
   "string_value" -> "'string_value'"
    2 -> "2"

  Complex Value Type:
  {:range, [start: "any_simple_type", end: "any_simple_type"]} -> "(any_simple_type..any_simple_type)"

  """

  def variable_in_parts(variable) do
    Enum.map(variable, fn {key, value} ->
      case key do
        :part -> string_have_question("#{value}")
        :index -> "[#{value}]"
        _ -> "[#{value}]"
      end
    end)
  end

  def string_have_question(value) when is_bitstring(value) do
    if String.contains?(value, "?") do
      String.replace(value, "?", "")
    else
      "#{value}"
    end
  end

  def is_else({:else, _}), do: true
  def is_else({:elsif, _}), do: true
  def is_else(_), do: false

  def not_open_if({:evaluation, _}), do: false
  def not_open_if({:else, _}), do: false
  def not_open_if({:elsif, _}), do: false
  def not_open_if(_), do: true

  def types_no_list([]), do: []

  def types_no_list(element) do
    if is_list(element), do: List.first(element), else: element
  end

  def types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end
end
