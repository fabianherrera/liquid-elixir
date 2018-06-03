defmodule Liquid.Combinators.Translators.Include do
  alias Liquid.{Tag, Include}
  def translate(markup) do
    markup = process_include_markup(markup)
    Include.parse(%Tag{markup: markup, name: :include})
  end

  def process_include_markup(snippet: [snippet]), do: snippet

  def process_include_markup(snippet: [snippet], with_param: [variable: [variable]]),
    do: "#{snippet} with #{variable}"

  def process_include_markup(snippet: [snippet], for_param: [variable: [variable]]),
    do: "#{snippet} for #{variable}"

  def process_include_markup(snippet: [snippet], variables: variables) do
    parts = Enum.map(variables, &concat_include_variables_in_markup(&1))
    variables = Enum.join(parts, ", ")
    "#{snippet}, #{variables}"
  end

  defp concat_include_variables_in_markup({:variable, [variable_name: [variable], value: value]}),
    do: "#{variable} '#{value}'"

  defp concat_include_variables_in_markup(
    {:variable, [variable_name: [variable], value: {:variable, [value]}]}
  ),
    do: "#{variable} #{value}"

end
# General.values_to_string(value)