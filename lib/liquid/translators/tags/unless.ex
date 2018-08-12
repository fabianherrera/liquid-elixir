defmodule Liquid.Translators.Tags.Unless do
  @moduledoc """
  Translate new AST to old AST for the Unless tag
  """

  alias Liquid.Translators.General
  alias Liquid.Combinators.Tags.If
  alias Liquid.Block

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a Unless tag
  """

  @spec translate(If.conditional_body()) :: Block.t()
  def translate(conditions: [value], body: body) when is_bitstring(value) do
    nodelist = Enum.filter(body, &General.not_open_if(&1))
    else_list = Enum.filter(body, &General.is_else/1)
    create_block_if("\"#{value}\"", nodelist, else_list)
  end

  def translate(conditions: conditions, body: body) do
    nodelist = Enum.filter(body, &General.not_open_if(&1))
    else_list = Enum.filter(body, &General.is_else/1)
    create_block_if(Enum.join(conditions), nodelist, else_list)
  end

  defp create_block_if(markup, nodelist, else_list) do
    block = %Liquid.Block{
      name: :unless,
      markup: markup,
      nodelist: Liquid.NimbleTranslator.process_node(nodelist),
      elselist: Liquid.NimbleTranslator.process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end
end
