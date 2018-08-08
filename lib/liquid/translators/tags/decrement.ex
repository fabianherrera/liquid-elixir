defmodule Liquid.Translators.Tags.Decrement do
  alias Liquid.Translators.Markup

  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: Markup.literal(variable_name)}
  end
end
