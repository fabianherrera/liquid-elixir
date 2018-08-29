defmodule Liquid.Combinators.Tags.CaptureTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "capture tag: parser basic structures" do
    test_parse(
      "{% capture about_me %} I am {{ age }} and my favorite food is {{ favorite_food }}{% endcapture %}",
      capture: [
        variable_name: "about_me",
        parts: [
          " I am ",
          {:liquid_variable, [variable: [parts: [part: "age"]]]},
          " and my favorite food is ",
          {:liquid_variable, [variable: [parts: [part: "favorite_food"]]]}
        ]
      ]
    )
  end

  test "fails in capture tag" do
    [
      "{% capture about_me %} I am {{ age } and my favorite food is { favorite_food }} {% endcapture %}",
      "{% capture about_me %}{% ndcapture %}"
    ]
    |> Enum.each(fn bad_markup -> test_combinator_error(bad_markup, &Parser.parse/1) end)
  end
end
