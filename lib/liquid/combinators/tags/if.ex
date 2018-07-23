defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Executes a block of code only if a certain condition is true.
  If this condition is false executes `else` block of code
  Input:
  ```
    {% if product.title == 'Awesome Shoes' %}
      These shoes are awesome!
    {% else %}
      These shoes are ugly!
    {% endif %}
  ```
  Output:
  ```
    These shoes are ugly!
  ```
  """

  import NimbleParsec
  alias Liquid.Combinators.{Tag, General}
  alias Liquid.Combinators.Tags.Generic

  @type elsif_tag :: [body: elsif_body | Liquid.NimbleParser.__parse__()]
  def elsif_tag do
    "elsif"
    |> Tag.open_tag(&predicate/1)
    |> parsec(:body_elsif)
    |> tag(:elsif)
    |> optional(parsec(:__parse__))
  end

  @type unless_tag :: [
          unless: [
            conditions: if_predicate,
            body: if_body,
            elsif: elsif_tag,
            else: Generic.else_tag()
          ]
        ]

  def unless_tag, do: do_tag("unless")

  @type if_tag :: [
          if: [
            conditions: if_predicate,
            body: if_body,
            elsif: elsif_tag,
            else: Generic.else_tag()
          ]
        ]

  def tag, do: do_tag("if")

  @type if_body :: [
          body: [Liquid.NimbleParser.__parse__() | elsif_tag | Generic.else_tag()]
        ]

  def body do
    empty()
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(Generic.else_tag(), min: 1))
    |> tag(:body)
  end

  @type elsif_body :: [
          body: [Liquid.NimbleParser.__parse__() | elsif_tag | Generic.else_tag()]
        ]

  def body_elsif do
    empty()
    |> choice([
      times(parsec(:elsif_tag), min: 1),
      Generic.else_tag(),
      parsec(:__parse__)
    ])
    |> optional(choice([parsec(:elsif_tag), Generic.else_tag()]))
    |> tag(:body)
  end

  defp do_tag(name) do
    Tag.define_closed(name, &predicate/1, fn combinator -> parsec(combinator, :body_if) end)
  end

  @type if_predicate :: [
          conditions: [
            condition:
              {LexicalToken.value(), General.comparison_operators(), LexicalToken.value()}
          ]
        ]

  defp predicate(combinator) do
    combinator
    |> General.conditions()
    |> tag(:conditions)
  end
end
