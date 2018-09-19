defmodule Liquid.Ast do
  alias Liquid.{Tokenizer, Parser}

  def build("", context, ast), do: {:ok, ast, context, ""}
  def build({literal, ""}, context, ast), do: {:ok, Enum.reverse([literal | ast]), context, ""}
  def build({"", markup}, context, ast), do: process_liquid(markup, context, ast)
  def build({literal, markup}, context, ast), do: process_liquid(markup, context, [literal | ast])

  def build(markup, context, ast) do
    markup |> Tokenizer.tokenize() |> build(context, ast)
  end

  # @doc """
  # End the block tag
  # """
  # def build(markup, [end_block: _], context), do: {:ok, {:end_block, markup}, context}

  # @doc """
  # Start the block tag
  # """
  # def build(markup, [block: [{tag_name, content}]], context) do
  #   markup |> Tokenizer.tokenize() |> build_block(tag_name, content, context)
  # end

  # def build(markup, ast, context),
  #   do: markup |> Tokenizer.tokenize() |> build_tag(ast, context)

  # defp build_block({literal, ""}, tag_name, content, context),
  #   do: {:ok, {tag_name, Keyword.put(content, :body, literal)}, context}

  # defp build_block({"", liquid}, tag_name, content, context) do
  #   wrap_block(liquid, context, fn acc, nimble_context ->
  #     internal_block(acc, nimble_context, tag_name, content, [], acc)
  #   end)
  # end

  # defp build_block({literal, liquid}, tag_name, content, context) do
  #   wrap_block(liquid, context, fn acc, nimble_context ->
  #     internal_block(acc, nimble_context, tag_name, content, [literal], [literal | acc])
  #   end)
  # end

  # defp internal_block(acc, nimble_context, tag_name, content, finish_block, next_block) do
  #   case acc do
  #     {:end_block, markup} ->
  #       [
  #         clean_build(markup, [], nimble_context),
  #         {tag_name, Enum.reverse(Keyword.put(content, :body, finish_block))}
  #       ]

  #     _ ->
  #       {tag_name, Enum.reverse(Keyword.put(content, :body, next_block))}
  #   end
  # end

  # defp wrap_block(liquid, context, constructor) do
  #   case process_liquid(liquid, context) do
  #     {:ok, acc, nimble_context} -> {:ok, constructor.(acc, nimble_context), nimble_context}
  #     {:error, error_message, rest_markup} -> {:error, error_message, rest_markup}
  #   end
  # end

  # defp build_tag({literal, ""}, ast, context), do: {:ok, [literal | ast], context}
  # defp build_tag({"", liquid}, ast, context), do: wrap_tag(liquid, context, &[&1 | ast])

  # defp build_tag({literal, liquid}, ast, context),
  #   do: wrap_tag(liquid, context, &[&1 | [literal | ast]])

  # defp wrap_tag(liquid, context, constructor) do
  #   case process_liquid(liquid, context) do
  #     {:ok, acc, nimble_context} -> {:ok, List.flatten(constructor.(acc)), nimble_context}
  #     {:error, error_message, rest_markup} -> {:error, error_message, rest_markup}
  #   end
  # end

  # defp clean_build(markup, ast, context) do
  #   case build(markup, ast, context) do
  #     {:ok, ast, _context} -> ast
  #   end
  # end

  defp process_liquid(markup, context, ast) do
    case Parser.__parse__(markup, context: context) do
      {:ok, [{:end_block, _}], rest, nimble_context, _line, _offset} ->
        {:ok, ast, nimble_context, rest}

      {:ok, [{:block, [{tag, content}]}], markup, nimble_context, _line, _offset} ->
        {:ok, acc, block_context, rest} = build(markup, nimble_context, [])
        build(rest, block_context, [{tag, Keyword.put(content, :body, acc)} | ast])

      {:ok, [acc], "", nimble_context, _, _} ->
        {:ok, Enum.reverse([acc | ast]), nimble_context, ""}

      {:ok, [acc], markup, nimble_context, _line, _offset} ->
        build(markup, nimble_context, [acc | ast])

      {:error, error_message, rest_markup, _nimble_context, _line, _offset} ->
        {:error, error_message, rest_markup}
    end
  end
end
