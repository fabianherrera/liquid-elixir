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
  alias Liquid.Combinators.General

  def cycle_group do
    parsec(:ignore_whitespaces)
    |> concat(
      choice([
        parsec(:quoted_token),
        repeat(utf8_char(not: ?,, not: ?:))
      ])
    )
    |> concat(utf8_char([?:]))
    |> reduce({List, :to_string, []})
  end

  def last_cycle_value do
    parsec(:ignore_whitespaces)
    |> choice([
      parsec(:quoted_token),
      parsec(:number)
    ])
    |> concat(parsec(:end_tag))
    |> reduce({List, :to_string, []})
  end

  def cycle_values do
    empty()
    |> optional(parsec(:ignore_whitespaces))
    |> choice([
      parsec(:quoted_token),
      parsec(:number)
    ])
    |> parsec(:ignore_whitespaces)
    |> ignore(utf8_char([General.codepoints().comma]))
    |> reduce({List, :to_string, []})
    |> choice([parsec(:cycle_values), parsec(:last_cycle_value)])
  end

  def tag do
    empty()
    |> parsec(:start_tag)
    |> string("cycle")
    |> ignore()
    |> optional(parsec(:cycle_group))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:cycle_values), parsec(:last_cycle_value)]))
    |> tag(:cycle)
    |> optional(parsec(:__parse__))
  end
end
