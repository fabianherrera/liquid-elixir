defmodule Liquid.Combinators.Tags.Custom_tag do
  @moduledoc """
  Sets variables in a template
  ```
    {% assign foo = 'monkey' %}
  ```
  User can then use the variables later in the page
  ```
    {{ foo }}
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag, LexicalToken}

  def tag do
    empty()
    |> parsec(:start_tag)
    |> times(parsec(:custom_name), max: 1)
    |> parsec(:custom_markup)
    |> parsec(:end_tag)
    |> tag(:custom_tag)
    |> optional(parsec(:__parse__))
  end

  def name do
    # choice([not_register_tag_name, similar_register_tag_name])
    similar_register_tag_name()
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_name)
  end

  def markup do
    # |> concat(not_register_tag_name)
    # |> repeat_until(utf8_char([]), [string(General.codepoints().end_tag)])
    empty()
    |> parsec(:ignore_whitespaces)
    |> repeat_until(utf8_char([]), [string(General.codepoints().end_tag)])
    |> reduce({List, :to_string, []})
    |> unwrap_and_tag(:custom_markup)
  end

  defp similar_register_tag_name do
    choice([
      string("case"),
      string("endcase"),
      string("when"),
      string("if"),
      string("endif"),
      string("unless"),
      string("endunless"),
      string("assign"),
      string("capture"),
      string("endcapture"),
      string("increment"),
      string("decrement"),
      string("include"),
      string("cycle"),
      string("raw"),
      string("endraw"),
      string("for"),
      string("endfor"),
      string("break_tag"),
      string("continue_tag"),
      string("tablerow"),
      string("ifchanged"),
      string("endifchanged"),
      string("else"),
      string("comment"),
      string("endcomment"),
      string("elsif"),
      repeat_until(utf8_char([]), [utf8_char([32])])
    ])
    |> concat(repeat_until(utf8_char([]), [utf8_char([32])]))
  end

  defp not_register_tag_name() do
    repeat_until(utf8_char([]), list_of_registered_tags)
  end

  defp list_of_registered_tags do
    [
      string("case"),
      string("endcase"),
      string("when"),
      string("if"),
      string("endif"),
      string("unless"),
      string("endunless"),
      string("assign"),
      string("capture"),
      string("endcapture"),
      string("increment"),
      string("decrement"),
      string("include"),
      string("cycle"),
      string("raw"),
      string("endraw"),
      string("for"),
      string("endfor"),
      string("break_tag"),
      string("continue_tag"),
      string("tablerow"),
      string("ifchanged"),
      string("endifchanged"),
      string("else"),
      string("comment"),
      string("endcomment"),
      string("elsif"),
      utf8_char([General.codepoints().space])
    ]
  end
end

# .......................%Liquid.Template{
#   blocks: [],
#   errors: [],
#   presets: %{},
#   root: %Liquid.Block{
#     blank: false,
#     condition: nil,
#     elselist: [],
#     iterator: [],
#     markup: nil,
#     name: :document,
#     nodelist: [
#       "123",
#       %Liquid.Tag{
#         attributes: [],
#         blank: true,
#         markup: "qwe = 5",
#         name: :assign,
#         parts: []
#       }
#     ],
#     parts: [],
#     strict: true
#   }
# }
# %Liquid.Template{
#   blocks: [],
#   errors: [],
#   presets: %{},
#   root: %Liquid.Block{
#     blank: false,
#     condition: nil,
#     elselist: [],
#     iterator: [],
#     markup: nil,
#     name: :document,
#     nodelist: [
#       %Liquid.Tag{
#         attributes: [],
#         blank: false,
#         markup: "5",
#         name: :minus_one,
#         parts: []
#       }
#     ],
#     parts: [],
#     strict: true
#   }
# }
# %Liquid.Template{
#   blocks: [],
#   errors: [],
#   presets: %{},
#   root: %Liquid.Block{
#     blank: false,
#     condition: nil,
#     elselist: [],
#     iterator: [],
#     markup: nil,
#     name: :document,
#     nodelist: [
#       "a",
#       %Liquid.Tag{
#         attributes: [],
#         blank: false,
#         markup: "2",
#         name: :minus_one,
#         parts: []
#       },
#       "b"
#     ],
#     parts: [],
#     strict: true
#   }
# }
