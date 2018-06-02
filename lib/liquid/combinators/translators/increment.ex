defmodule Liquid.Combinators.Translators.Increment do
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :increment, markup: "#{variable_name}"}
  end
end
