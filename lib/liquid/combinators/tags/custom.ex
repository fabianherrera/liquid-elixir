defmodule Liquid.Combinators.Tags.Custom do
  import NimbleParsec
  alias Liquid.Combinators.General

  def tag do
    parsec(:start_tag)
    |> concat(name())
    |> concat(markup())
    |> parsec(:end_tag)
    |> tag(:custom)
    |> optional(parsec(:__parse__))
  end

  def name do
    valid_name()
    |> unwrap_and_tag(:custom_name)
  end

  defp markup do
    empty()
    |> parsec(:ignore_whitespaces)
    |> concat(valid_markup())
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp valid_markup() do
    repeat_until(utf8_char([]), [string("{%"), string("%}"), string("{{"), string("}}")])
  end

  defp valid_name() do
    repeat_until(utf8_char([]), [
      string(" "),
      string("%}"),
      ascii_char([
        General.codepoints().horizontal_tab,
        General.codepoints().carriage_return,
        General.codepoints().newline,
        General.codepoints().space
      ])
    ])
    |> reduce({List, :to_string, []})
    |> traverse({Liquid.Combinators.Tags.Custom, :check_string, []})
  end

  def check_string(_rest, args, context, _line, _offset) do
    case liquid_tag_name?(args) do
      true -> {:error, "invalid tag name"}
      false -> {args, context}
    end
  end

  defp liquid_tag_name?([string])
       when string in [
              "case",
              "endcase",
              "when",
              "if",
              "endif",
              "unless",
              "endunless",
              "capture",
              "endcapture",
              "raw",
              "endraw",
              "for",
              "endfor",
              "break",
              "continue",
              "ifchanged",
              "endifchanged",
              "else",
              "comment",
              "endcomment",
              "tablerow",
              "endtablerow",
              "elsif"
            ],
       do: true

  defp liquid_tag_name?([_]), do: false
end
