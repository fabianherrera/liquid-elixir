defmodule Liquid.Combinators.Translators.LiquidVariable do
  alias Liquid.Combinators.Translators.General

  def translate(variable: [parts: variable_list]) do
    parts = General.variable_in_parts(variable_list)
    variable_name = Enum.join(parts: variable_list)
    %Liquid.Variable{name: variable_name, parts: parts}
  end

  def translate(variable: [parts: variable_list, filters: filters]) do
    parts = General.variable_in_parts(variable_list)
    variable_name = Enum.join(parts: variable_list)
    filters_markup = transform_filters(filters)
    %Liquid.Variable{name: variable_name, parts: parts, filters: filters_markup}
  end

  def translate([value, filters: filters]) when is_bitstring(value) do
    filters_markup = transform_filters(filters)
    %Liquid.Variable{name: "'#{value}'", filters: filters_markup, literal: "#{value}"}
  end

  def translate([value, filters: filters]) do
    filters_markup = transform_filters(filters)
    %Liquid.Variable{name: "#{value}", filters: filters_markup, literal: value}
  end

  def translate([value]) when is_bitstring(value),
    do: %Liquid.Variable{name: "'#{value}'", literal: "#{value}"}

  def translate([value]), do: %Liquid.Variable{name: "#{value}", literal: value}

  defp transform_filters(filters_list) do
    Keyword.get_values(filters_list, :filter)
    |> Enum.map(&filters_to_list/1)
  end

  defp filters_to_list([filter_name]) do
    [String.to_atom(filter_name), []]
  end

  defp filters_to_list([filter_name, filter_param]) do
    {_, param_value} = filter_param
    filter_list = Enum.map(param_value, &to_string/1)
    [String.to_atom(filter_name), filter_list]
  end
end
