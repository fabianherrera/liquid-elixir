defmodule Liquid.Translators.Tags.Break do
  def translate(_markup) do
    %Liquid.Tag{name: :break}
  end
end
