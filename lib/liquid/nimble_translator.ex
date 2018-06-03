defmodule Liquid.NimbleTranslator do
  @moduledoc """
  Translate NimbleParser's AST to old AST
  """
  alias Liquid.Template

  alias Liquid.Combinators.Translators.{
    Assign,
    LiquidVariable,
    Cycle,
    Increment,
    Decrement,
    Capture,
    Comment,
    Include,
    For,
    Tablerow
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

  # When the element its a string literal text
  defp process_node(elem) when is_bitstring(elem), do: elem

  # When the element its one string literal text inside a list
  defp process_node([elem]) when is_bitstring(elem), do: elem

  # When the element its a list
  defp process_node(nodelist) when is_list(nodelist) do
    multiprocess_node(nodelist, self())
  end

  # When the element its a tuple
  defp process_node({tag, markup}) do
    IO.inspect(markup)

    case tag do
      :assign -> Assign.translate(markup)
      :liquid_variable -> LiquidVariable.translate(markup)
      :cycle -> Cycle.translate(markup)
      :increment -> Increment.translate(markup)
      :decrement -> Decrement.translate(markup)
      :capture -> Capture.translate(markup)
      :comment -> Comment.translate(markup)
      :include -> Include.translate(markup)
      :for -> For.translate(markup)
      :tablerow -> Tablerow.translate(markup)


      # {:increment, markup} = elem -> Increment.translate(markup)
      # {:increment, markup} = elem -> Increment.translate(markup)
      # {:decrement, markup} = elem -> Decrement.translate(markup)
      # {:capture, markup} = elem -> Capture.translate(markup)
      _ ->
        markup
    end
  end
end
