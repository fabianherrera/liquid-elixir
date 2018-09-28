defmodule Liquid.TokenizerTest do
  use ExUnit.Case

  alias Liquid.Tokenizer

  test "empty string" do
    assert Tokenizer.tokenize("") == {"", ""}
    assert Tokenizer.tokenize2("") == []
  end

  test "white string" do
    assert Tokenizer.tokenize("    ") == {"    ", ""}
    assert Tokenizer.tokenize2("    ") == [literal: "    "]
  end

  test "starting tag" do
    assert Tokenizer.tokenize("{% hello %}") == {"", "{% hello %}"}
    assert Tokenizer.tokenize2("{% hello %}") == [liquid: "{% hello %}"]
  end

  test "starting variable" do
    assert Tokenizer.tokenize("{{ hello }}") == {"", "{{ hello }}"}
    assert Tokenizer.tokenize2("{{ hello }}") == [liquid: "{{ hello }}"]
  end

  test "tag starting with literal" do
    assert Tokenizer.tokenize("world {% hello %}") == {"world ", "{% hello %}"}
    assert Tokenizer.tokenize2("world {% hello %}") == [literal: "world ", liquid: "{% hello %}"]
  end

  test "variable starting with literal" do
    assert Tokenizer.tokenize("world {{ hello }}") == {"world ", "{{ hello }}"}
    assert Tokenizer.tokenize2("world {{ hello }}") == [literal: "world ", liquid: "{{ hello }}"]
  end

  test "literal inside block" do
    assert Tokenizer.tokenize("{% hello %} Hello {% endhello %}") ==
             {"", "{% hello %} Hello {% endhello %}"}

    assert Tokenizer.tokenize2("{% hello %} Hello {% endhello %}") ==
             [liquid: "{% hello %}", literal: " Hello ", liquid: "{% endhello %}"]
  end

  test "liquid inside literal" do
    assert Tokenizer.tokenize("{% hello %} Hello {% endhello %}") ==
    {"", "{% hello %} Hello {% endhello %}"}

    assert Tokenizer.tokenize2("Hello {% hello %} Hello") ==
      [literal: "Hello ", liquid: "{% hello %}",  literal: " Hello"]
  end
end
