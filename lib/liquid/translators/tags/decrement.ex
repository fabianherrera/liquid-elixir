defmodule Liquid.Translators.Tags.Decrement do
  @moduledoc """
  Translate new AST to old AST for the decrement tag 
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Decrement
  alias Liquid.Tag

  @doc """
  This function takes the markup of the new AST and creates a `Liquid.Tag` struct (the structure needed for the old AST) and fill the keys needed to render a Decrement tag.
  """

  @spec translate(Decrement.markup()) :: Tag.t()
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: Markup.literal(variable_name)}
  end
end
