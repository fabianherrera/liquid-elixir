defmodule Liquid.Combinators.Translators.LiquidVariable do
  alias Liquid.Combinators.Translators.General

  def translate(markup) do
    literal = hd(markup)

    if is_tuple(literal) do
      {key, value} = literal
      literal_have_filters = Enum.any?(value, fn x -> have_filters(x) end)

      if literal_have_filters == true do
        variable_list = literal |> elem(1)
        variable_name = variable_list |> hd
        filters_list = Enum.filter(variable_list, fn x -> is_tuple(x) == true end)
        filters = transform_filters(filters_list)
        %Liquid.Variable{name: variable_name, parts: [variable_name], filters: filters}
      else
        variable_list = literal |> elem(1)
        filters = transform_filters(markup)
        parts = Enum.map(variable_list, &General.variable_in_parts/1)
        name = General.variable_to_string(parts)
        %Liquid.Variable{name: name, parts: parts, filters: filters}
      end
    else
      if is_number(literal) or is_boolean(literal) do
        variable_name = "#{literal}"
      else
        variable_name = "'#{literal}'"
      end

      filters_list = Enum.filter(markup, fn x -> is_tuple(x) == true end)
      filters = transform_filters(filters_list)
      %Liquid.Variable{name: variable_name, literal: literal, filters: filters}
    end
  end

  defp have_filters({value, _}), do: value == :filter
  defp have_filters(_), do: false

  defp transform_filters(filters_list) do
    Keyword.get_values(filters_list, :filter)
    |> Enum.map(&filters_to_list/1)
  end

  defp filters_to_list({filter_name}) do
    [String.to_atom(filter_name), []]
  end

  defp filters_to_list({filter_name, filter_param}) do
    filter_param_value = filter_param |> elem(1)
    value = Keyword.get(filter_param_value, :value)
    [String.to_atom(filter_name), ["#{value}"]]
  end
end
