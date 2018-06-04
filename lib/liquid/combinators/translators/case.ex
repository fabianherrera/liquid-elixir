defmodule Liquid.Combinators.Translators.Case do
  alias Liquid.Combinators.Translators.General

  def translate(variable: [parts: parts], capture_sentences: capture_sentences) do
    variable_in_string =
      General.variable_in_parts(parts)
      |> General.variable_to_string()

    nodelist = Liquid.NimbleTranslator.process_node(capture_sentences)
    %Liquid.Block{name: :capture, markup: variable_in_string, blank: true, nodelist: nodelist}
  end

  def translate([capture_value, capture_sentences: capture_sentences]) do
    if is_bitstring(capture_value) do
      markup = "'#{capture_value}'"
    else
      markup = "#{capture_value}"
    end

    nodelist = Liquid.NimbleTranslator.process_node(capture_sentences)
    %Liquid.Block{name: :capture, markup: markup, blank: true, nodelist: nodelist}
  end
end
