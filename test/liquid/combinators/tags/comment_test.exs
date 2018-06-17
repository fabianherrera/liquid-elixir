defmodule Liquid.Combinators.Tags.CommentTest do
  use ExUnit.Case

  import Liquid.Helpers
  alias Liquid.NimbleParser, as: Parser

  test "comment tag parser" do
    test_combinator(
      "{% comment %} Allows you to leave un-rendered code inside a Liquid template. Any text within the opening and closing comment blocks will not be output, and any Liquid code within will not be executed. {% endcomment %}",
      &Parser.comment/1,
      comment: [
        " Allows you to leave un-rendered code inside a Liquid template. Any text within the opening and closing comment blocks will not be output, and any Liquid code within will not be executed. "
      ]
    )
  end

  test "comment with tags and variables in body" do
    test_combinator(
      "{% comment %} {% if true %} {% endcomment %}",
      &Parser.comment/1,
      [comment: [" ", "{%", " if true %} "]]
    )
  end

  test "comment with any tags in body" do
    test_combinator(
      "{% comment %} {% if true %} sadsadasd  {% afi true %}{% endcomment %}",
      &Parser.comment/1,
      [
        comment: [" ", "{%", " if true %} sadsadasd  ", "{%",
          " afi true %}"]
      ]
    )
  end

  test "comment with any tags  and comments or raw in body" do
    test_combinator(
      "{% comment %} {% if true %} {% comment %} {% if true %} {% endcomment %} {% endcomment %}",
      &Parser.comment/1,
      [
        comment: [
          " ",
          "{%",
          " if true %} ",
          {:comment, [" ", "{%", " if true %} "]},
          " "
        ]
      ]
    )
  end

end
