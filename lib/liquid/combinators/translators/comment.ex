defmodule Liquid.Combinators.Translators.Comment do
  def translate(_markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false}
  end
end
