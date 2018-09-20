defmodule Liquid.Ast do
  alias Liquid.{Tokenizer, Parser}

  def build("", context, ast), do: {:ok, ast, context, ""}
  def build({literal, ""}, context, ast), do: {:ok, Enum.reverse([literal | ast]), context, ""}
  def build({"", markup}, context, ast), do: process_liquid(markup, context, ast)
  def build({literal, markup}, context, ast), do: process_liquid(markup, context, [literal | ast])

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
      # {:ok, [{:else_block, _}], rest, nimble_context, _line, _offset} ->
      #   {:ok, ast, nimble_context, "%{ else_body %}#{rest}"}

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
