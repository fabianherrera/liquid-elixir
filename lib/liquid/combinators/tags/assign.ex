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
      |> parsec(:variable_name_for_assignation)
      |> ignore(string("="))
      |> parsec(:value)
    end)
  end
end
