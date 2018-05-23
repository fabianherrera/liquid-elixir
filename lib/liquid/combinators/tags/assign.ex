defmodule Liquid.Combinators.Tags.Assign do
  @moduledoc """
  Sets variables in a template
  ```
    {% assign foo = 'monkey' %}
  ```
  User can then use the variables later in the page
  ```
    {{ foo }}
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.Tag

  def tag do
    empty()
    |> parsec(:start_tag)
    |> concat(ignore(string("assign")))
    |> concat(parsec(:variable_name))
    |> concat(ignore(string("=")))
    |> concat(parsec(:value))
    |> optional(parsec(:filter))
    |> concat(parsec(:end_tag))
    |> tag(:assign)
    |> optional(parsec(:__parse__))
    Tag.define(:assign, fn combinator ->
      combinator
      |> concat(parsec(:variable_name))
      |> concat(ignore(string("=")))
      |> concat(parsec(:value))
    end)
  end
end
