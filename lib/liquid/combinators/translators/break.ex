defmodule Liquid.Combinators.Translators.Break do
  def translate(_markup) do
    %Liquid.Tag{name: :break}
  end
end
