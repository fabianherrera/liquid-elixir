defmodule Liquid.Combinators.Tags.If do
  @moduledoc """
  Executes a block of code only if a certain condition is true.
  If this condition is false executes `else` block of code.
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

  @type t :: [if: conditional_body()]
  @type unless_tag :: [unless: conditional_body()]
  @type conditional_body :: [
          conditions: General.conditions(),
          body: [
            Liquid.NimbleParser.t()
            | [elsif: conditional_body()]
            | [else: Liquid.NimbleParser.t()]
          ]
        ]

  @doc """
  Parse a `Liquid` Elsif tag.
  """
  def elsif_tag do
    "elsif"
    |> Tag.open_tag(&predicate/1)
    |> parsec(:body_elsif)
    |> tag(:elsif)
    |> optional(parsec(:__parse__))
  end

  @doc """
  Parse a `Liquid` Unless tag.
  """
  def unless_tag, do: do_tag("unless")

  @doc """
  Parse a `Liquid` If tag.
  """
  def tag, do: do_tag("if")

  defp body do
    empty()
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(Generic.else_tag(), min: 1))
    |> tag(:body)
  end

  @doc """
  Parse Elsif body.
  """
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
    Tag.define_closed(name, &predicate/1, fn combinator -> concat(combinator, body()) end)
  end

  defp predicate(combinator) do
    combinator
    |> General.conditions()
    |> tag(:conditions)
  end
end
