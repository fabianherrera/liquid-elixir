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
  import NimbleParsec
  alias Liquid.Combinators.General
  alias Liquid.Combinators.Tag

  defp close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endraw"))
    |> concat(parsec(:end_tag))
  end

  defp not_close_tag do
    empty()
    |> ignore(utf8_char([]))
    |> parsec(:raw_content)
  end

  def raw_content do
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag)
    ])
    |> choice([close_tag(), not_close_tag()])
    |> reduce({List, :to_string, []})
    |> tag(:raw_content)
  end

  def tag do
    Tag.define_closed("raw", & &1, fn combinator -> parsec(combinator, :raw_content) end)
  end
end
