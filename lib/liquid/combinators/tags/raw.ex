defmodule Liquid.Combinators.Tags.Raw do
  @moduledoc """
  Temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars)
  which uses conflicting syntax.
  Input:
  ```
    {% raw %}
    In Handlebars, {{ this }} will be HTML-escaped, but
    {{{ that }}} will not.
    {% endraw %}
  ```
  Output:
  ```
  In Handlebars, {{ this }} will be HTML-escaped, but {{{ that }}} will not.
  ```
  """
  alias Liquid.Combinators.General
  import NimbleParsec

  def tag, do: Tag.define_closed_no_head("raw", &body/1)

  def body(combinator) do
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag)
    ])
    |> reduce({List, :to_string, []})
    |> choice([parsec(:close_tag_raw), parsec(:tag_inside_raw)])
    |> reduce({List, :to_string, []})
  end

  def not_ingnored_start_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> parsec(:ignore_whitespaces)
  end

  def not_ingnored_end_tag do
    parsec(:ignore_whitespaces)
    |> concat(string(General.codepoints().end_tag))
  end

  def tag_inside_raw do
    empty()
    |> concat(not_ingnored_start_tag())
    |> repeat_until(utf8_char([]), [string(General.codepoints().end_tag), string("endraw")])
    |> concat(not_ingnored_end_tag())
    |> reduce({List, :to_string, []})
    |> parsec(:raw_body)
  end
end
