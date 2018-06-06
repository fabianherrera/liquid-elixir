defmodule Liquid.Combinators.Translators.Raw do
  def translate([markup]) do
    %Liquid.Block{name: :raw, strict: false, nodelist: ["#{markup}"]}
  end
end
