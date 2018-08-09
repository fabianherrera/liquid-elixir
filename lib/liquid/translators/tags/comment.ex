defmodule Liquid.Translators.Tags.Comment do
  @moduledoc """
  Translate new AST to old AST for the comment tag 
  """

  alias Liquid.Combinators.Tags.Comment
  alias Liquid.Block

  @doc """
  This function takes the markup of the new AST and creates a `Liquid.Block` struct (the structure needed for the old AST) and fill the keys needed to render a Comment tag.
  """

  @spec translate(Comment.markup()) :: Block.t()
  def translate(markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false, nodelist: [""]}
  end
end
