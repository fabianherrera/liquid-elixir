defmodule Liquid.Combinators.Tags.For do
  @moduledoc """
  "for" tag iterates over an array or collection.
  Several useful variables are available to you within the loop.

  Basic usage:
  ```
    {% for item in collection %}
      {{ forloop.index }}: {{ item.name }}
    {% endfor %}
  ```
  Advanced usage:
  ```
    {% for item in collection %}
      <div {% if forloop.first %}class="first"{% endif %}>
      Item {{ forloop.index }}: {{ item.name }}
      </div>
    {% else %}
      There is nothing in the collection.
    {% endfor %}
  ```
  You can also define a limit and offset much like SQL.  Remember
  that offset starts at 0 for the first item.
  ```
    {% for item in collection limit:5 offset:10 %}
      {{ item.name }}
    {% end %}
  ```
  To reverse the for loop simply use {% for item in collection reversed %}

  Available variables:
  ```
    forloop.name:: 'item-collection'
    forloop.length:: Length of the loop
    forloop.index:: The current item's position in the collection;
    forloop.index starts at 1.
    This is helpful for non-programmers who start believe
    the first item in an array is 1, not 0.
    forloop.index0:: The current item's position in the collection
    where the first item is 0
    forloop.rindex:: Number of items remaining in the loop
    (length - index) where 1 is the last item.
    forloop.rindex0:: Number of items remaining in the loop
    where 0 is the last item.
    forloop.first:: Returns true if the item is the first item.
    forloop.last:: Returns true if the item is the last item.
    forloop.parentloop:: Provides access to the parent loop, if present.
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag}
  alias Liquid.Combinators.Tags.Generic

  @type t :: [
          for: [
            for_statements: [
              variable: String.t(),
              value: LexicalToken.value(),
              for_params: [
                [offset: Integer.t() | String.t()]
                | [limit: Integer.t() | String.t()]
              ],
              for_body:
                Liquid.t()
                | Generic.else_tag()
            ]
          ]
        ]

  defp reversed_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("reversed"))
    |> parsec(:ignore_whitespaces)
    |> tag(:reversed)
  end

  defp for_params do
    empty()
    |> optional(
      times(
        choice([General.tag_param("offset"), General.tag_param("limit"), reversed_param()]),
        min: 1
      )
    )
    |> tag(:for_params)
  end

  defp for_body do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:for_body)
  end

  def continue_tag, do: Tag.define_open("continue")

  def break_tag, do: Tag.define_open("break")

  def tag, do: Tag.define_closed("for", &for_statements/1, &body/1)

  defp body(combinator) do
    combinator
    |> concat(for_body())
    |> optional(Generic.else_tag())
  end

  defp for_statements(combinator) do
    combinator
    |> parsec(:variable_value)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> parsec(:value)
    |> optional(for_params())
    |> parsec(:ignore_whitespaces)
    |> tag(:for_statements)
  end
end
