defmodule Liquid.Combinators.Translators.Assign do
  alias Liquid.Combinators.Translators.General

  def translate(markup) do
    cond do
      length(markup) == 2 ->
        value = Keyword.get(markup, :value)
        variable_name = Keyword.get(markup, :variable_name)

        if is_tuple(value) do
          variable = value |> elem(1)
          string_variable = Enum.map(variable,
            &General.variable_in_parts/1)
            |> General.variable_to_string()

          %Liquid.Tag{
            name: :assign,
            markup: "#{variable_name} = '#{string_variable}'",
            blank: true
          }
        else
          %Liquid.Tag{name: :assign, markup: "#{variable_name} = '#{value}'", blank: true}
        end

      length(markup) > 2 ->
        value = Keyword.get(markup, :value)
        variable_name = Keyword.get(markup, :variable_name)
        variable = value |> elem(1)
        string_variable = Enum.map(variable,
          &General.variable_in_parts/1)
        |> General.variable_to_string()
        filters =
          Keyword.get_values(markup, :filter)
          |> Enum.map(&General.filters_to_string/1)
          |> List.to_string()

        %Liquid.Tag{
          name: :assign,
          markup: "#{variable_name} = '#{string_variable}' #{filters}",
          blank: true
        }
    end
  end
end
