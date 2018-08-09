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

  @spec variable_in_parts(Liquid.Combinators.LexicalToke.variable_value()) :: String.t()
  def variable_in_parts(variable) do
    Enum.map(variable, fn {key, value} ->
      case key do
        :part -> string_have_question("#{value}")
        :index -> "[#{value}]"
        _ -> "[#{value}]"
      end
    end)
  end

  @doc """
  Liquid use the  `?` symbol for variables as  a instructions, the new parser takes the symbol as a part of the name of the variable, in order to render the variable is needed  to take  out the symbol of the name , this fuction does that.
  """

  @spec string_have_question(String.t()) :: String.t()
  def string_have_question(value) when is_bitstring(value) do
    if String.contains?(value, "?") do
      String.replace(value, "?", "")
    else
      "#{value}"
    end
  end

  @doc """
  This is a helper function to identify if a tuple is and Else/Elseif tag
  """
  @spec is_else(Tuple.t()) :: Boolean.t()
  def is_else({:else, _}), do: true
  def is_else({:elsif, _}), do: true
  def is_else(_), do: false

  @doc """
  This is a helper function to identify if a tuple is a If tag
  """
  @spec not_open_if(Tuple.t()) :: Boolean.t()
  def not_open_if({:evaluation, _}), do: false
  def not_open_if({:else, _}), do: false
  def not_open_if({:elsif, _}), do: false
  def not_open_if(_), do: true

  @doc """
  This is a helper function that if the value is a list extract only the first element of a list ,if not create a list with that element
  """
  @spec types_no_list(List.t()) :: String.t() | Number.t()
  def types_no_list([]), do: []

  def types_no_list(element) do
    if is_list(element), do: List.first(element), else: element
  end

  def types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end
end
