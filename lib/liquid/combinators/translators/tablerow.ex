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
    tablerow_param = concat_tablerow_params_in_markup(tablerow_collection)
    "#{variable} in #{value}#{range_value}" <> tablerow_param
  end

  defp concat_tablerow_value_in_markup(value) when is_nil(value), do: ""

  defp concat_tablerow_value_in_markup({:variable, [variable_parts: values]}) do
    parts = Enum.map(values, &General.variable_in_parts/1)
    value_string = General.variable_to_string(parts)
    value_string
  end

  defp concat_tablerow_value_in_markup(start: start_range, end: end_range) do
    "(#{to_string(start_range)}..#{to_string(end_range)})"
  end

  defp concat_tablerow_params_in_markup(tablerow_collection) do
    offset_param = Keyword.get(tablerow_collection, :offset_param)
    limit_param = Keyword.get(tablerow_collection, :limit_param)
    cols_param = Keyword.get(tablerow_collection, :cols_param)

    offset_string =
      if is_nil(offset_param), do: "", else: " offset:#{to_string(List.first(offset_param))}"

    limit_string =
      if is_nil(limit_param), do: "", else: " limit:#{to_string(List.first(limit_param))}"

    cols_string =
      if is_nil(cols_param), do: "", else: " limit:#{to_string(List.first(cols_param))}"
    "#{cols_string}#{offset_string}#{limit_string}"
  end

end

[
  "a",
  {:tablerow,
    [
      tablerow_collection: [
        variable_name: ["n"],
        value: {:variable, [variable_parts: ["numbers"]]},
        cols_param: [3]
      ],
      tablerow_body: [
        " ",
        {:liquid_variable, [variable: [variable_parts: ["n"]]]},
        " "
      ]
    ]}
]