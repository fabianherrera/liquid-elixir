defmodule Liquid.Translators.Tags.Increment do
  alias Liquid.Translators.Markup

  def translate(markup) do
    variable_name = Keyword.get(markup, :variable_name)
    %Liquid.Tag{name: :increment, markup: "#{Markup.literal(variable_name)}"}
  end
end
