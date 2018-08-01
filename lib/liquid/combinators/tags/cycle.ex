defmodule Liquid.Combinators.Tags.Cycle do
  @moduledoc """
  Implementation of `cycle` tag. Can be named or anonymous, rotates through pre-set values
  Cycle is usually used within a loop to alternate between values, like colors or DOM classes.
  ```
    {% for item in items %}
    <div class="{% cycle 'red', 'green', 'blue' %}"> {{ item }} </div>
    {% end %}
  ```
  ```
    <div class="red"> Item one </div>
    <div class="green"> Item two </div>
    <div class="blue"> Item three </div>
    <div class="red"> Item four </div>
    <div class="green"> Item five</div>
  ```
  Loops through a group of strings and outputs them in the order that they were passed as parameters.
  Each time cycle is called, the next string that was passed as a parameter is output.
  cycle must be used within a for loop block.
  Input:
  ```
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
    {% cycle 'one', 'two', 'three' %}
  ```
  Output:
  ```
    one
    two
    three
    one
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{Tag, General}

  @type t :: [cycle: [group: String.t(), values: [LexicalToken.value()]]]

  defp group do
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:quoted_token),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> ignore(utf8_char([?:]))
    |> reduce({List, :to_string, []})
    |> tag(:group)
  end

  defp body do
    parsec(:cycle_values)
    |> tag(:values)
  end

  def cycle_values do
    empty()
    |> times(parsec(:value_definition), min: 1)
    |> optional(ignore(utf8_char([General.codepoints().comma])))
    |> optional(parsec(:cycle_values))
  end

  def tag do
    Tag.define_open("cycle", fn combinator ->
      combinator
      |> optional(group())
      |> parsec(:ignore_whitespaces)
      |> concat(body())
    end)
  end
end
