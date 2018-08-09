defmodule Liquid.Translators.Tags.Capture do
  @moduledoc """
  Translate new AST to old AST for the capture tag 
  """
  alias Liquid.Translators.{General, Markup}
  alias Liquid.Combinators.Tags.Capture
  alias Liquid.Block

  @spec translate(Capture.markup()) :: Block.t()

  def translate([variable, parts: parts]) do
    nodelist =
      parts
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    %Liquid.Block{
      name: :capture,
      markup: Markup.literal(variable),
      blank: true,
      nodelist: nodelist
    }
  end
end
