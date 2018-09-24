defmodule Liquid.Ast do
  @moduledoc """
  Builds the AST processing with Nimble, only liquid valid tags and variables. It uses Tokenizer
  to send to Nimble only tags and variables, without literals.
  Literals (any markup which is not liquid variable or tag) are slow to be processed by Nimble thus
  this module improve performance between 30% and 100% depending how much text is processed.
  """
  alias Liquid.{Tokenizer, Parser}

  @doc """
  Recursively builds the AST taking a markup, or a tuple with a literal and a rest markup.
  It uses `context` to validate the correct opening and close of blocks and sub blocks.
  """
  @spec build(String.t() | {String.t(), String.t()}, Keyword.t(), List.t()) ::
          {:ok, List.t(), Keyword.t(), String.t()} | {:error, String.t(), String.t()}
  def build({literal, ""}, context, ast), do: {:ok, Enum.reverse([literal | ast]), context, ""}
  def build({"", markup}, context, ast), do: parse_liquid(markup, context, ast)
  def build({literal, markup}, context, ast), do: parse_liquid(markup, context, [literal | ast])
  def build("", context, ast), do: {:ok, ast, context, ""}
  def build(markup, context, ast), do: markup |> Tokenizer.tokenize() |> build(context, ast)
  def build({:error, error_message, rest_markup}), do: {:error, error_message, rest_markup}

  defp build_block(markup, block, context, ast), do: markup |> build(context, []) |> do_build_block(block, ast)

  defp do_build_block({:ok, [:end_block | tags], %{sub_blocks: [sub_block | _]} = context, rest}, block, ast),
    do: build(rest, %{context | sub_blocks: []}, [close_block(block, sub_block, tags) | ast])

  defp do_build_block({:ok, tags, %{sub_blocks: [sub_block | _]} = context, rest}, block, ast) do
    build_block(rest, block_content(block, sub_block, tags), context, ast)
  end

  defp do_build_block({:ok, [:end_block | tags], %{sub_blocks: []} = context, rest}, block, ast),
    do: build(rest, context, [close_block(block, [], tags) | ast])

  defp do_build_block({:ok, tags, %{sub_blocks: []} = context, rest}, block, ast),
    do: build(rest, context, [close_block(block, [], tags) | ast])

  defp do_build_block({:error, error, rest}, _, _), do: {:error, error, rest}

  defp parse_liquid(markup, context, ast), do: markup |> Parser.__parse__(context: context) |> do_parse_liquid(ast)

  defp do_parse_liquid({:ok, [{:error, message}], rest, _, _, _}, _), do: {:error, message, rest}
  defp do_parse_liquid({:ok, [{:sub_block, block}], rest, context, _, _}, ast), do: sub_block(block, rest, context, ast)
  defp do_parse_liquid({:ok, [{:end_block, _}], rest, context, _, _}, ast), do: {:ok, [:end_block | ast], context, rest}
  defp do_parse_liquid({:ok, [{:block, [blk]}], markup, context, _, _}, ast), do: build_block(markup, blk, context, ast)
  defp do_parse_liquid({:ok, [tags], "", context, _, _}, ast), do: {:ok, Enum.reverse([tags | ast]), context, ""}
  defp do_parse_liquid({:ok, [tags], markup, context, _, _}, ast), do: build(markup, context, [tags | ast])
  defp do_parse_liquid({:error, message, rest, _, _, _}, _), do: {:error, message, rest}

  defp close_block(block, sub_block, tags) do
    {tag, body_block} = block_content(block, sub_block, tags)
    {tag, Enum.reverse(body_block)}
  end

  defp block_content({tag, body_block}, [], tags) do
    {tag, Keyword.put(body_block, :body, Enum.reverse(tags))}
  end

  defp block_content({tag, body_block} = block, [{sub_block, body_sub_block}], tags) do
    if Keyword.has_key?(body_block, :body) do
      {tag, [{sub_block, Enum.reverse(Keyword.put(body_sub_block, :body, Enum.reverse(tags)))} | body_block]}
    else
      block_content(block, [], tags)
    end
  end

  defp sub_block(sub_block, markup, %{sub_blocks: sub_blocks} = context, ast) do
    {:ok, ast, %{context | sub_blocks: [sub_block | sub_blocks]}, markup}
  end
end
