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
      comment: [" {% if true %} "]
    )
  end

  test "comment with any tags in body" do
    test_combinator(
      "{% comment %} {% if true %} sadsadasd  {% afi true %}{% endcomment %}",
      &Parser.comment/1,
      comment: [" {% if true %} sadsadasd  {% afi true %}"]
    )
  end

  test "comment with any tags and comments or raw in body" do
    test_combinator(
      "{% comment %} {% if true %} {% comment %} {% if true %} {% endcomment %} {% endcomment %}",
      &Parser.comment/1,
      comment: [" {% if true %}  {% if true %}  "]
    )
  end

  test "comment with any tags and nested comment" do
    test_combinator(
      "{% comment %} {% comment %} {% if true %} {% comment %} {% if true %} {% endcomment %} {% endcomment %} {% endcomment %}",
      &Parser.comment/1,
      comment: ["  {% if true %}  {% if true %}   "]
    )

    test_combinator(
      "{% comment %} {% comment %} {% comment %}   {% comment %}  {% comment %} {% comment %} {% endcomment %} {% endcomment %}  {% endcomment %}{% endcomment %} {% endcomment %} {% endcomment %}",
      &Parser.comment/1,
      comment: ["              "]
    )

    test_combinator(
      "{% comment %} a {% comment %} b {% endcomment %} {% comment %} c{% endcomment %} {% comment %} d {% endcomment %}{% endcomment %}",
      &Parser.comment/1,
      comment: [" a  b   c  d "]
    )

    test_combinator(
      "{% comment %} a {% comment %} b {% endcomment %} {% comment %} c{% endcomment %} {% comment %} d {% endcomment %}{% endcomment %}",
      &Parser.comment/1,
      comment: [" a  b   c  d "]
    )

    test_combinator(
      "{% comment %} hi {% endcomment %}{% comment %} there {% endcomment %}",
      &Parser.comment/1,
      comment: [" hi "],
      comment: [" there "]
    )
  end

  test "comment with any tag that are similar to comment and endcomment" do
    test_combinator(
      "{% comment %} {% if true %} {% andcomment %} {% aendcomment %} {% acomment %} {% endcomment %}",
      &Parser.comment/1,
      comment: [" {% if true %} {% andcomment %} {% aendcomment %} {% acomment %} "]
    )

    test_combinator(
      "{% comment %} {% commenta %} {% endcomment %}",
      &Parser.comment/1,
      comment: [" {% commenta %} "]
    )
  end

  test "comment with several raw" do
    test_combinator(
      "{% comment %} {% raw %} {% comment %} {% endraw %} {% raw %} {% endcomment %}{% endraw %} {% raw %} hi there .. {% endraw %}{% endcomment %}",
      &Parser.comment/1,
      comment: ["  {% comment %}   {% endcomment %}  hi there .. "]
    )

    test_combinator(
      "{% comment %} {% raw %} {% comment %} {% endraw %} {% comment %} hi {% endcomment %} {% raw %} i am raw text .. {% endraw %} {% comment %} i am  a comment {% endcomment %}{% endcomment %}",
      &Parser.comment/1,
      comment: ["  {% comment %}   hi   i am raw text ..   i am  a comment "]
    )

    test_combinator(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endcomment %}",
      &Parser.comment/1,
      comment: ["any {% if true %}"]
    )

    test_combinator(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endif %}{% for item in products %}{% endfor %}{% endcomment %}",
      &Parser.comment/1,
      comment: ["any truefor itemproducts"]
    )

    test_combinator(
      "{% comment %}{% raw %}any {% endraw %}{% if true %}{% endif %}{% for item in products %}{%%}{% endcomment %}",
      &Parser.comment/1,
      comment: ["any true{% for item in products %}{%%}"]
    )
  end

  test "comment start and end tags" do
    test_combinator(
      "{%            comment      \n\n\n %}%}{%   \n\n\n     endcomment \n\n\n %}",
      &Parser.comment/1,
      comment: ["%}"]
    )

    test_combinator(
      "{% comment %}{%%}{%%}{%%}{%%}{%%}{% endcomment %}",
      &Parser.comment/1,
      comment: ["{%%}{%%}{%%}{%%}{%%}"]
    )
  end

  test "comment must fails with this one" do
    {result, _, _, _, _, _} =
      Parser.comment(
        "{% comment %} {% if true %} {% comment %} {% aendcomment %} {% acomment %} {% endcomment %}"
      )

    assert result == :error

    {result, _, _, _, _, _} = Parser.comment("{% comment %}{%}{% endcomment %}")
    assert result == :error

    {result, _} = Parser.parse("{% comment %} {% comment %} {% endcomment %}")
    assert result == :error

    {result, _} = Parser.parse("{%comment%}{%comment%}{%endcomment%}")
    assert result == :error

    {result, _} = Parser.parse("{% comment %} {% endcomment %} {% endcomment %}")
    assert result == :error
  end
end
