defmodule Liquid.Translators.Tags.Continue do
  @moduledoc """
  Translate new AST to old AST for the continue tag, this tag is only present inside the body of the for tag
  """
  def translate(_markup) do
    %Liquid.Tag{name: :continue}
  end
end
