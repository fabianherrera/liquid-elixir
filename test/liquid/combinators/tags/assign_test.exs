defmodule Liquid.Combinators.Tags.AssignTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "assign" do
    tags = [
      "{% assign cart = 5 %}",
      "{%      assign     cart    =    5    %}",
      "{%assign cart = 5%}",
      "{% assign cart=5 %}",
      "{%assign cart=5%}"
    ]

    Enum.each(tags, fn tag ->
      test_combinator(tag, &Parser.assign/1, assign: [variable_name: ["cart"], value: 5])
    end)

    test_combinator(
      "{% assign cart = old_var %}",
      &Parser.assign/1,
      assign: [
        variable_name: ["cart"],
        value: {:variable, [variable_parts: ["old_var"]]}
      ]
    )

    test_combinator(
      "{% assign cart = 'empty cart' %}",
      &Parser.assign/1,
      assign: [variable_name: ["cart"], value: "empty cart"]
    )

    test_combinator(
      ~s({% assign cart = "empty cart" %}),
      &Parser.assign/1,
      assign: [variable_name: ["cart"], value: "empty cart"]
    )
  end

  test "assign with variable" do
    test_combinator(
      "{% assign cart = 5 %}{{ cart }}",
      &Parser.assign/1,
      assign: [variable_name: ["cart"], value: 5],
      liquid_variable: [variable: [variable_parts: ["cart"]]]
    )
  end

  test "assign a list" do
    test_combinator(
      "{% assign cart = product[0] %}",
      &Parser.assign/1,
      assign: [
        variable_name: ["cart"],
        value: {:variable, [variable_parts: ["product", {:index, 0}]]}
      ]
    )

    test_combinator(
      "{% assign cart = products[0][0] %}",
      &Parser.assign/1,
      assign: [
        variable_name: "cart",
        value: {:variable, ["products", {:index, 0}, {:index, 0}]}
      ]
    )

    test_combinator(
      "{% assign cart = products[  0  ][ 0  ] %}",
      &Parser.assign/1,
      assign: [
        variable_name: "cart",
        value: {:variable, ["products", {:index, 0}, {:index, 0}]}
      ]
    )
  end

  test "assign an object" do
    test_combinator(
      "{% assign cart = company.employees.first.name %}",
      &Parser.assign/1,
      assign: [
        variable_name: ["cart"],
        value: {:variable, [variable_parts: ["company", "employees", "first", "name"]]}
      ]
    )

    test_combinator(
      "{% assign cart = company.managers[1].name %}",
      &Parser.assign/1,
      assign: [
        variable_name: ["cart"],
        value: {:variable, [variable_parts: ["company", "managers", {:index, 1}, "name"]]}
      ]
    )

    test_combinator(
      "{% assign cart = company.managers[1][0].name %}",
      &Parser.assign/1,
      assign: [
        variable_name: "cart",
        value: {:variable, ["company", "managers", {:index, 1}, {:index, 0}, "name"]}
      ]
    )
  end

  test "incorrect variable assignment" do
    test_combinator_error("{% assign cart@ = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign cart. = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign .cart = 5 %}", &Parser.assign/1)
    test_combinator_error("{% assign cart? = 5 %}", &Parser.assign/1)
  end
end
