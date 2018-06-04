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

  defp to_case_block(%Liquid.Block{markup: markup} = b) do
    [[_, name]] = Liquid.Case.syntax() |> Regex.scan(markup)
    Liquid.Case.split(name |> Liquid.Variable.create(), b.nodelist)
  end
end
