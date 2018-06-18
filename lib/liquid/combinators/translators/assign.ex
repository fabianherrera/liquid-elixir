defmodule Liquid.Combinators.Translators.Assign do
  alias Liquid.Combinators.Translators.General

  def translate([h | t]) do
    markup = [h | ["=" | t]]
    %Liquid.Tag{name: :assign, markup: Enum.join(markup), blank: true}
  end
end
