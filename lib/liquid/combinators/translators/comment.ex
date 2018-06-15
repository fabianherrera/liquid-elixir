defmodule Liquid.Combinators.Translators.Comment do
  def translate(markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false, nodelist: [""]}
  end
end
