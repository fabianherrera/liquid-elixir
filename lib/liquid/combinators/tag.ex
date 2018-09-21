defmodule Liquid.Combinators.Tag do
  @moduledoc """
  Helper to create tags
  """
  import NimbleParsec

  @doc """
  Define a tag from a tag_name and, optionally, a function to parse tag parameters,
  the tag and a function to parse the body inside the tag
  Both functions must receive a combinator and must return a combinator

  The returned tag is a combinator which expect a start tag `{%` a tag name and a end tag `%}`

  ## Examples

      defmodule MyParser do
        import NimbleParsec
        alias Liquid.Combinators.Tag

        def ignorable, do: Tag.define(
          "ignorable",
          fn combinator -> combinator |> string("T") |> ignore() |> integer(2,2))

      MyParser.ignorable("{% ignorable T12 %}")
      #=> {:ok, {:ignorable, [12]}, "", %{}, {1, 0}, 2}
  """
  def define_closed(tag_name, combinator_head \\ & &1, combinator_body \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> combinator_body.()
    |> close_tag(tag_name)
    |> tag(String.to_atom(tag_name))
  end

  def define_open(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> tag(String.to_atom(tag_name))
  end

  def define_sub_block(tag_name, allowed_tags, combinator \\ & &1) do
    empty()
    |> parsec(:start_tag)
    |> string(tag_name)
    |> combinator.()
    |> parsec(:end_tag)
    |> tag(:sub_block)
    |> traverse({__MODULE__, :check_allowed_tags, [allowed_tags]})
  end

  def define_block(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> tag(String.to_atom(tag_name))
    |> traverse({__MODULE__, :store_tag_in_context, []})
  end

  def define_inverse_open(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> optional(parsec(:__parse__))
    |> tag(String.to_atom(tag_name))
  end

  def open_tag(tag_name, combinator \\ & &1) do
    empty()
    |> parsec(:start_tag)
    |> ignore(string(tag_name))
    |> combinator.()
    |> parsec(:end_tag)
  end

  def close_tag(combinator \\ empty(), tag_name) do
    combinator
    |> parsec(:start_tag)
    |> ignore(string("end" <> tag_name))
    |> parsec(:end_tag)
  end

  def store_tag_in_context(_rest, tag, %{tags: tags} = context, _line, _offset) do
    tag_name = tag |> Keyword.keys() |> hd() |> to_string()
    {[block: tag], %{context | tags: [tag_name | tags]}}
  end

  def check_allowed_tags(_, acc, %{tags: []} = context, _, _, _) do
    tag_name = tag_name(acc)
    {[error: "Unexpected outer '#{tag_name}' tag"], context}
  end

  def check_allowed_tags(_, acc, %{tags: [tag | _]} = context, _, _, allowed_tags) do
    tag_name = tag_name(acc)

    if Enum.member?(allowed_tags, tag) do
      {acc, context}
    else
      {[
         error:
           "#{tag} does not expect #{tag_name} tag. The #{tag_name} tag is valid only inside: #{
             Enum.join(allowed_tags, ", ")
           }"
       ], context}
    end
  end

  defp tag_name([{:sub_block, [{tag, _}]}]), do: tag
  defp tag_name([{:sub_block, [tag]}]), do: tag
end
