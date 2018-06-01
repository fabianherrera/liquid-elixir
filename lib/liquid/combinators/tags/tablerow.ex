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
  alias Liquid.Combinators.General

  @doc "Tablerow offset param: {% tablerow products in products cols:2 %}"
  def cols_param do
    empty()
    |> parsec(:ignore_whitespaces)
    |> ignore(string("cols"))
    |> ignore(ascii_char([General.codepoints().colon]))
    |> parsec(:ignore_whitespaces)
    |> concat(choice([parsec(:number), parsec(:variable_definition)]))
    |> parsec(:ignore_whitespaces)
    |> tag(:cols_param)
  end

  def tablerow_sentences do
    empty()
    |> optional(parsec(:__parse__))
    |> tag(:tablerow_sentences)
  end

  @doc "Open Tablerow tag: {% tablerow products in products %}"
  def open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("tablerow"))
    |> parsec(:variable_name)
    |> parsec(:ignore_whitespaces)
    |> ignore(string("in"))
    |> parsec(:ignore_whitespaces)
    |> choice([parsec(:range_value), parsec(:value)])
    |> optional(
      times(choice([parsec(:offset_param), parsec(:cols_param), parsec(:limit_param)]), min: 1)
    )
    |> parsec(:ignore_whitespaces)
    |> concat(parsec(:end_tag))
    |> tag(:tablerow_conditions)
    |> parsec(:tablerow_sentences)
  end

  @doc "Close Tablerow tag: {% endtablerow %}"
  def close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endtablerow"))
    |> concat(parsec(:end_tag))
  end

  def tag do
    empty()
    |> parsec(:open_tag_tablerow)
    |> parsec(:close_tag_tablerow)
    |> tag(:tablerow)
    |> optional(parsec(:__parse__))
  end
end
