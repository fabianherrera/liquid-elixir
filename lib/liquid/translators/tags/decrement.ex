defmodule Liquid.Translators.Tags.Decrement do
  @moduledoc """
  Translate new AST to old AST for the decrement tag 
  """

  alias Liquid.Translators.Markup
  alias Liquid.Combinators.Tags.Decrement
  alias Liquid.Tag

  @spec translate(Decrement.markup()) :: Tag.t()

  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: Markup.literal(variable_name)}
  end
end
