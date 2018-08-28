defmodule Liquid.Combinators.Tags.CycleTest do
  use ExUnit.Case
  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "cycle tag with 2 values" do
    test_combinator(
      "{%cycle \"one\", \"two\"%}",
      &Parser.__parse__/1,
      cycle: [values: ["one", "two"]]
    )
  end

  test "cycle tag 2 times" do
    test_combinator(
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      &Parser.__parse__/1,
      [
        {:cycle, [values: ["one", "two"]]},
        " ",
        {:cycle, [values: ["one", "two"]]}
      ]
    )
  end

  test "cycle tag with quoted blanks" do
    test_combinator("{%cycle \"\", \"two\"%} {%cycle \"\", \"two\"%}", &Parser.__parse__/1, [
      {:cycle, [values: ["", "two"]]},
      " ",
      {:cycle, [values: ["", "two"]]}
    ])
  end

  test "cycle tag 3 times" do
    test_combinator(
      "{%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%} {%cycle \"one\", \"two\"%}",
      &Parser.__parse__/1,
      [
        {:cycle, [values: ["one", "two"]]},
        " ",
        {:cycle, [values: ["one", "two"]]},
        " ",
        {:cycle, [values: ["one", "two"]]}
      ]
    )
  end

  test "cycle with html values" do
    test_combinator(
      "{%cycle \"text-align: left\", \"text-align: right\" %} {%cycle \"text-align: left\", \"text-align: right\"%}",
      &Parser.__parse__/1,
      [
        {:cycle, [values: ["text-align: left", "text-align: right"]]},
        " ",
        {:cycle, [values: ["text-align: left", "text-align: right"]]}
      ]
    )
  end

  test "cycle tag with integers" do
    test_combinator(
      "{%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%} {%cycle 1,2,3%}",
      &Parser.__parse__/1,
      [
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]},
        " ",
        {:cycle, [values: [1, 2, 3]]}
      ]
    )
  end

  test "cycle tag group by numbers" do
    test_combinator(
      "{%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %} {%cycle 1: \"one\", \"two\" %} {%cycle 2: \"one\", \"two\" %}",
      &Parser.__parse__/1,
      [
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["2"], values: ["one", "two"]]}
      ]
    )
  end

  test "cycle tag group by strings" do
    test_combinator(
      "{%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %} {%cycle var1: \"one\", \"two\" %} {%cycle var2: \"one\", \"two\" %}",
      &Parser.__parse__/1,
      [
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var1"], values: ["one", "two"]]},
        " ",
        {:cycle, [group: ["var2"], values: ["one", "two"]]}
      ]
    )
  end
end
