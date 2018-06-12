defmodule Liquid.Combinators.Translators.Tablerow do
  alias Liquid.Block
  alias Liquid.NimbleTranslator

  def translate(tablerow_statements: [variable: variable, value: value, tablerow_params: tablerow_params], tablerow_body: tablerow_body) do
    variable_markup = Enum.join(variable)
    tablerow_params_markup = Enum.join(tablerow_params)
    markup = "#{variable_markup} in #{value} #{tablerow_params_markup}"

    %Liquid.Block{
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :tablerow,
      nodelist: fixer_tablerow_types_only_list(NimbleTranslator.process_node(tablerow_body))
    }
  end

  # fix current parser tablerow tag bug and compatibility
  defp fixer_tablerow_types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.TableRow.parse_iterator(%Block{markup: markup})
  end

end
