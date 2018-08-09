defmodule Liquid.Translators.Tags.Case do
  @moduledoc """
  Translate new AST to old AST for the case tag 
  """
  alias Liquid.Translators.{General, Markup}
  alias Liquid.Combinators.Tags.Case
  alias Liquid.Block

  @doc """
  This function takes the markup of the new AST and creates a `Liquid.Block` struct (the structure needed for the old AST) and fill the keys needed to render a Case tag.
  """

  @spec translate(Case.markup()) :: Block.t()
  def translate([nil]) do
    to_case_block("null", [])
  end

  def translate([nil, {:clauses, clauses}]) do
    create_block_for_case("null", clauses)
  end

  def translate([nil, {:clauses, clauses}, {:else, else_tag_values}]) do
    create_block_for_case("null", clauses, else_tag_values)
  end

  def translate([nil, {:else, else_tag_values}]) do
    create_block_for_case_else("null", else_tag_values)
  end

  def translate([nil, badbody, {:clauses, clauses}]) do
    create_block_for_case("null", badbody, clauses)
  end

  def translate([nil, badbody, {:clauses, clauses}, {:else, else_tag_values}]) do
    create_block_for_case("null", badbody, clauses, else_tag_values)
  end

  def translate([nil, badbody, {:else, else_tag_values}]) do
    create_block_for_case_else("null", badbody, else_tag_values)
  end

  def translate([nil, badbody]) do
    to_case_block("null", [badbody])
  end

  def translate([value]) do
    markup = Markup.literal(value)
    to_case_block(markup, [])
  end

  def translate([value, {:clauses, clauses}]) do
    create_block_for_case(Markup.literal(value), clauses)
  end

  def translate([value, {:clauses, clauses}, {:else, else_tag_values}]) do
    create_block_for_case(Markup.literal(value), clauses, else_tag_values)
  end

  def translate([value, {:else, else_tag_values}]) do
    create_block_for_case_else(Markup.literal(value), else_tag_values)
  end

  def translate([value, badbody, {:clauses, clauses}]) do
    create_block_for_case(Markup.literal(value), badbody, clauses)
  end

  def translate([value, badbody, {:clauses, clauses}, {:else, else_tag_values}]) do
    create_block_for_case(Markup.literal(value), badbody, clauses, else_tag_values)
  end

  def translate([value, badbody, {:else, else_tag_values}]) do
    create_block_for_case_else(Markup.literal(value), badbody, else_tag_values)
  end

  def translate([value, badbody]) do
    markup = Markup.literal(value)
    nodelist = [badbody]
    to_case_block(markup, nodelist)
  end

  defp when_to_nodelist({:when, [conditions: [head | tail], body: values]})
       when is_bitstring(head) do
    tag = %Liquid.Tag{
      name: :when,
      markup: "\"#{Markup.literal(head)}\"" <> Markup.literal(tail)
    }

    result = Liquid.NimbleTranslator.process_node(values)
    [tag, result]
  end

  defp when_to_nodelist({:when, [conditions: conditions, body: values]}) do
    tag = %Liquid.Tag{
      name: :when,
      markup: Enum.join(conditions)
    }

    result = Liquid.NimbleTranslator.process_node(values)
    [tag, result]
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
    nodelist = Enum.flat_map(when_alone, &when_to_nodelist/1)
    to_case_block(markup, nodelist)
  end

  defp create_block_for_case(markup, when_tag, else_tag_values) when is_list(when_tag) do
    nodelist = Enum.flat_map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist | else_tag(else_tag_values)] |> List.flatten()
    to_case_block(markup, nodelist_plus_else)
  end

  defp create_block_for_case(markup, badbody, when_tag) do
    nodelist_when = Enum.flat_map(when_tag, &when_to_nodelist/1)
    full_list = [badbody | nodelist_when] |> List.flatten()
    to_case_block(markup, full_list)
  end

  defp create_block_for_case(markup, badbody, when_tag, else_tag_values) do
    nodelist_when = Enum.flat_map(when_tag, &when_to_nodelist/1)
    nodelist_plus_else = [nodelist_when | else_tag(else_tag_values)]
    full_list = [badbody | nodelist_plus_else] |> List.flatten()
    to_case_block(markup, full_list)
  end

  defp create_block_for_case_else(markup, else_tag_values) do
    nodelist = else_tag(else_tag_values)
    to_case_block(markup, nodelist)
  end

  defp create_block_for_case_else(markup, badbody, else_tag_values) do
    nodelist_plus_else = else_tag(else_tag_values)
    full_list = [badbody | nodelist_plus_else] |> List.flatten()
    to_case_block(markup, full_list)
  end

  defp to_case_block(markup, nodelist) do
    [[_, name]] = Liquid.Case.syntax() |> Regex.scan(markup)
    Liquid.Case.split(name |> Liquid.Variable.create(), nodelist)
  end
end
