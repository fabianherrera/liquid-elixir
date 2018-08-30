defmodule Liquid.Translators.Tags.CustomBlock do
  alias Liquid.Translators.General

  def translate(custom_name: name, custom_markup: markup, body: body, custom_name: _endname) do
    tag_name = String.to_atom(name)

    nodelist =
      body
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    %Liquid.Block{
      name: tag_name,
      markup: markup,
      blank: true,
      nodelist: nodelist
    }
  end
end
