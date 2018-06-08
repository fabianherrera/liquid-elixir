defmodule Liquid.Combinators.Translators.Assign do
  alias Liquid.Combinators.Translators.General

  def translate(markup) do
    %Liquid.Tag{name: :assign, markup: Enum.join(markup), blank: true}
  end
end
