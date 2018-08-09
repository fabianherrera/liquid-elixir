defmodule Liquid.Translators.Tags.Break do
  @moduledoc """
  Translate new AST to old AST for the break  tag, this tag is only present inside the body of the for tag
  """
  def translate(_markup) do
    %Liquid.Tag{name: :break}
  end
end
