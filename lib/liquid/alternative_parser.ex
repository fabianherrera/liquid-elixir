defmodule Liquid.AlternativeParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`.
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}
  alias Liquid.Tokenizer

  alias Liquid.Combinators.Tags.{
    Assign,
    Comment,
    Decrement,
    EndBlock,
    Increment,
    Include,
    Raw,
    Cycle,
    If,
    For,
    Tablerow,
    Case,
    Capture,
    Ifchanged,
    CustomTag,
    CustomBlock
  }

  @type t :: [
          Assign.t()
          | Capture.t()
          | Increment.t()
          | Decrement.t()
          | Include.t()
          | Cycle.t()
          | Raw.t()
          | Comment.t()
          | For.t()
          | If.t()
          | Unless.t()
          | Tablerow.t()
          | Case.t()
          | Ifchanged.t()
          | CustomTag.t()
          | CustomBlock.t()
          | General.liquid_variable()
          | String.t()
        ]

  defparsec(:liquid_variable, General.liquid_variable())
  defparsec(:variable_definition, General.variable_definition())
  defparsec(:variable_name, General.variable_name())
  defparsec(:quoted_variable_name, General.quoted_variable_name())
  defparsec(:variable_definition_for_assignment, General.variable_definition_for_assignment())
  defparsec(:variable_name_for_assignment, General.variable_name_for_assignment())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:start_variable, General.start_variable())
  defparsec(:end_variable, General.end_variable())
  defparsec(:filter_param, General.filter_param())
  defparsec(:filter, General.filter())
  defparsec(:filters, General.filters())
  defparsec(:single_quoted_token, General.single_quoted_token())
  defparsec(:double_quoted_token, General.double_quoted_token())
  defparsec(:quoted_token, General.quoted_token())
  defparsec(:comparison_operators, General.comparison_operators())
  defparsec(:logical_operators, General.logical_operators())
  defparsec(:ignore_whitespaces, General.ignore_whitespaces())
  defparsec(:condition, General.condition())
  defparsec(:logical_condition, General.logical_condition())

  defparsec(:null_value, LexicalToken.null_value())
  defparsec(:number, LexicalToken.number())
  defparsec(:value_definition, LexicalToken.value_definition())
  defparsec(:value, LexicalToken.value())
  defparsec(:object_property, LexicalToken.object_property())
  defparsec(:boolean_value, LexicalToken.boolean_value())
  defparsec(:string_value, LexicalToken.string_value())
  defparsec(:object_value, LexicalToken.object_value())
  defparsec(:variable_value, LexicalToken.variable_value())
  defparsec(:variable_part, LexicalToken.variable_part())

  defparsec(
    :__parse__,
    empty()
    |> choice([
      parsec(:liquid_variable),
      # parsec(:custom_block),
      # parsec(:custom_tag),
      parsec(:liquid_tag)
    ])
  )

  defparsec(:assign, Assign.tag())
  defparsec(:capture, Capture.tag2())
  defparsec(:decrement, Decrement.tag())
  defparsec(:increment, Increment.tag())

  defparsec(:comment_content, Comment.comment_content())
  defparsec(:comment, Comment.tag())

  defparsec(:cycle_values, Cycle.cycle_values())
  defparsec(:cycle, Cycle.tag())

  defparsec(:end_block, EndBlock.tag())

  defparsecp(:raw_content, Raw.raw_content())
  defparsec(:raw, Raw.tag())

  defparsec(:ifchanged, Ifchanged.tag())

  defparsec(:include, Include.tag())

  defparsec(:body_elsif, If.body_elsif())
  defparsec(:if, If.tag())
  defparsec(:elsif_tag, If.elsif_tag())
  defparsec(:unless, If.unless_tag())

  defparsec(:break_tag, For.break_tag())
  defparsec(:continue_tag, For.continue_tag())
  defparsec(:for, For.tag())

  defparsec(:tablerow, Tablerow.tag())

  defparsec(:case, Case.tag())
  defparsec(:clauses, Case.clauses())
  defparsec(:custom_tag, CustomTag.tag())
  defparsec(:custom_block, CustomBlock.block())

  defparsec(
    :liquid_tag,
    choice([
      parsec(:assign),
      parsec(:capture),
      parsec(:increment),
      parsec(:decrement),
      parsec(:include),
      parsec(:cycle),
      parsec(:raw),
      parsec(:comment),
      parsec(:end_block)
      # parsec(:for),
      # parsec(:break_tag),
      # parsec(:continue_tag),
      # parsec(:if),
      # parsec(:unless),
      # parsec(:tablerow),
      # parsec(:case),
      # parsec(:ifchanged)
    ])
  )

  defp process_liquid_block(markup, ast, context, rest) do
    case parser(markup, [], context, rest) do
      {:ok, template, %{tags: []}, rest} when is_list(template) ->
        {rest, Enum.reverse([acc | ast]), context, rest}

      {:ok, template, %{tags: []}, rest} ->
        {:ok, [template]}

      {:ok, _, %{tags: [unclosed | _]}, _rest} ->
        {:error, "Malformed tag, open without close: '#{unclosed}'", ""}

      {:error, message, rest_markup} ->
        {:error, message, rest_markup}
    end
  end

  defp process_liquid(markup, ast, context) do
    case __parse__(markup, context: context) do
      {:ok, [block: liquid_acc], rest, liquid_context, _line, _offset} ->
        {rest, block_acc, liquid_context, rest} = process_liquid_block(rest, liquid_acc, liquid_context, rest) #
        {rest, [block_acc | ast], context, rest}

      {:ok, acc, rest, liquid_context, _line, _offset} ->
        {rest, [acc | ast], context, rest}

      {:error, error_message, rest_markup, _context, _, _} ->
        {:error, error_message, rest_markup}
    end
  end

  defp build_ast(:error, message, rest), do: {:error, message, rest}

  defp parser("", ast, context, rest), do: {:ok, ast, context, rest}

  defp parser(markup, acc, context, rest) do
    case Tokenizer.tokenize(markup) do
      {literal, ""} ->
        {:ok, [literal | acc], context, ""}

      {"", liquid} ->
        {liquid_markup, liquid_ast, liquid_context, liquid_rest} = process_liquid(liquid, acc, context, rest)
        parser(liquid_markup, liquid_ast, liquid_context, liquid_rest)

      {literal, liquid} ->
        {liquid_markup, liquid_ast, liquid_context, acc, rest} = process_liquid(liquid, acc, context, rest)
        parser(liquid_markup, liquid_ast, liquid_context, rest)
         {[[literal | acc] | liquid_processed]}
    end
  end

  @doc """
  Validates and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    case parser(markup, [], %{tags: []}, markup) do
      {:ok, template, %{tags: []}, _rest} when is_list(template) ->
        {:ok, Enum.reverse(template)}

      {:ok, template, %{tags: []}, _rest} ->
        {:ok, [template]}

      {:ok, _, %{tags: [unclosed | _]}, _rest} ->
        {:error, "Malformed tag, open without close: '#{unclosed}'", ""}

      {:error, message, rest_markup} ->
        {:error, message, rest_markup}
    end
  end
end
