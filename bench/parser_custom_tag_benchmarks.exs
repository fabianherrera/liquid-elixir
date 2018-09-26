defmodule MinusOneTag do
  def parse(%Liquid.Tag{} = tag, %Liquid.Template{} = context) do
    {tag, context}
  end

  def render(output, tag, context) do
    number = tag.markup |> Integer.parse() |> elem(0)
    {["#{number - 1}"] ++ output, context}
  end
end

defmodule MundoTag do
  def parse(%Liquid.Tag{} = tag, %Liquid.Template{} = context) do
    {tag, context}
  end

  def render(output, tag, context) do
    number = tag.markup |> Integer.parse() |> elem(0)
    {["#{number - 1}"] ++ output, context}
  end
end

Liquid.Registers.register("minus_one", MinusOneTag, Liquid.Tag)
Liquid.Registers.register("Mundo", MundoTag, Liquid.Block)
Liquid.start()

custom_block = "{% Mundo 5 %}my body{% endMundo %}"
custom_tag = "{% minus_one  5 %}"

templates = [
  custom_block: custom_block,
  custom_tag: custom_tag
]

custom_tag |> Liquid.Parser.parse() |> inspect() |> IO.puts()
custom_block |> Liquid.Parser.parse() |> inspect() |> IO.puts()
custom_tag |> Liquid.NimbleParser.parse() |> inspect() |> IO.puts()
custom_block |> Liquid.NimbleParser.parse() |> inspect() |> IO.puts()

Enum.each(templates,
  fn {name, template} ->
    IO.puts "running: #{name}"
    Benchee.run(
      %{
        "#{name}-nimble" => fn -> Liquid.NimbleParser.parse(template) end,
        "#{name}-fast-nimble" => fn -> Liquid.Parser.parse(template) end
      },
      warmup: 5,
      time: 30
    )
  end
)
