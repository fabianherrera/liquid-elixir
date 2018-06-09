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
  alias Liquid.Combinators.Tag
  alias Liquid.Combinators.Tags.Generic

  def elsif_tag, do: Tag.define_end("elsif", &predicate/1)

  def unless_tag, do: Tag.define_closed_test("unless", &predicate/1)

  def tag, do: Tag.define_closed_test("if", &predicate/1)

  def body_if do
    empty()
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(Generic.else_tag(), min: 1))
    |> tag(:body)
  end

  def body(combinator) do
    combinator
    |> optional(parsec(:__parse__))
    |> optional(times(parsec(:elsif_tag), min: 1))
    |> optional(times(Generic.else_tag(), min: 1))
    |> tag(:body)
  end

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

  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endif"))
    |> parsec(:end_tag)
  end

  defp predicate(combinator) do
    combinator
    |> choice([
      parsec(:condition),
      parsec(:value_definition),
      parsec(:variable_definition)
    ])
    |> optional(times(parsec(:logical_condition), min: 1))
    |> tag(:evaluation)
  end
end
