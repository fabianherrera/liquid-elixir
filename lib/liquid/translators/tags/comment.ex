defmodule Liquid.Translators.Tags.Comment do
  @moduledoc """
  Translate new AST to old AST for the comment tag 
  """

  def translate(markup) do
    %Liquid.Block{name: :comment, blank: true, strict: false, nodelist: [""]}
  end
end
