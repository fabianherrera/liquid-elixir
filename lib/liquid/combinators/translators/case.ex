defmodule Liquid.Combinators.Translators.Case do
  alias Liquid.Combinators.Translators.General

  def translate(variable: [:parts, part]) do
    variable_in_string = variable_to_markup(part)

    %Liquid.Block{name: :case, markup: variable_in_string, nodelist: []}
  end

  def translate(variable: parts, whens: whens) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case(variable_in_string, whens)
  end

  def translate(variable: parts, whens: whens, else: else_tag_values) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case(variable_in_string, whens, else_tag_values)
  end

  def translate(variable: parts, else: else_tag_values) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case_else(variable_in_string, else_tag_values)
  end

  def translate([{:variable, parts}, badbody]) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    block = %Liquid.Block{name: :case, markup: variable_in_string, nodelist: badbody}
    to_case_block(block)
  end

  def translate([{:variable, parts}, badbody, {:whens, whens}]) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case(variable_in_string, badbody, whens)
  end

  def translate([{:variable, parts}, badbody, {:whens, whens}, {:else, else_tag_values}]) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case(variable_in_string, badbody, whens, else_tag_values)
  end

  def translate([{:variable, parts}, badbody, {:else, else_tag_values}]) do
    [parts: part] = parts
    variable_in_string = variable_to_markup(part)
    create_block_for_case_else(variable_in_string, badbody, else_tag_values)
  end

  def translate([value]) do
    markup = General.values_to_string(value)
    block = %Liquid.Block{name: :case, markup: markup}
    to_case_block(block)
  end

  def translate([value, {:whens, whens}]) do
    markup = General.values_to_string(value)
    create_block_for_case(markup, whens)
  end

  def translate([value, {:whens, whens}, {:else, else_tag_values}]) do
    markup = General.values_to_string(value)
    create_block_for_case(markup, whens, else_tag_values)
  end

  def translate([value, {:else, else_tag_values}]) do
    markup = General.values_to_string(value)
    create_block_for_case_else(markup, else_tag_values)
  end

  def translate([value, badbody, {:whens, whens}]) do
    markup = General.values_to_string(value)
    create_block_for_case(markup, badbody, whens)
  end

  def translate([value, badbody, {:whens, whens}, {:else, else_tag_values}]) do
    markup = General.values_to_string(value)
    create_block_for_case(markup, badbody, whens, else_tag_values)
  end

  def translate([value, badbody, {:else, else_tag_values}]) do
    markup = General.values_to_string(value)
    create_block_for_case_else(markup, badbody, else_tag_values)
  end

  def translate([value, badbody]) do
    markup = General.values_to_string(value)
    block = %Liquid.Block{name: :case, markup: markup, nodelist: [badbody]}
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

  defp create_block_for_case(markup, when_alone) do
    nodelist = Enum.map(when_alone, &when_to_nodelist/1)
    block = %Liquid.Block{name: :case, markup: markup, nodelist: nodelist}
    to_case_block(block)
  end

  defp create_block_for_case(markup, when_tag, else_tag_values) when is_list(when_tag) do
    nodelist = Enum.map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist | else_tag(else_tag_values)] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: nodelist_plus_else}
    to_case_block(block)
  end

  defp create_block_for_case(markup, badbody, when_tag) do
    nodelist_when = Enum.map(when_tag, &when_to_nodelist/1)
    full_list = [badbody | nodelist_when] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: full_list}
    to_case_block(block)
  end

  defp create_block_for_case(markup, badbody, when_tag, else_tag_values) do
    nodelist_when = Enum.map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist_when | else_tag(else_tag_values)]
    full_list = [badbody | nodelist_plus_else] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: full_list}
    to_case_block(block)
  end

  defp create_block_for_case_else(markup, else_tag_values) do
    nodelist = else_tag(else_tag_values)
    block = %Liquid.Block{name: :case, markup: markup, nodelist: nodelist}
    to_case_block(block)
  end

  defp create_block_for_case_else(markup, badbody, else_tag_values) do
    nodelist_plus_else = else_tag(else_tag_values)
    full_list = [badbody | nodelist_plus_else] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: full_list}
    to_case_block(block)
  end

  defp variable_to_markup(part) do
    General.variable_in_parts(part)
    |> General.variable_to_string()
  end

  defp to_case_block(%Liquid.Block{markup: markup} = b) do
    [[_, name]] = Liquid.Case.syntax() |> Regex.scan(markup)
    Liquid.Case.split(name |> Liquid.Variable.create(), b.nodelist)
  end
end
