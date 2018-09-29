Liquid.start()

complex = File.read!("test/templates/complex/01/input.liquid")

middle = """
  <h1>{{ product.name }}</h1>
  <h2>{{ product.price }}</h2>
  <h2>{{ product.price }}</h2>
  {% comment %}This is a commentary{% endcomment %}
  {% raw %}This is a raw tag{% endraw %}
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

simple = """
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

empty = "{% cycle 1, 2, 3 %}"

templates = [empty: empty]

Enum.each(templates,
  fn {name, template} ->
    IO.puts "running: #{name}"
    Benchee.run(
      %{
        # "#{name}-regex" => fn -> Liquid.Template.old_parse(template) end,
        # "#{name}-parser" => fn -> Liquid.Template.parse(template) end,
        "#{name}-parse" => fn -> Liquid.Parser.parse(template) end,
        "#{name}-parallel" => fn -> Liquid.ParallelParser.parse(template) end
      },
      warmup: 5,
      time: 20
    )
  end
)
