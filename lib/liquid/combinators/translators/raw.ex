defmodule Liquid.Combinators.Translators.Raw do
  def translate([markup]) do
    %Liquid.Block{name: :raw, nodelist: "#{markup}"}
  end
end
