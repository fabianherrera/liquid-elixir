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

  def comment_content do
    empty()
    |> repeat_until(utf8_char([]), [string(General.codepoints().start_tag)])
    |> choice([close_tag(), not_close_tag(), internal_comment_tag()])
    |> reduce({List, :to_string, []})
  end

  def tag do
    open_tag()
    |> concat(comment_content())
    |> tag(:comment)
    |> optional(parsec(:__parse__))
  end

  def internal_comment_tag do
    open_tag()
    |> parsec(:comment_content)
#    |> tag(:comment)
#    |> optional(comment_content())
  end

  defp open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("comment"))
    |> concat(parsec(:end_tag))
  end

  defp close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endcomment"))
    |> concat(parsec(:end_tag))
  end

  defp not_close_tag do
    empty()
    |> string(General.codepoints().start_tag)
    |> parsec(:comment_content)
  end

end