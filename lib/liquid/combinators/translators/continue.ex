defmodule Liquid.Combinators.Translators.Continue do
  def translate(_markup) do
    %Liquid.Tag{name: :continue}
  end
end