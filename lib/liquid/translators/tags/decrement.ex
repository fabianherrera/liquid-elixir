defmodule Liquid.Translators.Tags.Decrement do
  alias Liquid.Translators.Markup

  @moduledoc """
  Translate new AST to old AST for the decrement tag 
  """

  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: Markup.literal(variable_name)}
  end
end
