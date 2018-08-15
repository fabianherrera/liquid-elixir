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
  alias Liquid.Translators.Markup

  @type t :: [comment: Comment.markup()]

  @type markup :: [String.t() | Comment.t() | Raw.t()]

  @doc """
  Creates a comment body combinator to group his parts.
  """
  def comment_content do
    General.literal_until_tag()
    |> optional(
      choice([
        parsec(:comment) |> optional(parsec(:comment_content)),
        parsec(:raw) |> optional(parsec(:comment_content)),
        any_tag() |> optional(parsec(:comment_content))
      ])
    )
    |> concat(General.literal_until_tag())
  end

  @doc """
  Parse a `Liquid` Comment tag.
  """
  def tag do
    Tag.define_closed("comment", & &1, fn combinator ->
      combinator
      |> optional(parsec(:comment_content))
      |> reduce({Markup, :literal, []})
    end)
  end

  def any_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> optional(repeat(General.whitespace()))
    |> choice([
      string_with_comment(),
      string_with_endcomment(),
      string_without_comment()
    ])
    |> reduce({List, :to_string, []})
    |> string(General.codepoints().end_tag)
  end

  def string_with_endcomment do
    utf8_char([])
    |> concat(string_without_comment())
    |> concat(string("endcomment"))
    |> optional(string_without_comment())
  end

  def string_with_comment do
    string_without_comment()
    |> concat(string("comment"))
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
