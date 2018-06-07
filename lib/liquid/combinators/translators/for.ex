defmodule Liquid.Combinators.Translators.For do
  alias Liquid.Block
  alias Liquid.Combinators.Translators.General
  alias Liquid.NimbleTranslator

  def translate(for_collection: for_collection, for_body: for_body, else: else_body) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      elselist: General.types_no_list(NimbleTranslator.process_node(else_body)),
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: General.types_only_list(NimbleTranslator.process_node(for_body))
    }
  end

  def translate(for_collection: for_collection, for_body: for_body) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: General.types_only_list(NimbleTranslator.process_node(for_body))
    }
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

  defp process_for_markup(for_collection) do
    variable = Keyword.get(for_collection, :variable_name)
    value = concat_for_value_in_markup(Keyword.get(for_collection, :value))
    range_value = concat_for_value_in_markup(Keyword.get(for_collection, :range_value))
    for_params = concat_for_params_in_markup(Keyword.get(for_collection, :for_params))
    "#{variable} in #{value}#{range_value}" <> for_params
  end

  defp concat_for_value_in_markup(value) do
    if is_nil(value), do: "", else: General.values_to_string(value)
  end

  defp concat_for_params_in_markup([]), do: ""

  defp concat_for_params_in_markup(for_params) do
    for_params
    |> Enum.map(fn param ->
      case param do
        {:reversed_param, _value} -> " reversed"
        {:offset_param, value} -> " offset:#{General.values_to_string(value)}"
        {:limit_param, value} -> " limit:#{General.values_to_string(value)}"
        _ -> ""
      end
    end)
    |> List.to_string()
  end
end
