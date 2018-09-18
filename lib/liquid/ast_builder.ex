defmodule Liquid.AstBuilder do
  alias Liquid.{Tokenizer, Parser}

  @doc """
  End the block tag
  """
  def build_ast(markup, [end_block: _], context), do: {:ok, {:end_block, markup}, context}

  @doc """
  Start the block tag
  """
  def build_ast(markup, [block: [{tag_name, content}]], context) do
    markup |> Tokenizer.tokenize() |> build_block(tag_name, content, context)
  end

  def build_ast(markup, ast, context),
    do: markup |> Tokenizer.tokenize() |> build_tag(ast, context)

  defp build_block({literal, ""}, tag_name, content, context),
    do: {:ok, {tag_name, Keyword.put(content, :body, literal)}, context}

  defp build_block({"", liquid}, tag_name, content, context) do
    wrap_block(liquid, context, fn acc, nimble_context ->
      case acc do
        {:end_block, markup} -> [{tag_name, Keyword.put(content, :body, [])}, clean_build_ast(markup, [], nimble_context)]

        _ ->
         {tag_name, Keyword.put(content, :body, acc)}
      end
    end)
  end

  defp build_block({literal, liquid}, tag_name, body, context) do
    wrap_block(liquid, context, fn acc, nimble_context ->
      case acc do
        {:end_block, markup} -> [{tag_name, Keyword.put(body, :body, [literal])}, clean_build_ast(markup, [], nimble_context)]

        _ -> {tag_name, Keyword.put(body, :body, [literal | acc])}
      end
    end)
  end

  defp wrap_block(liquid, context, constructor) do
    case process_liquid(liquid, context) do
      {:ok, acc, nimble_context} -> {:ok, constructor.(acc, nimble_context), nimble_context}
      {:error, error_message, rest_markup} -> {:error, error_message, rest_markup}
    end
  end

  defp build_tag({literal, ""}, ast, context), do: {:ok, [literal | ast], context}
  defp build_tag({"", liquid}, ast, context), do: wrap_tag(liquid, context, &[&1 | ast])

  defp build_tag({literal, liquid}, ast, context),
    do: wrap_tag(liquid, context, &[&1 | [literal | ast]])

  defp wrap_tag(liquid, context, constructor) do
    case process_liquid(liquid, context) do
      {:ok, acc, nimble_context} -> {:ok, List.flatten(constructor.(acc)), nimble_context}
      {:error, error_message, rest_markup} -> {:error, error_message, rest_markup}
    end
  end

  defp clean_build_ast(markup, ast, context) do
    case build_ast(markup, ast, context) do
      {:ok, ast, _context} -> ast
    end
  end

  defp process_liquid(markup, context) do
    case Parser.__parse__(markup, context: context) do
      {:ok, [{:end_block, _tag_name}], "", nimble_context, _line, _offset} ->
        {:ok, [], nimble_context}

      {:ok, [acc], "", %{tags: []} = nimble_context, _line, _offset} ->
        {:ok, acc, nimble_context}

      {:ok, acc, markup, nimble_context, _line, _offset} ->
        build_ast(markup, acc, nimble_context)

      {:error, error_message, rest_markup, _nimble_context, _line, _offset} ->
        {:error, error_message, rest_markup}
    end
  end
end
