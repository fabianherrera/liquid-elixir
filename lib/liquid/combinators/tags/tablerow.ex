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

  defp offset_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("offset"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:offset)
  end

  defp limit_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("limit"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:limit)
  end

  defp cols_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("cols"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:cols)
  end

  defp tablerow_params do
    empty()
    |> optional(
      times(
        choice([offset_param(), cols_param(), limit_param()]),
        min: 1
      )
    )
    |> tag(:tablerow_params)
  end

  defp tablerow_body do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:tablerow_body)
  end

  def tag, do: Tag.define_closed("tablerow", &tablerow_statements/1, &body/1)

  defp body(combinator) do
    combinator
    |> concat(tablerow_body())
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
