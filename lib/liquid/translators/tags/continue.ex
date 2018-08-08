defmodule Liquid.Translators.Tags.Continue do
  def translate(_markup) do
    %Liquid.Tag{name: :continue}
  end
end
