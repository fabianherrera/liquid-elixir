defmodule Liquid.Translators.Tags.If do
  alias Liquid.Translators.{General, Markup}

  def translate(conditions: [value], body: body) when is_bitstring(value) do
    nodelist = Enum.filter(body, &General.not_open_if(&1))
    else_list = Enum.filter(body, &General.is_else/1)
    create_block_if("\"#{Markup.literal(value)}\"", nodelist, else_list)
  end

  def translate(conditions: conditions, body: body) do
    nodelist = Enum.filter(body, &General.not_open_if(&1))
    else_list = Enum.filter(body, &General.is_else/1)
    #TODO: Check Enum.join(conditions)
    create_block_if(Enum.join(conditions), nodelist, else_list)
  end

  defp create_block_if(markup, nodelist, else_list) do
    block = %Liquid.Block{
      name: :if,
      markup: markup,
      nodelist: General.types_only_list(Liquid.NimbleTranslator.process_node(nodelist)),
      blank: Blank.blank?(nodelist) and Blank.blank?(else_list),
      elselist:
        General.types_only_list(Liquid.NimbleTranslator.process_node(else_list) |> List.flatten())
    }

    Liquid.IfElse.parse_conditions(block)
  end
end
