defmodule Liquid.Translators.Tags.Raw do
  alias Liquid.Translators.Markup

  def translate([markup]) do
    %Liquid.Block{name: :raw, strict: false, nodelist: ["#{Markup.literal(markup)}"]}
  end
end
