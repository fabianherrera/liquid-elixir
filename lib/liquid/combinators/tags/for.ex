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
  alias Liquid.Combinators.{General, Tag, Variable}

  @doc "For offset param: {% for products in products offset:2 %}"
  def offset_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("offset"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:offset_param)
  end

  @doc "For limit param: {% for products in products limit:2 %}"
  def limit_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("limit"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:limit_param)
  end

  @doc "For reversed param: {% for products in products reversed %}"
  def reversed_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("reversed"))
    |> parsec(:ignore_whitespaces)
    |> tag(:reversed_param)
  end

  def for_body do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:for_body)
  end

  def forloop_first, do: Variable.define("forloop.first")

  def forloop_index, do: Variable.define("forloop.index")

  def forloop_index0, do: Variable.define("forloop.index0")

  def forloop_last, do: Variable.define("forloop.last")

  def forloop_length, do: Variable.define("forloop.length")

  def forloop_rindex, do: Variable.define("forloop.rindex")

  def forloop_rindex0, do: Variable.define("forloop.rindex0")

  def forloop_variables do
    empty()
    |> choice([
        parsec(:forloop_first),
        parsec(:forloop_index),
        parsec(:forloop_index0),
        parsec(:forloop_last),
        parsec(:forloop_length),
        parsec(:forloop_rindex),
        parsec(:forloop_rindex0)
        ])
  end

  def else_tag, do: Tag.define_open("else")

  def continue_tag, do:  Tag.define_open("continue")

  def break_tag, do:  Tag.define_open("break")

  def tag, do: Tag.define_closed("for", &for_collection/1, &body/1)

  defp body(combinator) do
    combinator
    |> parsec(:for_body)
    |> optional(parsec(:else_tag_for))
  end

  defp for_collection(combinator) do
    combinator
    |> parsec(:variable_name)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> choice([parsec(:range_value), parsec(:value)])
    |> optional(
         times(
           choice([parsec(:offset_param), parsec(:reversed_param), parsec(:limit_param)]),
           min: 1
         )
       )
    |> parsec(:ignore_whitespaces)
    |> tag(:for_collection)
  end
end

