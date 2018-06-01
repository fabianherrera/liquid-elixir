defmodule Liquid.Combinators.Tags.RawTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "raw tag parser" do
    test_combinator(
      "{% raw %} Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax.{% endraw %}",
      &Parser.raw/1,
      raw: [
        " Raw temporarily disables tag processing. This is useful for generating content (eg, Mustache, Handlebars )like this {{ product }} which uses conflicting syntax."
      ]
    )
  end

  test "raw with tags and variables in body" do
    test_combinator(
      "{% raw %} {% if true %} {% endraw %}",
      &Parser.raw/1,
      raw: [" {% if true %} "]
    )
  end
end
