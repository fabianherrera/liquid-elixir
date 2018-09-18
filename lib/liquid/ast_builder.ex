defmodule Liquid.AstBuilder do
  alias Liquid.{Tokenizer, Parser}

  defp process_markup(markup, context) do
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

  def build_ast(markup, [end_block: _], context), do: {:ok, {:end_block, markup}, context}

  def build_ast(markup, [block: [{tag_name, body}]] = ast, context) do
    case Tokenizer.tokenize(markup) do
      {literal, ""} ->
        {:ok, {tag_name, Keyword.put(body, :body, literal)}, context}

      {"", liquid} ->
        case process_markup(liquid, context) do
          {:ok, acc, nimble_context} ->
            case acc do
              {:end_block, markup} ->
                {:ok, {tag_name, build_ast(markup, [], nimble_context), %{tags: []}}}

              _ ->
                {:ok, {tag_name, Keyword.put(body, :body, acc)}, nimble_context}
            end

          {:error, error_message, rest_markup} ->
            {:error, error_message, rest_markup}
        end

      {literal, liquid} ->
        case process_markup(liquid, context) do
          {:ok, acc, nimble_context} ->
            case acc do
              {:end_block, markup} ->
                {:ok,
                 [
                   {tag_name, Keyword.put(body, :body, [literal])}
                   | clean_build_ast(markup, [], nimble_context)
                 ], %{tags: []}}

              _ ->
                {:ok, {tag_name, Keyword.put(body, :body, [literal | acc])}, nimble_context}
            end

          {:error, error_message, rest_markup} ->
            {:error, error_message, rest_markup}
        end

      _ ->
        {:ok, [], context}
    end
  end

  def build_ast(markup, ast, context) do
    case Tokenizer.tokenize(markup) do
      {literal, ""} ->
        {:ok, [literal | ast], context}

      {"", liquid} ->
        case process_markup(liquid, context) do
          {:ok, acc, nimble_context} -> {:ok, [acc | ast] |> List.flatten(), nimble_context}
          {:error, error_message, rest_markup} -> {:error, error_message, rest_markup}
        end

      {literal, liquid} ->
        case process_markup(liquid, context) do
          {:ok, acc, nimble_context} ->
            {:ok, [acc | [literal | ast]] |> List.flatten(), nimble_context}

          {:error, error_message, rest_markup} ->
            {:error, error_message, rest_markup}
        end
    end
  end

  defp clean_build_ast(markup, ast, context) do
    case build_ast(markup, ast, context) do
      {:ok, ast, _context} -> ast
    end
  end
end
