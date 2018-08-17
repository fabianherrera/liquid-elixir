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
  alias Liquid.Combinators.{Tag, General}
  @name "raw"

  @type t :: [raw: [String.t()]]

  @doc """
  Creates a list of string, this is to emulate the behaviuor of the `Liquid` raw tag
  """
  def raw_content do
    General.literal_until_tag()
    |> choice([Tag.close_tag(@name), any_tag()])
    |> reduce({List, :to_string, []})
  end

  @doc """
  Parse a `Liquid` Raw tag, create a Keyword list where the key is the name of the tag 
  (raw in this case) and the value is  the result of the `Liquid.Combinators.Tags.Raw.raw_content` combinator.
  """
  def tag do
    @name
    |> Tag.open_tag()
    |> concat(raw_content())
    |> tag(:raw)
    |> optional(parsec(:__parse__))
  end

  defp any_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> parsec(:raw_content)
  end
end
