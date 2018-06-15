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
  alias Liquid.Combinators.General

  # def comment_content do
  #   empty()
  #   |> optional(repeat_until(utf8_char([]), [string(General.codepoints().start_tag)]))
  #   |> optional(parsec(:comment))
  #   |> optional(repeat_until(utf8_char([]), [string(General.codepoints().start_tag)]))
  #   |> optional(parsec(:raw))
  #   |> optional(repeat_until(utf8_char([]), [string(General.codepoints().start_tag)]))
  #   |> optional(times(any_tag(), min: 1))
  #   |> optional(repeat_until(utf8_char([]), [string(General.codepoints().start_tag)]))
  # end

  defp literal_comment do
    optional(repeat_until(utf8_char([]), [string(General.codepoints().start_tag)]))
    |> reduce({List, :to_string, []})
  end

  def comment_content do
    literal_comment()
    |> optional(choice([
        parsec(:comment),
        parsec(:raw),
        times(any_tag(), min: 1)
      ]))
    |> concat(literal_comment())
  end

  def tag do
    open_tag()
    |> parsec(:comment_content)
    |> concat(close_tag())
    |> reduce({Enum, :join, []})
    |> tag(:comment)
    |> optional(parsec(:__parse__))
  end

  defp open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("comment"))
    |> concat(parsec(:end_tag))
  end

  defp close_tag do
    parsec(:ignore_whitespaces)
    |> parsec(:start_tag)
    |> ignore(string("endcomment"))
    |> concat(parsec(:end_tag))
  end

  def any_tag do
    optional(literal_comment())
    |> parsec(:start_tag)
    |> choice([
      strigs_with_comment(),
      strigs_with_endcomment(),
      string_without_comment()
    ])
    |> concat(parsec(:end_tag))
    |> optional(parsec(:comment_content))
    |> parsec(:ignore_whitespaces)
  end

  # def strigs_with_endcomment do
  #   utf8_char([?a..?z])
  #   |> concat(string_helper())
  #   |> utf8_char([?e])
  #   |> utf8_char([?n])
  #   |> utf8_char([?d])
  #   |> utf8_char([?c])
  #   |> utf8_char([?o])
  #   |> utf8_char([?m])
  #   |> utf8_char([?m])
  #   |> utf8_char([?e])
  #   |> utf8_char([?n])
  #   |> utf8_char([?t])
  #   |> optional(string_helper())
  #   |> reduce({List, :to_string, []})
  # end

  # def strigs_with_comment do
  #   utf8_char([?a..?z])
  #   |> concat(string_helper())
  #   |> utf8_char([?c])
  #   |> utf8_char([?o])
  #   |> utf8_char([?m])
  #   |> utf8_char([?m])
  #   |> utf8_char([?e])
  #   |> utf8_char([?n])
  #   |> utf8_char([?t])
  #   |> concat(string_helper())
  #   |> reduce({List, :to_string, []})
  # end

  def strigs_with_endcomment do
    utf8_char([?a..?z])
    |> concat(string_helper())
    |> concat(string("endcomment"))
    |> optional(string_helper())
    |> reduce({List, :to_string, []})
  end

  def strigs_with_comment do
    utf8_char([?a..?z])
    |> concat(string_helper())
    |> concat(string("comment"))
    |> concat(string_helper())
    |> reduce({List, :to_string, []})
  end

  def string_helper do
    repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag),
      string(General.codepoints().end_tag),
      string("nd"),
      string("comment")
    ])
    |> reduce({List, :to_string, []})
  end

  def string_without_comment do
    repeat_until(utf8_char([]), [
      string(General.codepoints().start_tag),
      string(General.codepoints().end_tag),
      string("endcomment"),
      string("comment")
    ])
    |> reduce({List, :to_string, []})
  end
end
