Liquid.start()

complex_template = File.read!("test/templates/complex/01/input.liquid")

middle_template = """
  {% decrement product.price %}
  <h1>{{ product.name }}</h1>
  <h2>{{ product.price }}</h2>
  {% increment product.price %}
  <h2>{{ product.price }}</h2>
  {% comment %}This is a commentary{% endcomment %}
  {% raw %}This is a raw tag{% endraw %}
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

simple_template = """
  {% for item in array %} Repeat this {% else %} Array Empty {% endfor %}
"""

empty_template = ""

template = middle_template

time = DateTime.to_string(DateTime.utc_now())

Benchee.run(
  %{
    nimble: fn -> Liquid.NimleParser.parse(template) end,
    nimble_with_translator: fn -> Liquid.Template.parse(template) end,
    regex: fn -> Liquid.Parse.parse(template, %Liquid.Template{}) end
  },
  warmup: 5,
  time: 60,
  formatters: [
    Benchee.Formatters.Console,
    Benchee.Formatters.CSV
  ],
  formatter_options: [csv: [file: "bench/results/parser-benchmarks-#{time}.csv"]]
)
