defmodule Liquid.Combinators.Tags.Case do
  import NimbleParsec
  alias Liquid.Combinators.Tag
  alias Liquid.Combinators.Tags.Generic

  def tag, do: Tag.define_closed("case", &head/1, &body/1)

  defp when_tag do
    Tag.define_open("when", fn combinator ->
      combinator
      |> choice([
        parsec(:condition),
        parsec(:value_definition),
        parsec(:variable_definition)
      ])
      |> optional(times(parsec(:logical_condition), min: 1))
    end)
  end

  def whens do
    empty()
    |> times(when_tag(), min: 1)
    |> tag(:whens)
  end

  defp head(combinator) do
    combinator
    |> choice([
      parsec(:condition),
      # TO-DO: nill to string is "" and the potocolls does by default 
      parsec(:null_value) |> unwrap_and_tag(:null),
      parsec(:value_definition),
      parsec(:variable_definition)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
  end

  defp body(combinator) do
    combinator
    |> optional(parsec(:__parse__))
    |> optional(parsec(:whens))
    |> parsec(:ignore_whitespaces)
    |> optional(times(Generic.else_tag(), min: 1))
  end
end
