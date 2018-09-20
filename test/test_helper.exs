ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  use ExUnit.Case
  alias Liquid.{Template, NimbleParser, NimbleTranslator}

  def render(text, data \\ %{}) do
    text |> Template.parse() |> Template.render(data) |> elem(1)
  end

  def test_parse(markup, expected) do
    {:ok, response} = NimbleParser.parse(markup)
    assert response == expected
  end

  def test_combinator(markup, combiner, expected) do
    {:ok, response, _, _, _, _} = combiner.(markup)
    assert response == expected
  end

  def test_combinator_error(markup) do
    {:error, message} = NimbleParser.parse(markup)
    assert message != ""
  end

  def test_ast_translation(markup, params \\ %{}) do
    old = markup |> Template.parse() |> Template.render(params) |> elem(1)

    new =
      markup
      |> NimbleParser.parse()
      |> NimbleTranslator.translate()
      |> Template.render(params)
      |> elem(1)

    assert old == new
  end
end

# TODO: this module must be deleted after finish the work with the new Parser

defmodule Liquid.HelpersFast do
  use ExUnit.Case
  alias Liquid.Parser

  def test_parse(markup, expected) do
    {:ok, response} = Parser.parse(markup)
    assert response == expected
  end

  def test_combinator_error(markup) do
    {:error, message, _rest} = Parser.parse(markup)
    assert message != ""
  end
end
