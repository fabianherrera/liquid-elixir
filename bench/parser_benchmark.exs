Liquid.start()

complex = File.read!("bench/templates/complex.liquid")

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

empty = ""

templates = [complex: complex]

Enum.each(templates,
  fn {name, template} ->
    Benchee.run(
      %{
        "#{name}" => fn -> Liquid.Parser.parse(template) end
      },
      warmup: 5,
      time: 60
    )
  end
)
