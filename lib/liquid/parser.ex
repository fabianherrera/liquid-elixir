defmodule Liquid.Parser do
  @moduledoc """
  Transform a valid liquid markup in an AST to be executed by `render`.
  """
  import NimbleParsec

  alias Liquid.Combinators.{General, LexicalToken}
  alias Liquid.Combinators.Tags.Generic
  alias Liquid.Ast

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
      parsec(:liquid_tag),
      parsec(:liquid_variable)
    ])
  )

  defparsec(:assign, Assign.tag())

  defparsec(:increment, Increment.tag())

  defparsec(:decrement, Decrement.tag())

  defparsec(:cycle_values, Cycle.cycle_values())
  defparsec(:cycle, Cycle.tag())

  defparsec(:include, Include.tag())

  defparsec(:comment_content, Comment.comment_content())
  defparsec(:comment, Comment.tag())

  defparsecp(:raw_content, Raw.raw_content())
  defparsec(:raw, Raw.tag())

  defparsec(:capture, Capture.tag2())

  defparsec(:if, If.tag2())
  defparsec(:elsif, If.elsif_tag2())
  defparsec(:unless, If.unless_tag2())

  defparsec(:for, For.tag2())
  defparsec(:break_tag, For.break_tag())
  defparsec(:continue_tag, For.continue_tag())

  defparsec(:ifchanged, Ifchanged.tag2())

  defparsec(:tablerow, Tablerow.tag2())

  defparsec(:case, Case.tag2())
  defparsec(:when, Case.when_tag2())

  defparsec(:else, Generic.else_tag2())

  defparsec(:custom, CustomTag.tag2())

  defparsec(:end_block, EndBlock.tag())

  defparsec(
    :liquid_tag,
    # The tag order affects the parser execution any change can break the app
    choice([
      parsec(:raw),
      parsec(:comment),
      parsec(:if),
      parsec(:unless),
      parsec(:for),
      parsec(:case),
      parsec(:capture),
      parsec(:tablerow),
      parsec(:cycle),
      parsec(:assign),
      parsec(:increment),
      parsec(:decrement),
      parsec(:include),
      parsec(:ifchanged),
      parsec(:else),
      parsec(:when),
      parsec(:elsif),
      parsec(:break_tag),
      parsec(:continue_tag),
      parsec(:end_block),
      parsec(:custom)
    ])
  )

  @doc """
  Validates and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    case Ast.build(markup, %{tags: []}, []) do
      {:ok, template, %{tags: []}, ""} ->
        {:ok, template}

      {:ok, _, %{tags: [unclosed | _]}, ""} ->
        {:error, "Malformed tag, open without close: '#{unclosed}'", ""}

      {:error, message, rest_markup} ->
        {:error, message, rest_markup}
    end
  end
end
