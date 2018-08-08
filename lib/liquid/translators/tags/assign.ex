defmodule Liquid.Translators.Tags.Assign do
  @moduledoc """
  Translate new AST to old AST for Assign tag
  """
  alias Liquid.Translators.Markup

  def translate([h | t]) do
    markup = [h | ["=" | t]]
    %Liquid.Tag{name: :assign, markup: Markup.literal(markup), blank: true}
  end
end
