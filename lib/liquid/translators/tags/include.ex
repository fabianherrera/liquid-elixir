defmodule Liquid.Translators.Tags.Include do
  @moduledoc """
  Translate new AST to old AST for the include tag 
  """

  alias Liquid.{Tag, Include}
  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Include, as: IncludeCombinator

  @spec translate(IncludeCombinator.markup()) :: Tag.t()

  def translate([snippet]), do: parse("'#{Markup.literal(snippet)}'")

  def translate([snippet, rest]),
    do: parse("'#{Markup.literal(snippet)}' #{Markup.literal(rest)}")

  defp parse(markup) do
    Include.parse(%Tag{markup: markup, name: :include})
  end
end
