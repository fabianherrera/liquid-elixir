defmodule Liquid.Combinators.Translators.Case do
  alias Liquid.Combinators.Translators.General

  def translate([value]) do
    block = %Liquid.Block{name: :case, markup: "#{value}"}
    to_case_block(block)
  end

  def translate([value, {:whens, whens}]) do
    create_block_for_case("#{value}", whens)
  end

  def translate([value, {:whens, whens}, {:else, else_tag_values}]) do
    create_block_for_case("#{value}", whens, else_tag_values)
  end

  def translate([value, {:else, else_tag_values}]) do
    create_block_for_case_else("#{value}", else_tag_values)
  end

  def translate([value, badbody, {:whens, whens}]) do
    create_block_for_case("#{value}", badbody, whens)
  end

  def translate([value, badbody, {:whens, whens}, {:else, else_tag_values}]) do
    create_block_for_case("#{value}", badbody, whens, else_tag_values)
  end

  def translate([value, badbody, {:else, else_tag_values}]) do
    create_block_for_case_else("#{value}", badbody, else_tag_values)
  end

  def translate([value, badbody]) do
    block = %Liquid.Block{name: :case, markup: "#{value}", nodelist: [badbody]}
    to_case_block(block)
  end

  defp when_to_nodelist({:when, [head | tail]}) when is_bitstring(head) do
    %Liquid.Tag{
      name: :when,
      markup: "\"#{head}\""
    }
  end

  defp when_to_nodelist({:when, value}) do
    %Liquid.Tag{
      name: :when,
      markup: Enum.join(value)
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

  defp to_case_block(%Liquid.Block{markup: markup} = b) do
    [[_, name]] = Liquid.Case.syntax() |> Regex.scan(markup)
    Liquid.Case.split(name |> Liquid.Variable.create(), b.nodelist)
  end
end
