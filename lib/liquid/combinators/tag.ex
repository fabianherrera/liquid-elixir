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
    |> optional(parsec(:__parse__))
  end

  def define_closed_test(tag_name, combinator_head \\ & &1, _combinator_body \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> parsec(:body_if)
    |> close_tag(tag_name)
    |> tag(String.to_atom(tag_name))
    |> optional(parsec(:__parse__))
  end

  def define_end(tag_name, combinator_head \\ & &1, combinator_body \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> parsec(:body_elsif)
    |> tag(String.to_atom(tag_name))
    |> optional(parsec(:__parse__))
  end

  def define_open(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> tag(String.to_atom(tag_name))
    |> optional(parsec(:__parse__))
  end

  def define_inverse_open(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> optional(parsec(:__parse__))
    |> tag(String.to_atom(tag_name))
  end

  def define_inverse_open_when(tag_name, combinator_head \\ & &1) do
    tag_name
    |> open_tag(combinator_head)
    |> tag(:statements)
    |> concat(tag(optional(parsec(:__parse__)), :value_if_true))
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
end
