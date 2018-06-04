defmodule Liquid.Combinators.Translators.Unless do
  alias Liquid.Combinators.Translators.General

  def translate(if_condition: if_condition, body: body) do
    nodelist = Enum.filter(body, &General.not_open_if(&1))
    else_list = Enum.filter(body, &General.is_else/1)
    markup_string = General.if_markup_to_string(if_condition) |> List.to_string()

    block = %Liquid.Block{
      name: :unless,
      markup: markup_string,
      nodelist: Liquid.NimbleTranslator.process_node(nodelist),
      elselist: Liquid.NimbleTranslator.process_node(else_list)
    }

    Liquid.IfElse.parse_conditions(block)
  end
end
