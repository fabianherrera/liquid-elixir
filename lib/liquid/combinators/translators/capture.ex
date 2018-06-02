defmodule Liquid.Combinators.Translators.Capture do
  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    capture_sentences = Keyword.get(markup, :capture_sentences)
    nodelist = Liquid.NimbleTranslator.translate(capture_sentences)
    %Liquid.Block{name: :capture, markup: variable_name, blank: true, nodelist: nodelist}
  end
end
