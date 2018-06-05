defmodule Liquid.Combinators.Translators.Case do
  alias Liquid.Combinators.Translators.General

  def translate(variable: [:parts, part]) do
    variable_in_string =
      General.variable_in_parts(part)
      |> General.variable_to_string()

    %Liquid.Block{name: :case, markup: variable_in_string, nodelist: []}
  end

  def translate(variable: parts, whens: whens) do
    [parts: part] = parts

    variable_in_string =
      General.variable_in_parts(part)
      |> General.variable_to_string()

    nodelist = Enum.map(whens, &when_to_nodelist/1)
    block = %Liquid.Block{name: :case, markup: variable_in_string, nodelist: nodelist}
    to_case_block(block)
  end

  def translate(variable: parts, whens: whens, else: else_tag_values) do
    [parts: part] = parts

    variable_in_string =
      General.variable_in_parts(part)
      |> General.variable_to_string()

    nodelist = Enum.map(whens, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist | else_tag(else_tag_values)]
    new_nodelist = List.flatten(nodelist_plus_else)
    block = %Liquid.Block{name: :case, markup: variable_in_string, nodelist: new_nodelist}
    to_case_block(block)
  end

  defp when_to_nodelist({:when, value}) do
    markup_list = General.if_markup_to_string(value)
    markup_string = List.to_string(markup_list)

    %Liquid.Tag{
      name: :when,
      markup: markup_string
    }
  end

  defp when_to_nodelist(any) do
    Liquid.NimbleTranslator.process_node(any)
  end

  defp else_tag(values) do
    process_list = Liquid.NimbleTranslator.process_node(values)

    if is_list(process_list) do
      else_liquid_tag = %Liquid.Tag{
        name: :else
      }

      [else_liquid_tag | process_list]
    else
      else_liquid_tag = %Liquid.Tag{
        name: :else
      }

      [else_liquid_tag, process_list]
    end
  end

  defp to_case_block(%Liquid.Block{markup: markup} = b) do
    [[_, name]] = Liquid.Case.syntax() |> Regex.scan(markup)
    Liquid.Case.split(name |> Liquid.Variable.create(), b.nodelist)
  end
end
