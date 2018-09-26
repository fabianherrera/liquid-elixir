defmodule Liquid.Combinators.Tags.CustomTag do
  @moduledoc """
  Implementation of custom tag. "Tags" are tags that take any number of arguments, but do not contain a block of template code.
  To create a new tag, Use Liquid.Register module and register your tag with Liquid.Register.register/3.
  The register tag  takes three arguments: the user-facing name of the tag, the module where code of parsing/rendering is located
  and the type that implements it (tag or block).

  ```
    {% MyCustomTag argument1 = 1, argument2, argument3 = 5 %}
  ```

  """
  import NimbleParsec
  alias Liquid.Combinators.General

  @type t :: [custom_tag: Custom_tag.markup()]
  @type markup :: [custom_name: String.t(), custom_markup: [String.t()]]

  @doc """
  Parses a `Liquid` Custom tag, creates a Keyword list where the key is the name of the custom tag
  (custom_tag in this case) and the value is another keyword list which represent the internal
  structure of the tag (arguments).
  """
  @spec tag() :: NimbleParsec.t()
  def tag2 do
    empty()
    |> parsec(:start_tag)
    |> concat(General.valid_tag_name())
    |> optional(markup())
    |> parsec(:end_tag)
    |> traverse({__MODULE__, :check_customs, []})
  end

  def check_customs(_, [params | tag], %{tags: tags} = context, _, _) do
    [tag_name] = tag
    name = String.to_atom(tag_name)

    Application.get_env(:liquid, :extra_tags, %{})
    |> Map.get(name)
    |> case do
      nil ->
        {[error: "The '#{tag}' tag has not been registered"], context}

      {_, Liquid.Block} ->
        {[block: [custom: [{:custom_name, tag}, params]]], %{context | tags: [tag_name | tags]}}

      {_, Liquid.Tag} ->
        {[custom: [{:custom_name, tag} | params]], context}
    end
  end

  def tag do
    parsec(:start_tag)
    |> concat(name())
    |> concat(markup())
    |> parsec(:end_tag)
    |> tag(:custom_tag)
  end

  defp name do
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

  @doc """
  Parses a `Liquid` Custom tag's name, isolates custom tag name from markup.
  """
  @spec string_name() :: NimbleParsec.t()
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

  @doc """
  It returns Custom tag's name. If tag is called equal to Liquid registered tag, this function returns a map with an error causing
  Nimble Parser stops its excecution.
  """
  @spec check_string(
          rest :: String.t(),
          args :: String.t(),
          context :: Map.t(),
          line :: Integer.t(),
          offset :: Integer.t()
        ) :: Keyword.t()
  def check_string(_rest, args, context, _line, _offset) do
    case liquid_tag_name?(args) do
      true ->
        {:error,
         "Error processing tag '#{args}'. The tag is malformed or you are using a reserved tag name to define a Custom Tag"}

      false ->
        {args, context}
    end
  end

  defp liquid_tag_name?([string]) when is_bitstring(string) do
    case string in all_tags() do
      true -> true
      false -> false
    end
  end

  defp liquid_tag_name?([_]), do: false

  defp register_tags() do
    case Application.get_env(:liquid, :extra_tags) do
      nil ->
        false

      map ->
        Enum.map(map, &simplify(&1))
        |> Enum.filter(fn {_key, type} -> type == Block end)
        |> Enum.map(fn {key, _type} -> "#{key}" end)
    end
  end

  defp all_tags do
    List.flatten([
      Liquid.Combinators.Tags.CustomTag.end_register_tag_name()
      | Liquid.Combinators.Tags.CustomTag.liquid_tags()
    ])
  end

  @doc """
  This function returns a List of Liquid reserved tag's name, also contains end block types names. It is used in order to verify
  custom tags will not be called with a registered tag's name.
  """
  @spec liquid_tags() :: List.t()
  def liquid_tags do
    [
      "case",
      "endcase",
      "when",
      "assign",
      "decrement",
      "increment",
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

  @doc """
  It checks correct end tags for a given open tag.
  """
  @spec end_register_tag_name() :: List.t()
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

  @doc """
  Returns a Keyword resulting of transformation of custom tag and type (tag or block).
  `{key, Tag}`
  `{key, Block}`

  """
  defp simplify({key, {_, Liquid.Block}}), do: {key, Block}
  defp simplify({key, {_, Block}}), do: {key, Block}
  defp simplify({key, {_, Tag}}), do: {key, Tag}
  defp simplify({key, {_, Liquid.Tag}}), do: {key, Tag}
end
