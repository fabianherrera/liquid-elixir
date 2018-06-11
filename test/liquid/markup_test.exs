defmodule Liquid.Markup do
  use ExUnit.Case
  import Liquid.Helpers

  test "implement to_string {:part}" do
    assert to_string({:part, 5}) == "5"
    assert to_string({:part, true}) == "true"
    assert to_string({:part, "house"}) == "house"
  end

  test "implement to_string {:index }" do
    assert to_string({:index, 5}) == "[5]"
    assert to_string({:index, true}) == "[true]"
    assert to_string({:index, "house"}) == "[\"house\"]"
  end

  test "implement to_string {:parts}" do
    assert to_string(
             {:parts, [{:part, "company"}, {:part, "name"}, {:part, "employee"}, {:index, 0}]}
           ) == "company.name.employee[0]"

    assert to_string(
             {:parts,
              [
                {:part, "company"},
                {:part, "name"},
                {:part, "employee"},
                {:index, {:variable, [parts: [part: "store", part: "state", index: 1]]}}
              ]}
           ) == "company.name.employee[store.state[1]]"
  end

  test "implement to_string {:variable}" do
    assert to_string({:variable, [parts: [part: "store", part: "state", index: 1]]}) ==
             "store.state[1]"

    assert to_string(
             {:variable, [parts: [part: "store", part: "state", index: 0, index: 0, index: 1]]}
           ) == "store.state[0][0][1]"

    assert to_string({:variable, [parts: [part: "var", index: "a:b c", index: "paged"]]}) ==
             "var[\"a:b c\"][\"paged\"]"
  end

  test "implement to_string {:or}" do
    assert to_string({:logical, [:or, {:variable, [parts: [part: "b"]]}]}) == " or b "
  end

  test "implement to_string {:condition}" do
    assert to_string({:condition, {true, :==, nil}}) == "true == null"
  end

  test "implement to_string {:control_flow}" do
    assert to_string(
             {:control_flow,
              [
                variable: [parts: [part: "a"]],
                logical: [:or, {:variable, [parts: [part: "b"]]}]
              ]}
           ) == "a or b "
  end
end
