defmodule Liquid.Translators.MarkupTest do
  use ExUnit.Case

  alias Liquid.Translators.Markup

  test "create the markup with the Markup.literal functions for  {:parts}" do
    assert Markup.literal(
             {:parts, [{:part, "company"}, {:part, "name"}, {:part, "employee"}, {:index, 0}]}
           ) == "company.name.employee[0]"

    assert Markup.literal(
             {:parts,
              [
                {:part, "company"},
                {:part, "name"},
                {:part, "employee"},
                {:index, {:variable, [parts: [part: "store", part: "state", index: 1]]}}
              ]}
           ) == "company.name.employee[store.state[1]]"
  end

  test "create the markup with the Markup.literal functions for {:variable}" do
    assert Markup.literal({:variable, [parts: [part: "store", part: "state", index: 1]]}) ==
             "store.state[1]"

    assert Markup.literal(
             {:variable, [parts: [part: "store", part: "state", index: 0, index: 0, index: 1]]}
           ) == "store.state[0][0][1]"

    assert Markup.literal({:variable, [parts: [part: "var", index: "a:b c", index: "paged"]]}) ==
             "var[\"a:b c\"][\"paged\"]"
  end

  test "create the markup with the Markup.literal functions for {:logical}" do
    assert Markup.literal({:logical, [:or, {:variable, [parts: [part: "b"]]}]}) == " or b"
  end

  test "create the markup with the Markup.literal functions for {:condition}" do
    assert Markup.literal({:condition, {true, :==, nil}}) == "true == null"
  end

  test "create the markup with the Markup.literal functions for  {:conditions} and {:logical}" do
    assert Markup.literal(
             {:conditions,
              [
                variable: [parts: [part: "a"]],
                logical: [:or, {:variable, [parts: [part: "b"]]}]
              ]}
           ) == "a or b"
  end
end
