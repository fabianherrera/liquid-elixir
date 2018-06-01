defmodule Liquid.Combinators.Tags.Include do
  @moduledoc """
  Include allows templates to relate with other templates
  """
  import NimbleParsec
  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tag

  def tag do
    Tag.define_open("include", &head/1)
  end

  def var_assignment do
    General.cleaned_comma()
    |> concat(variable_atom())
    |> parsec(:value)
    |> tag(:variables)
    |> optional(parsec(:var_assignment))
  end

  defp snippet do
    parsec(:ignore_whitespaces)
    |> concat(utf8_char([General.codepoints().single_quote]))
    |> parsec(:variable_definition)
    |> ascii_char([General.codepoints().single_quote])
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:snippet)
  end

  defp variable_atom do
    empty()
    |> parsec(:ignore_whitespaces)
    |> parsec(:variable_definition)
    |> concat(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> reduce({List, :to_string, []})
    |> tag(:variable_name)
  end

  defp with_param do
    empty()
    |> ignore(string("with"))
    |> parsec(:value_definition)
    |> tag(:with_param)
  end

  defp for_param do
    empty()
    |> ignore(string("for"))
    |> concat(parsec(:value_definition))
    |> tag(:for_param)
  end

  defp head(combinator) do
    combinator
    |> concat(snippet())
    |> optional(choice([with_param(), for_param(), var_assignment()]))
  end
end
