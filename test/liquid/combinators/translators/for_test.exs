defmodule Liquid.Combinators.Translators.ForTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "for translate new AST to old AST" do
    params = %{"array" => [1, 1, 2, 2, 3, 3], "repeat_array" => [1, 1, 1, 1]}
    [
      "{%for item in array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      "{%for i in (1..2) %}{% assign a = \"variable\"%}{% endfor %}{{a}}",
      "{%for item in repeat_array%}{%ifchanged%}{{item}}{% endifchanged %}{%endfor%}",
      "{%for item in (1..3)%}{%ifchanged%}{{item}}{%for item in (4..6)%}{{item}}{%endfor%}{% endifchanged %}{%endfor%}",
      "0{% for i in (1..3) %} {{ i }}{% endfor %}",
#      "0{%\nfor i in (1..3)\n%} {{\ni\n}}{%\nendfor\n%}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag, params)
    end)
  end
end
