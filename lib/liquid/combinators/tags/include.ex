defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include enables the possibility to include and render other liquid templates. Templates can also be recursively included
  """
  import NimbleParsec
  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tag

  def tag, do: Tag.define_open("include", &head/1)

  defp assignments do
    General.codepoints().colon
    |> General.assignment()
    |> tag(:assignment)
    |> times(min: 1)
    |> tag(:assignments)
  end

  defp snippet do
    parsec(:ignore_whitespaces)
    |> ignore(utf8_char([General.codepoints().single_quote]))
    |> parsec(:variable_value)
    |> ignore(utf8_char([General.codepoints().single_quote]))
    |> parsec(:ignore_whitespaces)
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
