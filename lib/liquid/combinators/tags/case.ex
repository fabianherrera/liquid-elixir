defmodule Liquid.Combinators.Tags.Case do
  @moduledoc """
  Creates a switch statement to compare a variable against different values.
  `case` initializes the switch statement, and `when` compares its values.
  Input:
  ```
    {% assign handle = 'cake' %}
    {% case handle %}
    {% when 'cake' %}
      This is a cake
    {% when 'cookie' %}
      This is a cookie
    {% else %}
      This is not a cake nor a cookie
    {% endcase %}
  ```
  Output:
  ```
    This is a cake
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag, do: Tag.define_closed("case", &head/1, &body/1)

  defp when_tag do
    Tag.define_open("when", fn combinator ->
      combinator
      |> choice([
        parsec(:condition),
        parsec(:value_definition),
        parsec(:quoted_token),
        parsec(:variable_definition)
      ])
      |> optional(
        times(choice([parsec(:logical_condition), parsec(:comma_contition_value)]), min: 1)
      )
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
      parsec(:value_definition),
      parsec(:quoted_token),
      parsec(:variable_definition)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
  end

  defp body(combinator) do
    combinator
    |> choice([parsec(:whens), parsec(:__parse__)])
    |> parsec(:ignore_whitespaces)
    |> optional(times(parsec(:else_tag), min: 1))
  end
end
