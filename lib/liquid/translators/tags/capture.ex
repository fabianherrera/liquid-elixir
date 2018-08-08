defmodule Liquid.Translators.Tags.Capture do
  alias Liquid.Translators.{General, Markup}

  def translate([variable, parts: parts]) do
    nodelist =
      parts
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    %Liquid.Block{name: :capture, markup: Markup.literal(variable), blank: true, nodelist: nodelist}
  end
end
