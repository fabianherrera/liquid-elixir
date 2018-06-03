defmodule Liquid.NimbleTranslator do
  @moduledoc """
  Translate NimbleParser's AST to old AST
  """
  alias Liquid.Template

  alias Liquid.Combinators.Translators.{
    LiquidVariable,
    Assign,
    Capture,
    Comment,
    Cycle,
    Decrement,
    For,
    If,
    Include,
    Increment,
    Tablerow,
  }

  @doc """
  Converts passed Nimble AST into old AST to use old render
  """
  def translate({:ok, [""]}) do
    %Template{root: %Liquid.Block{name: :document}}
  end

  def translate({:ok, [literal_text]}) when is_bitstring(literal_text) do
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def translate({:ok, nodelist}) when is_list(nodelist) do
    list = multiprocess_node(nodelist, self())
    %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  defp multiprocess_node(nodelist, external_process) do
    nodelist
    |> Enum.map(fn elem ->
      spawn_link(fn -> send(external_process, {self(), process_node(elem)}) end)
    end)
    |> Enum.map(fn pid ->
      receive do
        {^pid, result} -> result
      end
    end)
  end

  def process_node(elem) when is_bitstring(elem), do: elem

  def process_node([elem]) when is_bitstring(elem), do: elem

  def process_node(nodelist) when is_list(nodelist) do
    multiprocess_node(nodelist, self())
  end

  def process_node({tag, markup}) do
    case tag do
      :liquid_variable -> LiquidVariable.translate(markup)
      :assign -> Assign.translate(markup)
      :capture -> Capture.translate(markup)
      :comment -> Comment.translate(markup)
      :cycle -> Cycle.translate(markup)
      :decrement -> Decrement.translate(markup)
      :for -> For.translate(markup)
      :if -> If.translate(markup)
      :elsif -> If.translate(markup)
      :else -> translate({:ok, markup})
      :include -> Include.translate(markup)
      :increment -> Increment.translate(markup)
      :tablerow -> Tablerow.translate(markup)
      _ -> markup
    end
  end
end
