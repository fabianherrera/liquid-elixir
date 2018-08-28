defmodule Liquid.Combinators.Translators.Custom_Tag do
  def translate(custom_name: name, custom_markup: markup) do
    tag_name = String.to_atom(name)
    custom_tag = Application.get_env(:liquid, :extra_tags)

    case is_map?(custom_tag) do
      true ->
        case Map.has_key?(custom_tag, tag_name) do
          true ->
            %Liquid.Tag{name: String.to_atom(name), markup: markup, blank: false}

          false ->
            raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
        end

      false ->
        raise Liquid.SyntaxError, message: "This custom tag: {% #{name} %} is not registered"
    end
  end

  defp is_map?(value) when is_map(value), do: true
  defp is_map?(_), do: false
end
