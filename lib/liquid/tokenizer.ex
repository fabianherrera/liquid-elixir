defmodule Liquid.Tokenizer do
  @moduledoc """
  Prepares markup to be parsed. Tokenizer splits the code between starting literal and rest of markup.
  When called recursively, it allows to process only liquid part (tags and variables) and bypass the slower literal.
  """

  alias Liquid.Combinators.General

  @doc """
  Takes a markup, find start of liquid construction (tag or variable) and returns
  a tuple with two elements: a literal and rest(with tags/variables and optionally more literals)
  """
  @spec tokenize(String.t()) :: {String.t(), String.t()}
  def tokenize(markup) do
    case :binary.match(markup, [
           General.codepoints().start_tag,
           General.codepoints().start_variable
         ]) do
      :nomatch -> {markup, ""}
      {0, _} -> {"", markup}
      {start, _} -> split(markup, start)
    end
  end

  defp split(markup, start) do
    len = byte_size(markup)
    literal = :binary.part(markup, {0, start})
    rest_markup = :binary.part(markup, {len, start - len})
    {literal, rest_markup}
  end

  @spec tokenize2(String.t()) :: [{:literal, String.t()} | {:liquid, String.t()}]
  def tokenize2(markup) do
    do_tokenize(markup, [])
  end

  defp do_tokenize("", acc), do: Enum.reverse(acc)
  defp do_tokenize(markup, acc) do
    case :binary.match(markup, [
              General.codepoints().start_tag,
              General.codepoints().start_variable
            ]) do
      :nomatch -> do_tokenize("", [{:literal, markup} | acc])
      {0, _} -> do_tokenize_close(markup, acc)
      {start, _} ->
        {literal, rest} = split(markup, start)
        do_tokenize_close(rest, [{:literal, literal} | acc])
    end
  end

  defp do_tokenize_close(markup, acc) do
    case :binary.match(markup, [
              General.codepoints().end_tag,
              General.codepoints().end_variable
            ]) do
      :nomatch -> do_tokenize("", [{:liquid, markup} | acc])
      # {0, _} -> do_tokenize_close(markup, acc)
      {close, _} ->
        {liquid, rest} = split(markup, close + 2)
        do_tokenize(rest, [{:liquid, liquid} | acc])
    end
  end
end
