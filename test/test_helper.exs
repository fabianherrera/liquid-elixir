ExUnit.start(exclude: [:skip])

defmodule Liquid.Helpers do
  use ExUnit.Case
  alias Liquid.{Template, NimbleParser, NimbleTranslator}

  def render(text, data \\ %{}) do
    text |> Template.parse() |> Template.render(data) |> elem(1)
  end

  def test_combinator(markup, combiner, expected) do
    {:ok, response, _, _, _, _} = combiner.(markup)
    assert response == expected
  end

  # cambiado
  def test_combinator_internal_error(markup, combiner) do
    {:error, _, _, _, _, _} = combiner.(markup)
    assert true
  end

  def test_combinator_error(markup, combiner) do
    {:error, _} = combiner.(markup)
    assert true
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
