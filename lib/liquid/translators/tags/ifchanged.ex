defmodule Liquid.Translators.Tags.Ifchanged do
  alias Liquid.NimbleTranslator

  def translate(markup) do
    nodelist = NimbleTranslator.process_node(markup)
    %Liquid.Block{name: :ifchanged, nodelist: nodelist}
  end
end
