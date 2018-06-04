defmodule Liquid.Combinators.Translators.Include do
  alias Liquid.{Tag, Include}
  alias Liquid.Combinators.Translators.General

  def translate(markup) do
    markup = process_include_markup(markup)
    Include.parse(%Tag{markup: markup, name: :include})
  end

  def process_include_markup(snippet: [snippet]), do: snippet

  def process_include_markup(snippet: [snippet], with_param: [variable]) do
    with_param_value_string = General.values_to_string(variable)
    "#{snippet} with #{with_param_value_string}"
  end

  def process_include_markup(snippet: [snippet], for_param: [variable]) do
    for_param_value_string = General.values_to_string(variable)
    "#{snippet} for #{for_param_value_string}"
  end

  def process_include_markup(snippet: [snippet], variables: variables) do
    parts = Enum.map(variables, &concat_include_variables_in_markup(&1))
    variables = Enum.join(parts, ", ")
    "#{snippet}, #{variables}"
  end

  defp concat_include_variables_in_markup({:variable, [variable_name: [variable], value: value]}) do
    value_string =  General.values_to_string(value)
    "#{variable} #{value_string}"
  end

end