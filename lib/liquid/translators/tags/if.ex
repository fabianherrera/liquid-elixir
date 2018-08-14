defmodule Liquid.Translators.Tags.If do
  @moduledoc """
  Translate new AST to old AST for the If tag
  """
  alias Liquid.Translators.{General, Markup}
  alias Liquid.Combinators.Tags.If
  alias Liquid.{Block, IfElse, NimbleTranslator}

  @doc """
  Takes the markup of the new AST, creates a `Liquid.Block` struct (old AST) and fill the keys needed to render a If tag
  """
  @spec translate(If.conditional_body()) :: Block.t()
  def translate(conditions: [value], body: body) when is_bitstring(value) do
    nodelist = Enum.filter(body, fn tag -> !General.conditional_statement?(tag) end)
    else_list = Enum.filter(body, &General.else?/1)
    create_block_if("\"#{Markup.literal(value)}\"", nodelist, else_list)
  end

  def translate(conditions: conditions, body: body) do
    nodelist = Enum.filter(body, fn tag -> !General.conditional_statement?(tag) end)
    else_list = Enum.filter(body, &General.else?/1)
    # TODO: Check Enum.join(conditions)
    create_block_if(Enum.join(conditions), nodelist, else_list)
  end

  defp create_block_if(markup, nodelist, else_list) do
    block = %Liquid.Block{
      name: :if,
      markup: markup,
      nodelist: General.types_only_list(NimbleTranslator.process_node(nodelist)),
      blank: Blank.blank?(nodelist) and Blank.blank?(else_list),
      elselist: else_list |> NimbleTranslator.process_node() |> List.flatten() |> General.types_only_list()
    }

    IfElse.parse_conditions(block)
  end
end
