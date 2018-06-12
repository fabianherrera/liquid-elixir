defmodule Liquid.Combinators.Translators.For do
  alias Liquid.Block
  alias Liquid.Combinators.Translators.General
  alias Liquid.NimbleTranslator

  def translate(for_statements: [variable: variable, value: value, for_params: for_params], for_body: for_body, else: else_body) do
      create_block_for(variable, value, for_params, for_body, else_body)
  end

  def translate(for_statements: [variable: variable, value: value, for_params: for_params], for_body: for_body) do
    create_block_for(variable, value, for_params, for_body, [])
  end

  defp create_block_for(variable, value, for_params, for_body, else_body) do
    variable_markup = Enum.join(variable)
    for_params_markup = Enum.join(for_params)
    markup = "#{variable_markup} in #{value} #{for_params_markup}"
    %Liquid.Block{
    elselist: General.types_no_list(NimbleTranslator.process_node(else_body)),
    iterator: process_iterator(%Block{markup: markup}),
    markup: markup,
    name: :for,
    nodelist: General.types_only_list(NimbleTranslator.process_node(for_body))
    }
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

end
