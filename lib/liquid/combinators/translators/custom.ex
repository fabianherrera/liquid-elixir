defmodule Liquid.Combinators.Translators.Custom do
  alias Liquid.NimbleTranslator

  def translate(custom_name: name, custom_markup: markup) do
    %Liquid.Tag{name: String.to_atom(name), markup: markup, blank: false}
  end
end
