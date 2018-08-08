defmodule Liquid.Translators.Tags.Assign do
  def translate([h | t]) do
    markup = [h | ["=" | t]]
    %Liquid.Tag{name: :assign, markup: Enum.join(markup), blank: true}
  end
end
