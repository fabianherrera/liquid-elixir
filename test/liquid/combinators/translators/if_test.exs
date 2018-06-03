defmodule Liquid.Combinators.Translators.IfTest do
  use ExUnit.Case
  import Liquid.Helpers

  test "if translate new AST to old AST" do
    params = %{"array" => [1, 1, 2, 2, 3, 3], "repeat_array" => [1, 1, 1, 1]}
    [
      "{% if true == empty %}?{% endif %}",
      "{% if true == null %}?{% endif %}",
      "{% if empty == true %}?{% endif %}",
      "{% if null == true %}?{% endif %}"
    ]
    |> Enum.each(fn tag ->
      test_ast_translation(tag, params)
    end)
  end
end
