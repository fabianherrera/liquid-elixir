defmodule Liquid.Combinators.Translators.Capture do
  alias Liquid.Combinators.Translators.General

  def translate([variable, parts: parts]) do
    nodelist =
      parts
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    %Liquid.Block{name: :capture, markup: "#{variable}", blank: true, nodelist: nodelist}
  end
end
