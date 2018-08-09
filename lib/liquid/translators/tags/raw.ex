defmodule Liquid.Translators.Tags.Raw do
  alias Liquid.Translators.Markup

  @moduledoc """
  Translate new AST to old AST for the raw tag 
  """

  alias Liquid.Block

  @spec translate(String.t()) :: Block.t()

  def translate([markup]) do
    %Liquid.Block{name: :raw, strict: false, nodelist: ["#{Markup.literal(markup)}"]}
  end
end
