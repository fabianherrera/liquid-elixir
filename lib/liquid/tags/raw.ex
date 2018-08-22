defmodule Liquid.Raw do
  alias Liquid.{Block, Render, Template, Context}

  def full_token_possibly_invalid,
    do: ~r/\A(.*)#{Liquid.tag_start()}\s*(\w+)\s*(.*)?#{Liquid.tag_end()}\z/m

  def parse(%Block{name: name} = block, [h | t], accum, %Template{} = template) do
    if Regex.match?(Liquid.Raw.full_token_possibly_invalid(), h) do
      block_delimiter = "end" <> to_string(name)

      regex_result =
        Regex.scan(Liquid.Raw.full_token_possibly_invalid(), h, capture: :all_but_first)

      [extra_data, endblock | _] = List.flatten(regex_result)

      if block_delimiter == endblock do
        extra_accum = accum ++ [extra_data]
        block = %{block | strict: false, nodelist: Enum.filter(extra_accum, &(&1 != ""))}
        {block, t, template}
      else
        if length(t) > 0 do
          parse(block, t, accum ++ [h], template)
        else
          raise "No matching end for block {% #{to_string(name)} %}"
        end
      end
    else
      parse(block, t, accum ++ [h], template)
    end
  end

  def parse(%Block{} = block, %Template{} = t) do
    {block, t}
  end

  @doc """
  Implementation of 'Raw' render operations.
  """
  @spec render(list(), %Block{}, %Context{}) :: {list(), %Context{}}
  def render(output, %Block{} = block, context) do
    Render.render(output, block.nodelist, context)
  end
end
