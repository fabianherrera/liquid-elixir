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
  alias Liquid.Combinators.{Tag, General}
  alias Liquid.Combinators.Tags.Generic

  def tag, do: Tag.define_closed("case", &General.conditions/1, &body/1)

  def clauses do
    empty()
    |> times(when_tag(), min: 1)
    |> tag(:clauses)
  end

  defp when_tag do
    "when"
    |> Tag.open_tag(&General.conditions/1)
    |> tag(:statements)
    |> concat(tag(optional(parsec(:__parse__)), :value_if_true))
    |> tag(:when)
  end

  defp body(combinator) do
    combinator
    |> optional(parsec(:__parse__))
    |> optional(parsec(:clauses))
    |> parsec(:ignore_whitespaces)
    |> optional(times(Generic.else_tag(), min: 1))
  end
end
