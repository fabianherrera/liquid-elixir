defmodule Liquid.Combinators.Tags.Custom do
  import NimbleParsec
  alias Liquid.Combinators.General

  def tag do
    empty()
    |> parsec(:start_tag)
    |> concat(name())
    |> concat(markup())
    |> parsec(:end_tag)
    |> tag(:custom)
    |> optional(parsec(:__parse__))
  end

  defp name do
    not_register_tag_name()
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_name)
  end

  defp markup do
    empty()
    |> parsec(:ignore_whitespaces)
    |> concat(not_register_tag_name())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp not_register_tag_name() do
    repeat_until(utf8_char([]), list_of_registered_tags())
  end

  defp list_of_registered_tags do
    [
      string("case"),
      string("endcase"),
      string("when"),
      string("if"),
      string("endif"),
      string("unless"),
      string("endunless"),
      string("assign"),
      string("capture"),
      string("endcapture"),
      string("increment"),
      string("decrement"),
      string("include"),
      string("cycle"),
      string("raw"),
      string("endraw"),
      string("for"),
      string("endfor"),
      string("break_tag"),
      string("continue_tag"),
      string("tablerow"),
      string("ifchanged"),
      string("endifchanged"),
      string("else"),
      string("comment"),
      string("endcomment"),
      string("elsif"),
      utf8_char([General.codepoints().space])
    ]
  end
end
