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
  It uses a context to validate the correct opening and close of blocks and sub blocks.
  """
  @spec build(String.t() | {String.t(), String.t()}, Keyword.t(), List.t()) ::
          {:ok, List.t(), Keyword.t(), String.t()} | {:error, String.t(), String.t()}
  def build({literal, ""}, context, ast), do: {:ok, Enum.reverse([literal | ast]), context, ""}
  def build({"", markup}, context, ast), do: process_liquid(markup, context, ast)
  def build({literal, markup}, context, ast), do: process_liquid(markup, context, [literal | ast])

  def build("", context, ast), do: {:ok, ast, context, ""}
  def build(markup, context, ast) do
    markup |> Tokenizer.tokenize() |> build(context, ast)
  end

  def build({:error, error_message, rest_markup}), do: {:error, error_message, rest_markup}

  defp build_block(markup, [{tag, content}], context, ast) do
    case build(markup, context, []) do
      {:ok, acc, block_context, rest} ->
        build(rest, block_context, [
          {tag, Enum.reverse(Keyword.put(content, :body, Enum.reverse(acc)))} | ast
        ])

      {:error, error_message, rest_markup} ->
        {:error, error_message, rest_markup}
    end
  end

  defp process_liquid(markup, context, ast) do
    case Parser.__parse__(markup, context: context) do
      {:ok, [{:error, message}], rest, _, _, _} ->
        {:error, message, rest}

      {:ok, [{:end_block, _}], rest, nimble_context, _line, _offset} ->
        {:ok, ast, nimble_context, rest}

      {:ok, [{:block, content}], markup, nimble_context, _line, _offset} ->
        build_block(markup, content, nimble_context, ast)

      {:ok, [acc], "", nimble_context, _, _} ->
        {:ok, Enum.reverse([acc | ast]), nimble_context, ""}

      {:ok, [acc], markup, nimble_context, _line, _offset} ->
        build(markup, nimble_context, [acc | ast])

      {:error, error_message, rest_markup, _nimble_context, _line, _offset} ->
        {:error, error_message, rest_markup}
    end
  end
end
