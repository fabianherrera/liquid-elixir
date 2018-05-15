defmodule Liquid.NimbleParser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalTokens}

  alias Liquid.Combinators.Tags.{
    Assign,
    Comment,
    Decrement,
    Increment,
    Include,
    Raw,
    Cycle,
    If,
    For
  }

  defparsec(:liquid_variable, General.liquid_variable())
  defparsec(:variable_definition, General.variable_definition())
  defparsec(:variable_name, General.variable_name())
  defparsec(:start_tag, General.start_tag())
  defparsec(:end_tag, General.end_tag())
  defparsec(:single_quoted_token, General.single_quoted_token())
  defparsec(:double_quoted_token, General.double_quoted_token())
  defparsec(:token, General.token())
  defparsec(:math_operators, General.math_operators())
  defparsec(:logical_operators, General.logical_operators())
  defparsec(:ignore_whitespaces, General.ignore_whitespaces())

  defparsec(:number, LexicalTokens.number())
  defparsec(:value_definition, LexicalTokens.value_definition())
  defparsec(:value, LexicalTokens.value())
  defparsec(:object_property, LexicalTokens.object_property())
  defparsec(:object_value, LexicalTokens.object_value())
  defparsec(:range_value, LexicalTokens.range_value())

  defparsec(
    :__parse__,
    General.literal()
    |> optional(choice([parsec(:liquid_tag), parsec(:liquid_variable)]))
  )

  defparsec(:assign, Assign.tag())

  defparsec(:decrement, Decrement.tag())

  defparsec(:increment, Increment.tag())

  defparsecp(:open_tag_comment, Comment.open_tag())
  defparsecp(:close_tag_comment, Comment.close_tag())
  defparsecp(:not_close_tag_comment, Comment.not_close_tag_comment())
  defparsecp(:comment_content, Comment.comment_content())
  defparsec(:comment, Comment.tag())

  defparsec(:cycle_group, Cycle.cycle_group())
  defparsec(:last_cycle_value, Cycle.last_cycle_value())
  defparsec(:cycle_values, Cycle.cycle_values())
  defparsec(:cycle, Cycle.tag())

  defparsec(:open_tag_raw, Raw.open_tag())
  defparsec(:close_tag_raw, Raw.close_tag())
  defparsecp(:not_close_tag_raw, Raw.not_close_tag_raw())
  defparsec(:raw_content, Raw.raw_content())
  defparsec(:raw, Raw.tag())

  defparsecp(:snippet, Include.snippet())
  defparsec(:variable_atom, Include.variable_atom())
  defparsecp(:var_assignation, Include.var_assignation())
  defparsecp(:with_param, Include.with_param())
  defparsecp(:for_param, Include.for_param())
  defparsec(:include, Include.tag())

  defparsec(:if, If.open_tag())
  defparsec(:conditions, If.conditions())
  defparsecp(:logical_conditions, If.logical_conditions())

  defparsecp(:offset_param, For.offset_param())
  defparsecp(:limit_param, For.limit_param())
  defparsecp(:reversed_param, For.reversed_param())
  defparsecp(:open_tag_for, For.open_tag())
  defparsecp(:close_tag_for, For.close_tag())
  defparsecp(:else_tag_for, For.else_tag())
  defparsecp(:for_sentences, For.for_sentences())
  defparsec(:break_tag_for, For.break_tag())
  defparsec(:continue_tag_for, For.continue_tag())
  defparsec(:for, For.tag())


  defparsec(
    :liquid_tag,
    choice([
      parsec(:assign),
      parsec(:increment),
      parsec(:decrement),
      parsec(:include),
      parsec(:cycle),
      parsec(:raw),
      parsec(:comment),
      parsec(:for),
      parsec(:break_tag_for),
      parsec(:continue_tag_for)
    ])
  )

  @doc """
  Valid and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(""), do: {:ok, ""}

  def parse(markup) do
    case __parse__(markup) do
      {:ok, template, "", _, _, _} ->
        {:ok, template}

      {:ok, _, rest, _, _, _} ->
        {:error, "Error parsing: #{rest}"}
    end
  end
end
