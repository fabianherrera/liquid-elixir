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
  Parses a `Liquid` Elsif tag, creates a Keyword list where the key is the name of the tag
  (elsif in this case) and the value is the result of the `body_elsif()` combinator.
  """
  @spec elsif_tag() :: NimbleParsec.t()
  def elsif_tag do
    "elsif"
    |> Tag.open_tag(&predicate/1)
    |> concat(body_elsif())
    |> tag(:elsif)
    |> optional(parsec(:__parse__))
  end

  @doc """
  Parses a `Liquid` Unless tag, creates a Keyword list where the key is the name of the tag
  (unless in this case) and the value is another keyword list, that represent the internal
  structure of the tag.
  """
  @spec unless_tag() :: NimbleParsec.t()
  def unless_tag, do: do_tag("unless")

  @doc """
  Parses a `Liquid` If tag, creates a Keyword list where the key is the name of the tag
  (if in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag, do: do_tag("if")

  defp body do
    empty()
    |> optional(parsec(:__parse__))
    |> optional(repeat(parsec(:elsif_tag)))
    |> optional(repeat(Generic.else_tag()))
    |> tag(:body)
  end

  @doc """
  Parses a Elsif body, creates a Keyword list with key `body:` and the value is another keyword list, that behaves like a if body.
  """
  @spec body_elsif() :: NimbleParsec.t()
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
