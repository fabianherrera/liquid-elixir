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

  def raw_content do
    empty()
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> choice([close_tag(), not_close_tag()])
    |> reduce({List, :to_string, []})
  end

  def tag do
    open_tag()
    |> concat(raw_content())
    |> tag(:raw)
    |> optional(parsec(:__parse__))
  end

  defp open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("raw"))
    |> concat(parsec(:end_tag))
  end

  defp close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endraw"))
    |> concat(parsec(:end_tag))
  end

  defp not_close_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> parsec(:raw_content)
  end
end
