defmodule Liquid.Combinators.Tags.Tablerow do
  @moduledoc """
  Iterates over an array or collection splitting it up to a table with pre-set columns number
  Several useful variables are available to you within the loop.
  Generates an HTML table. Must be wrapped in opening <table> and closing </table> HTML tags.
  Input:
  ```
    <table>
      {% tablerow product in collection.products %}
        {{ product.title }}
      {% endtablerow %}
    </table>
  ```
  Output:
  ```
    <table>
    <tr class="row1">
      <td class="col1">
        Cool Shirt
      </td>
      <td class="col2">
        Alien Poster
      </td>
      <td class="col3">
        Batman Poster
      </td>
      <td class="col4">
        Bullseye Shirt
      </td>
      <td class="col5">
        Another Classic Vinyl
      </td>
      <td class="col6">
        Awesome Jeans
      </td>
    </tr>
    </table>
  ```
  """
  import NimbleParsec
  alias Liquid.Combinators.{General, Tag}

  @type t :: [
          tablerow: [
            tablerow_statements: [
              variable: Liquid.Combinators.LexicalToken.variable_value(),
              value: Liquid.Combinators.LexicalToken.value()
            ],
            tablerow_params: [limit: [LexicalToken.value()], cols: [LexicalToken.value()]],
            tablerow_body: Liquid.t()
          ]
        ]

  def tag do
    Tag.define_closed("tablerow", &tablerow_statements/1, fn combinator ->
      optional(combinator, parsec(:__parse__) |> tag(:tablerow_body))
    end)
  end

  defp tablerow_params do
    empty()
    |> times(
      choice([General.tag_param("offset"), General.tag_param("cols"), General.tag_param("limit")]),
      min: 1
    )
    |> optional()
    |> tag(:tablerow_params)
  end

  defp tablerow_statements(combinator) do
    combinator
    |> parsec(:variable_value)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> parsec(:value)
    |> optional(tablerow_params())
    |> parsec(:ignore_whitespaces)
    |> tag(:tablerow_statements)
  end
end
