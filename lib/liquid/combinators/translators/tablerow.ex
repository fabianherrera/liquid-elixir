defmodule Liquid.Combinators.Translators.Tablerow do
  alias Liquid.Block
  alias Liquid.Combinators.Translators.General
  alias Liquid.NimbleTranslator

   def translate([tablerow_collection: tablerow_collection, tablerow_body: tablerow_body]) do
    markup = process_tablerow_markup(tablerow_collection)

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

  defp process_tablerow_markup(tablerow_collection) do
    variable = Keyword.get(tablerow_collection, :variable_name)
    value = concat_tablerow_value_in_markup(Keyword.get(tablerow_collection, :value))
    range_value = concat_tablerow_value_in_markup(Keyword.get(tablerow_collection, :range_value))
    tablerow_params = concat_tablerow_params_in_markup(Keyword.get(tablerow_collection, :tablerow_params))
    "#{variable} in #{value}#{range_value}" <> tablerow_params
  end

  defp concat_tablerow_value_in_markup(value) do
    if is_nil(value), do: "", else: General.values_to_string(value)
  end

  defp concat_tablerow_params_in_markup([]), do: ""

  defp concat_tablerow_params_in_markup(tablerow_params) do
    tablerow_params
    |>  Enum.map(fn  param ->
      case param do
        {:cols_param, value} -> " cols:#{General.values_to_string(value)}"
        {:offset_param, value} -> " offset:#{General.values_to_string(value)}"
        {:limit_param, value} -> " limit:#{General.values_to_string(value)}"
        _ -> ""
      end
    end)
    |> List.to_string()
  end

end