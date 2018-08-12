defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include enables the possibility to include and render other liquid templates
  Templates can also be recursively included
  """
  import NimbleParsec
  alias Liquid.Combinators.{Tag, General}

  @type t :: [
          include: Include.markup()
        ]

  @type markup :: [
          variable_name: String.t(),
          params: [assignment: [variable_name: String.t(), value: LexicalToken.value()]]
        ]

  def tag, do: Tag.define_open("include", &head/1)

  defp params do
    General.codepoints().colon
    |> General.assignment()
    |> tag(:assignment)
    |> times(min: 1)
    |> tag(:params)
  end

  defp predicate(name) do
    empty()
    |> ignore(string(name))
    |> parsec(:value_definition)
    |> tag(String.to_atom(name))
  end

  defp head(combinator) do
    combinator
    |> parsec(:quoted_variable_name)
    |> optional(choice([predicate("with"), predicate("for"), params()]))
  end
end
