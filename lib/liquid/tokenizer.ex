defmodule Liquid.Tokenizer do
  @moduledoc """
  Prepares markup to be parsed
  """

  alias Liquid.Combinators.General

  @doc """
  Takes a markup, find start of liquid construction (tag or variable) and returns
  a tuple with two elements: a literal and a possible liquid construction
  """
  @spec tokenize(String.t) :: []
  def tokenize(markup) do
    case :binary.match(markup, [General.codepoints.start_tag, General.codepoints.start_variable]) do
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
end
