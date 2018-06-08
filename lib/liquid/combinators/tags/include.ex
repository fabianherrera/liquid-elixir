defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include allows templates to relate with other templates
  """
  import NimbleParsec
  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tag

  def tag, do: Tag.define_open("include", &head/1)

  def assignment do
    empty()
    |> optional(General.cleaned_comma())
    |> concat(variable())
    |> parsec(:value)
    |> tag(:assignment)
    |> optional(parsec(:assignment))
  end

  defp assignments do
    parsec(:assignment)
    |> tag(:assignments)
  end

  defp snippet do
    parsec(:ignore_whitespaces)
    |> ignore(utf8_char([General.codepoints().single_quote]))
    |> parsec(:variable_value)
    |> ignore(utf8_char([General.codepoints().single_quote]))
    |> parsec(:ignore_whitespaces)
  end

  defp variable do
    empty()
    |> parsec(:variable_definition)
    |> parsec(:ignore_whitespaces)
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:name)
  end

  defp predicate(name) do
    empty()
    |> ignore(string(name))
    |> parsec(:value_definition)
    |> tag(String.to_atom(name))
  end

  defp head(combinator) do
    combinator
    |> concat(snippet())
    |> optional(ignore(string(",")))
    |> optional(choice([predicate("with"), predicate("for"), assignments()]))
  end
end
