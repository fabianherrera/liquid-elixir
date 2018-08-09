defmodule Liquid.Translators.Tags.Comment do
  @moduledoc """
  Translate new AST to old AST for the comment tag 
  """

  alias Liquid.Combinators.Tags.Comment
  alias Liquid.Block

  @spec translate(Comment.markup()) :: Block.t()

  def translate(markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false, nodelist: [""]}
  end
end
