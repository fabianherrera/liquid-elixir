defmodule Liquid.Combinators.Tags.CustomTag do
  import NimbleParsec
  alias Liquid.Combinators.General

  def tag do
    parsec(:start_tag)
    |> concat(name())
    |> concat(markup())
    |> parsec(:end_tag)
    |> tag(:custom_tag)
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

  def check_close_tag(_rest, args, context, _line, _offset) do
    tags_name = Keyword.get_values(args, :custom_name)
    [opened_name, closed_name] = tags_name

    case opened_name == "end" <> closed_name do
      true -> {args, context}
      false -> {:error, "#{opened_name} #{closed_name}"}
    end
  end

  defp valid_markup() do
    repeat_until(utf8_char([]), [string("{%"), string("%}"), string("{{"), string("}}")])
  end

  def string_name do
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
  end

  defp valid_name() do
    string_name()
    |> traverse({Liquid.Combinators.Tags.CustomTag, :check_string, []})
  end

  def check_string(_rest, args, context, _line, _offset) do
    case liquid_tag_name?(args) do
      true -> {:error, "Invalid tag name"}
      false -> {args, context}
    end
  end

  defp liquid_tag_name?([string]) when is_bitstring(string) do
    case string in all_tags() do
      true -> true
      false -> false
    end
  end

  defp liquid_tag_name?([_]), do: false

  def register_tags() do
    case Application.get_env(:liquid, :extra_tags) do
      nil ->
        false

      map ->
        Enum.map(map, &simplify(&1))
        |> Enum.filter(fn {_key, type} -> type == Block end)
        |> Enum.map(fn {key, _type} -> "#{key}" end)
    end
  end

  def all_tags do
    List.flatten([
      Liquid.Combinators.Tags.CustomTag.end_register_tag_name()
      | Liquid.Combinators.Tags.CustomTag.liquid_tags()
    ])
  end

  def liquid_tags do
    [
      "case",
      "endcase",
      "when",
      "assign",
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
      "elsif",
      ""
    ]
  end

  def end_register_tag_name do
    list = register_tags()

    case list do
      false ->
        []

      _ ->
        new_list = Enum.map(list, fn x -> "end#{x}" end)
        [new_list | register_tags()]
    end
  end

  def simplify({key, {_, Liquid.Block}}), do: {key, Block}
  def simplify({key, {_, Block}}), do: {key, Block}
  def simplify({key, {_, Tag}}), do: {key, Tag}
  def simplify({key, {_, Liquid.Tag}}), do: {key, Tag}
end
