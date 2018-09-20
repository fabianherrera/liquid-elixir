Liquid.start()

big_literal = File.read!("test/templates/complex/01/big_literal.liquid")
big_literal_with_tags = File.read!("test/templates/complex/01/big_literal_with_tags.liquid")
small_literal = "X"
assign = "Price in stock {% assign a = 5 %} Final Price"
capture = """
Lorem Ipsum is simply dummy text {% capture first_variable %}Hey{% endcapture %}of the printing and typesetting industry. Lorem Ipsum has {% capture first_variable %}Hey{% endcapture %}been the industry's standard dummy text ever since the {% capture first_variable %}Hey{% endcapture %}1500s, when an unknown printer {% capture first_variable %}Hey{% endcapture %}took a galley of type and scrambled it {% capture first_variable %}Hey{% endcapture %}to make a type specimen book. It has survived {% capture first_variable %}Hey{% endcapture %}not only five centuries, but also the leap into electronic typesetting, remaining essentially unchanged{% capture first_variable %}Hey{% endcapture %}. It was popularised in the 1960s with the release of Letraset sheets containing Lorem Ipsum passages, and more recently with desktop publishing software like Aldus PageMaker {% capture first_variable %}Hey{% endcapture %}including versions of Lorem Ipsum.Open{% capture first_variable %}Hey{% endcapture %}{% capture second_variable %}Hello{% endcapture %}{% capture last_variable %}{% endcapture %}CloseOpen{% capture first_variable %}Hey{% endcapture %}{% capture second_variable %}Hello{% endcapture %}{% capture last_variable %}{% endcapture %}Close
"""
small_capture = "{% capture x %}X{% endcapture %}"
case_tag = "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}"
comment = "{% comment %} {% if true %} This is a commented block  {% afi true %}{% endcomment %}"
cycle = "This time {%cycle \"one\", \"two\"%} we win MF!"
decrement = "Total Price: {% decrement a %}"
for_tag = "{% for item in array %}{% else %}{% endfor %}"
if_tag = "{% if false %} this text should not go into the output {% endif %}"
include = "With text {% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %} finally!"
increment = "Price with discount: {% increment a %}"
raw = "{% raw %} {% if true %} this is a raw block {% endraw %}"
tablerow = "{% tablerow item in array %}{% endtablerow %}"

templates = [
  literal: big_literal,
  big_literal_with_tags: big_literal_with_tags,
  small_literal: small_literal,
  assign: assign,
  capture: capture,
  small_capture: small_capture,
  # case: case_tag,
   comment: comment,
  # cycle: cycle,
   decrement: decrement,
  # for: for_tag,
  # if: if_tag,
   include: include,
   increment: increment,
   raw: raw,
  # tablerow: tablerow
]

Enum.each(templates,
  fn {name, template} ->
    IO.puts "running: #{name}"
    Benchee.run(
      %{
        "#{name}-nimble" => fn -> Liquid.NimbleParser.parse(template) end,
        "#{name}-fast-nimble" => fn -> Liquid.Parser.parse(template) end
      },
      warmup: 5,
      time: 30,
    )
  end
)
