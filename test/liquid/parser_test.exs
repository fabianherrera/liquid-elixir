defmodule Liquid.ParserTest do
  use ExUnit.Case

  import Liquid.HelpersFast

  test "only literal" do
    test_parse("Hello", ["Hello"])
  end

  test "liquid variable" do
    test_parse("{{ X }}", liquid_variable: [variable: [parts: [part: "X"]]])
  end

  test "test liquid open tag" do
    test_parse("{% assign a = 5 %}", assign: [variable_name: "a", value: 5])
  end

  test "test literal + liquid open tag" do
    test_parse(
      "Hello {% assign a = 5 %}",
      ["Hello ", {:assign, [variable_name: "a", value: 5]}]
    )
  end

  test "test liquid open tag + literal" do
    test_parse(
      "{% assign a = 5 %} Hello",
      [{:assign, [variable_name: "a", value: 5]}, " Hello"]
    )
  end

  test "test literal + liquid open tag + literal" do
    test_parse(
      "Hello {% assign a = 5 %} Hello",
      ["Hello ", {:assign, [variable_name: "a", value: 5]}, " Hello"]
    )
  end

  test "test multiple open tags" do
    test_parse(
      "{% assign a = 5 %}{% increment a %}",
      [{:assign, [variable_name: "a", value: 5]}, {:increment, [variable: [parts: [part: "a"]]]}]
    )
  end

  test "unclosed block must fails" do
    test_combinator_error("{% capture variable %}",
      "Malformed tag, open without close: 'capture'"
    )
  end

  test "empty closed tag" do
    test_parse(
      "{% capture variable %}{% endcapture %}",
      [{:capture, [variable_name: "variable", body: []]}]
    )
  end

  test "tag without open" do
    test_combinator_error("{% if true %}{% endiif %}",
      "The 'if' tag has not been correctly closed")
  end

  test "literal left, right and inside block" do
    test_parse(
      "Hello{% capture variable %}World{% endcapture %}Here",
      ["Hello", {:capture, [variable_name: "variable", body: ["World"]]}, "Here"]
    )
  end

  test "multiple closed tags" do
    test_parse(
      "Open{% capture first_variable %}Hey{% endcapture %}{% capture second_variable %}Hello{% endcapture %}{% capture last_variable %}{% endcapture %}Close",
      [
        "Open",
        {:capture, [variable_name: "first_variable", body: ["Hey"]]},
        {:capture, [variable_name: "second_variable", body: ["Hello"]]},
        {:capture, [variable_name: "last_variable", body: []]},
        "Close"
      ]
    )
  end

  test "tag inside block" do
    test_parse(
      "{% capture x %}{% decrement x %}{% endcapture %}",
      [{:capture, [variable_name: "x", body: [{:decrement, [variable: [parts: [part: "x"]]]}]]}]
    )
  end

  test "literal and tag inside block" do
    test_parse(
      "{% capture x %}X{% decrement x %}{% endcapture %}",
      [
        {:capture,
         [variable_name: "x", body: ["X", {:decrement, [variable: [parts: [part: "x"]]]}]]}
      ]
    )
  end

  test "two tags inside block" do
    test_parse(
      "{% capture x %}{% decrement x %}{% decrement x %}{% endcapture %}",
      [
        {:capture,
         [
           variable_name: "x",
           body: [
             {:decrement, [variable: [parts: [part: "x"]]]},
             {:decrement, [variable: [parts: [part: "x"]]]}
           ]
         ]}
      ]
    )
  end

  test "tag inside block with tag ending" do
    test_parse(
      "{% capture x %}{% increment x %}{% endcapture %}{% decrement y %}",
      capture: [variable_name: "x", body: [increment: [variable: [parts: [part: "x"]]]]],
      decrement: [variable: [parts: [part: "y"]]]
    )
  end

  test "nested closed tags" do
    test_parse(
      "{% capture variable %}{% capture internal_variable %}{% endcapture %}{% endcapture %}",
      capture: [
        variable_name: "variable",
        body: [capture: [variable_name: "internal_variable", body: []]]
      ]
    )
  end

  test "block without endblock" do
    test_combinator_error("{% capture variable %}{% capture internal_variable %}{% endcapture %}")
  end

  test "block closed without open" do
    test_combinator_error(
      "{% endcapture %}",
      "The tag 'capture' was not opened"
    )
  end

  test "bad endblock" do
    test_combinator_error(
      "{% capture variable %}{% capture internal_variable %}{% endif %}{% endcapture %}"
    )
  end

  test "if block" do
    test_parse(
      "{% if a == b or c == d %}Hello{% endif %}",
      if: [
        conditions: [
          {:condition,
           {{:variable, [parts: [part: "a"]]}, :==, {:variable, [parts: [part: "b"]]}}},
          logical: [
            :or,
            {:condition,
             {{:variable, [parts: [part: "c"]]}, :==, {:variable, [parts: [part: "d"]]}}}
          ]
        ],
        body: ["Hello"]
      ]
    )
  end

  test "tablerow block" do
    test_parse(
      "{% tablerow item in array limit:2 %}{% endtablerow %}",
      tablerow: [
        statements: [
          variable: [parts: [part: "item"]],
          value: {:variable, [parts: [part: "array"]]},
          params: [limit: [2]]
        ],
        body: []
      ]
    )
  end

  test "unexpected outer else tag" do
    test_combinator_error(
      "{% else %}",
      "Unexpected outer 'else' tag"
    )
  end

  test "else out of valid tag" do
    test_combinator_error(
      "{% capture z %}{% else %}{% endcapture %}",
      "capture does not expect else tag. The else tag is valid only inside: if, when, elsif, for"
    )
  end
end
