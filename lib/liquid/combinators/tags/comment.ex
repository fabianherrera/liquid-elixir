defmodule Liquid.Combinators.Tags.Comment do
  @moduledoc """
  Allows you to leave un-rendered code inside a Liquid template.
  Any text within the opening and closing comment blocks will not be output,
  and any Liquid code within will not be executed
  Input:
  ```
    Anything you put between {% comment %} and {% endcomment %} tags
    is turned into a comment.
  ```
  Output:
  ```
    Anything you put between  tags
    is turned into a comment
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag}

  def comment_content do
    empty()
    |> optional(General.literal_until_tag())
    |> optional(
      choice([
        parsec(:comment),
        parsec(:raw),
        any_tag()
      ])
    )
    |> optional(General.literal_until_tag())
  end

  def tag do
    Tag.define_closed("comment", & &1, fn combinator ->
      combinator
      |> optional(parsec(:comment_content))
      |> reduce({Enum, :join, []})
    end)
  end

  def any_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> choice([
      string_with_comment(),
      string_without_comment()
    ])
    |> reduce({List, :to_string, []})
    |> string(General.codepoints().end_tag)
    |> optional(parsec(:comment_content))
  end

  def string_with_comment do
    string_without_comment()
    |> string("comment")
    |> concat(string_without_comment())
  end

  def string_without_comment do
    empty()
    |> repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag),
      string(General.codepoints().end_tag),
      string("endcomment"),
      string("comment")
    ])
  end
end
