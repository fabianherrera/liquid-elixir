defmodule Liquid.Translators.Tags.CustomTag do
  alias Liquid.{Template, Tag}

  def translate(custom_name: name, custom_markup: markup) do
    tag_name = String.to_atom(name)
    custom_tag = Application.get_env(:liquid, :extra_tags)

    case is_map(custom_tag) do
      true ->
        case Map.has_key?(custom_tag, tag_name) do
          true ->
            partial_tag = %Tag{
              name: String.to_atom(name),
              markup: String.trim(markup)
            }

            {module, _type} = Map.get(custom_tag, tag_name)
            {tag, _contex} = module.parse(partial_tag, %Template{})
            tag

          false ->
            raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
        end

      false ->
        raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
    end
  end
end
