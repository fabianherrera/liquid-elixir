defmodule Liquid.Combinators.Translators.Include do
  alias Liquid.{Tag, Include}

  def translate([snippet]), do: parse("'#{snippet}'")

  def translate([snippet, rest]), do: parse("'#{snippet}' #{rest}")

  defp parse(markup) do
    Include.parse(%Tag{markup: markup, name: :include})
  end
end
