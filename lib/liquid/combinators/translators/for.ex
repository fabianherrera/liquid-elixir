defmodule Liquid.Combinators.Translators.For do
  alias Liquid.Block
  alias Liquid.Combinators.Translators.General
  alias Liquid.NimbleTranslator

  def translate([for_collection: for_collection, for_body: for_body, else: else_body]) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      elselist: fixer_for_types_no_list(NimbleTranslator.translate(else_body)),
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(NimbleTranslator.translate(for_body))
    }
  end

  def translate([for_collection: for_collection, for_body: for_body]) do
    markup = process_for_markup(for_collection)

    %Liquid.Block{
      iterator: process_iterator(%Block{markup: markup}),
      markup: markup,
      name: :for,
      nodelist: fixer_for_types_only_list(NimbleTranslator.translate(for_body))
    }
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_no_list(element) do
    if is_list(element), do: List.first(element), else: element
  end

  # fix current parser for tag bug and compatibility
  defp fixer_for_types_only_list(element) do
    if is_list(element), do: element, else: [element]
  end

  defp process_iterator(%Block{markup: markup}) do
    Liquid.ForElse.parse_iterator(%Block{markup: markup})
  end

  defp process_for_markup(for_collection) do
    variable = Keyword.get(for_collection, :variable_name)
    value = concat_for_value_in_markup(Keyword.get(for_collection, :value))
    range_value = concat_for_value_in_markup(Keyword.get(for_collection, :range_value))
    for_param = concat_for_params_in_markup(for_collection)
    "#{variable} in #{value}#{range_value}" <> for_param
  end

  defp concat_for_value_in_markup(value) when is_nil(value), do: ""

  defp concat_for_value_in_markup({:variable, values}) do
    parts = Enum.map(values, &General.variable_in_parts/1)
    value_string = General.variable_to_string(parts)
    value_string
  end

  defp concat_for_value_in_markup(start: start_range, end: end_range) do
    "(#{to_string(start_range)}..#{to_string(end_range)})"
  end

  defp concat_for_params_in_markup(for_collection) do
    offset_param = Keyword.get(for_collection, :offset_param)
    limit_param = Keyword.get(for_collection, :limit_param)
    reversed_param = Keyword.get(for_collection, :reversed_param)

    offset_string =
      if is_nil(offset_param), do: "", else: " offset:#{to_string(List.first(offset_param))}"

    limit_string =
      if is_nil(limit_param), do: "", else: " limit:#{to_string(List.first(limit_param))}"

    reversed_string = if is_nil(reversed_param), do: "", else: " reversed"
    "#{reversed_string}#{offset_string}#{limit_string}"
  end

end
