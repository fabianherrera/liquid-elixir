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
    Tag.define_open("assign", fn combinator ->
      combinator
      |> parsec(:variable_name)
      |> ignore(string("="))
      |> parsec(:value)
      |> optional(parsec(:filters))
    end)
  end
end
