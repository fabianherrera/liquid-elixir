defmodule Liquid.NimbleTranslator do
  @moduledoc """
  Translate NimbleParser AST to old AST.
  """
  alias Liquid.Template

  alias Liquid.Translators.Tags.{
    Assign,
    Break,
    Capture,
    Case,
    Comment,
    Continue,
    Cycle,
    Decrement,
    For,
    If,
    Ifchanged,
    Include,
    Increment,
    LiquidVariable,
    Raw,
    Tablerow,
    Unless,
    CustomTag,
    CustomBlock
  }

  @doc """
  Converts Nimble AST into old AST in order to use old render.
  """
  def translate({:ok, [""]}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def translate({:ok, [literal_text]}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def translate({:ok, nodelist}) when is_list(nodelist) do
    list = process_node(nodelist)
    %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  ############################ multi ##################################

  def translate_multiprocess_node({:ok, [""]}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def translate_multiprocess_node({:ok, [literal_text]}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def translate_multiprocess_node({:ok, nodelist}) when is_list(nodelist) do
    list = multiprocess_node(nodelist, self())
    %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  defp multiprocess_node(nodelist, external_process) do
    nodelist
    |> Enum.map(fn elem ->
      spawn_link(fn -> send(external_process, {self(), process_node_multi(elem)}) end)
    end)
    |> Enum.map(fn pid ->
      receive do
        {^pid, result} -> result
      end
    end)
  end

  def process_node_multi(elem) when is_bitstring(elem), do: elem

  def process_node_multi([elem]) when is_bitstring(elem), do: elem

  def process_node_multi(nodelist) when is_list(nodelist) do
    multiprocess_node(nodelist, self())
  end

  def process_node_multi({tag, markup}) do
    translated =
      case tag do
        :liquid_variable -> LiquidVariable.translate(markup)
        :assign -> Assign.translate(markup)
        :capture -> Capture.translate(markup)
        :comment -> Comment.translate(markup)
        :cycle -> Cycle.translate(markup)
        :decrement -> Decrement.translate(markup)
        :for -> For.translate(markup)
        :if -> If.translate(markup)
        :unless -> Unless.translate(markup)
        :elsif -> If.translate(markup)
        :else -> process_node(markup)
        :include -> Include.translate(markup)
        :increment -> Increment.translate(markup)
        :tablerow -> Tablerow.translate(markup)
        :ifchanged -> Ifchanged.translate(markup)
        :raw -> Raw.translate(markup)
        :break -> Break.translate(markup)
        :continue -> Continue.translate(markup)
        :case -> Case.translate(markup)
        :custom_tag -> CustomTag.translate(markup)
        :custom_block -> CustomBlock.translate(markup)
      end

    check_blank(translated)
  end

  ################################ single ########################################

  @doc """
  Takes the new parsed tag and match it with his translator, then return the old parser struct.
  """
  @spec process_node(Liquid.NimbleParser.t()) :: Liquid.Tag.t() | Liquid.Block.t()
  def process_node(elem) when is_bitstring(elem), do: elem

  def process_node([elem]) when is_bitstring(elem), do: elem

  def process_node(nodelist) when is_list(nodelist) do
    Enum.map(nodelist, &process_node/1)
  end

  def process_node({tag, markup}) do
    translated =
      case tag do
        :liquid_variable -> LiquidVariable.translate(markup)
        :assign -> Assign.translate(markup)
        :capture -> Capture.translate(markup)
        :comment -> Comment.translate(markup)
        :cycle -> Cycle.translate(markup)
        :decrement -> Decrement.translate(markup)
        :for -> For.translate(markup)
        :if -> If.translate(markup)
        :unless -> Unless.translate(markup)
        :elsif -> If.translate(markup)
        :else -> process_node(markup)
        :include -> Include.translate(markup)
        :increment -> Increment.translate(markup)
        :tablerow -> Tablerow.translate(markup)
        :ifchanged -> Ifchanged.translate(markup)
        :raw -> Raw.translate(markup)
        :break -> Break.translate(markup)
        :continue -> Continue.translate(markup)
        :case -> Case.translate(markup)
        :custom_tag -> CustomTag.translate(markup)
        :custom_block -> CustomBlock.translate(markup)
      end

    check_blank(translated)
  end

  @doc """
  Emulates the `Liquid` behavior for blanks blocks. Checks all the blocks and determine if it is blank or not.
  """
  @spec check_blank(Liquid.Tag.t() | Liquid.Block.t()) :: Liquid.Tag.t() | Liquid.Block.t()
  def check_blank(%Liquid.Block{name: :if, nodelist: nodelist, elselist: elselist} = translated)
      when is_list(nodelist) and is_list(elselist) do
    if Blank.blank?(nodelist) and Blank.blank?(elselist) do
      %{translated | blank: true}
    else
      translated
    end
  end

  def check_blank(%Liquid.Block{nodelist: nodelist} = translated)
      when is_list(nodelist) do
    if Blank.blank?(nodelist) do
      %{translated | blank: true}
    else
      translated
    end
  end

  def check_blank(translated), do: translated
end
