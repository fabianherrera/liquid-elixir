defmodule Liquid.Translators.Tags.Increment do
  @moduledoc """
  Translate new AST to old AST for the increment tag 
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Increment
  alias Liquid.Tag

  @doc """
  This function takes the markup of the new AST and creates a `Liquid.Tag` struct (the structure needed for the old AST) and fill the keys needed to render a Increment tag.
  """

  @spec translate(Increment.markup()) :: Tag.t()
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :increment, markup: "#{Markup.literal(variable_name)}"}
  end
end
