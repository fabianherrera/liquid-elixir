Liquid.start()

big_literal = File.read!("test/templates/complex/01/big_literal.liquid")
little_literal = "X"
assign = "Price in stock {% assign a = 5 %} Final Price"
capture = "{% capture about_me %} I am {{ age }} and my favorite food is {{ favorite_food }}{% endcapture %}"
case_tag = "{% case condition %}{% when 1 %} its 1 {% when 2 %} its 2 {% endcase %}"
comment = "{% comment %} {% if true %} sadsadasd  {% afi true %}{% endcomment %}"
cycle = "{%cycle \"one\", \"two\"%}"
decrement = "Total Price: {% decrement a %}"
for_tag = "{% for item in array %}{% else %}{% endfor %}"
if_tag = "{% if false %} this text should not go into the output {% endif %}"
include = "{% include 'snippet', my_variable: 'apples', my_other_variable: 'oranges' %}"
increment = "Price with discount: {% increment a %}"
raw = "{% raw %} {% if true %} {% endraw %}"
tablerow = "{% tablerow item in array %}{% endtablerow %}"

templates = [
  literal: big_literal,
  little_literal: little_literal,
  assign: assign,
  # capture: capture,
  # case: case_tag,
  # comment: comment,
  # cycle: cycle,
  decrement: decrement,
  # for: for_tag,
  # if: if_tag,
  # include: include,
  increment: increment,
  # raw: raw,
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
      warmup: 2,
      time: 10,
    )
  end
)
