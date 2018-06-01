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
  alias Liquid.Combinators.{Tag, General}

  @doc "Open comment tag: {% comment %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("comment"))
    |> concat(parsec(:end_tag))
  end

  @doc "Close comment tag: {% endcomment %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endcomment"))
    |> concat(parsec(:end_tag))
  end

  def not_close_tag_comment do
    empty()
    |> string(General.codepoints().start_tag)
    |> parsec(:comment_content)
  end

  def comment_body do
    empty()
    |> parsec(:comment_content)
    |> tag(:comment_body)
  end

  def comment_content do
    empty()
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> choice([parsec(:close_tag_comment), parsec(:not_close_tag_comment)])
    |> reduce({List, :to_string, []})
  end

  def tag do
    empty()
    |> parsec(:open_tag_comment)
    |> parsec(:comment_body)
    |> tag(:comment)
    |> optional(parsec(:__parse__))
  end

  #  def elsif_tag, do: Tag.define_open("elsif", &predicate/1)
  #
  #  def else_tag, do: Tag.define_open("else")
  #
  #  def unless_tag, do: Tag.define_closed("unless", &predicate/1, &body/1)
  #
  #  def tag, do: Tag.define_closed("comment", &predicate/1, &body/1)
  #
  #  defp body(combinator) do
  #    combinator
  #    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
  #    |> reduce({List, :to_string, []})
  #    |> choice([parsec(:close_tag_comment), parsec(:not_close_tag_comment)])
  #    |> reduce({List, :to_string, []})
  #  end
  #
  #  defp predicate(combinator) do
  #    combinator
  ##    |> empty()
  #  end
  #
  #
  #  empty()
  #  |> concat(not_ingnored_start_tag())
  #  |> repeat_until(utf8_char([]), [string(General.codepoints().end_tag), string("endraw")])
  #  |> concat(not_ingnored_end_tag())
  #  |> reduce({List, :to_string, []})
  #  |> parsec(:raw_body)
  #
  #  empty()
  #  |> utf8_char([])
  #  |> parsec(:comment_content)
end
