defmodule Liquid.Translators.Tags.Continue do
  @moduledoc """
  Translate new AST to old AST for the continue tag, this tag is only present inside the body of the for tag
  """

  @doc """
  This function takes the markup of the new AST and creates a `Liquid.Tag` struct (the structure needed for the old AST) and fill the keys needed, this is used recursively by the for tag.
  """
  @spec translate(List.t() | String.t()) :: Tag.t()
  def translate(_markup) do
    %Liquid.Tag{name: :continue}
  end
end
