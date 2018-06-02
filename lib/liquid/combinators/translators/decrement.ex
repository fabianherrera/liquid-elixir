defmodule Liquid.Combinators.Translators.Decrement do
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :decrement, markup: "#{variable_name}"}
  end
end
