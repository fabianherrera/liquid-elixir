defmodule Liquid.Translators.Tags.Case do
  alias Liquid.Translators.{General, Markup}

  def translate([nil]) do
    block = %Liquid.Block{name: :case, markup: "null"}
    to_case_block(block)
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
    block = %Liquid.Block{name: :case, markup: "null", nodelist: [badbody]}
    to_case_block(block)
  end

  def translate([value]) do
    block = %Liquid.Block{name: :case, markup: Markup.literal(value)}
    to_case_block(block)
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
    block = %Liquid.Block{name: :case, markup: Markup.literal(value), nodelist: [badbody]}
    to_case_block(block)
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
    nodelist = Enum.map(when_alone, &when_to_nodelist/1) |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: nodelist}
    to_case_block(block)
  end

  defp create_block_for_case(markup, when_tag, else_tag_values) when is_list(when_tag) do
    nodelist = Enum.map(when_tag, &when_to_nodelist/1) |> List.flatten()
    nodelist_plus_else = [nodelist | else_tag(else_tag_values)] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: nodelist_plus_else}
    to_case_block(block)
  end

  defp create_block_for_case(markup, badbody, when_tag) do
    nodelist_when = Enum.map(when_tag, &when_to_nodelist/1) |> List.flatten()
    full_list = [badbody | nodelist_when] |> List.flatten()
    block = %Liquid.Block{name: :case, markup: markup, nodelist: full_list}
    to_case_block(block)
  end

  defp create_block_for_case(markup, badbody, when_tag, else_tag_values) do
    nodelist_when = Enum.map(when_tag, &when_to_nodelist/1) |> List.flatten()
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
