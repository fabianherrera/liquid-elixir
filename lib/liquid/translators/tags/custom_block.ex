defmodule Liquid.Translators.Tags.CustomBlock do
  alias Liquid.Translators.General
  alias Liquid.{Template, Block}

  def translate(custom_name: name, custom_markup: markup, body: body) do
    tag_name = String.to_atom(name)
    custom_tags = Application.get_env(:liquid, :extra_tags)

    nodelist =
      body
      |> Liquid.NimbleTranslator.process_node()
      |> General.types_only_list()

    partial_block = %Block{
      name: tag_name,
      markup: String.trim(markup),
      nodelist: nodelist
    }

    user_parse(partial_block, custom_tags, tag_name)
  end

  def translate(custom_name: name, custom_markup: markup) do
    tag_name = String.to_atom(name)
    custom_tags = Application.get_env(:liquid, :extra_tags)

    partial_block = %Block{
      name: tag_name,
      markup: String.trim(markup)
    }

    user_parse(partial_block, custom_tags, tag_name)
  end

  defp user_parse(partial_block, map_of_tags, tag_name) do
    {module, _type} = Map.get(map_of_tags, tag_name)
    {block, _contex} = module.parse(partial_block, %Template{})
    block
  end
end
