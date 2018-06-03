defmodule Liquid.Combinators.Tags.Ifchanged do
  @moduledoc """
  The block contained within ifchanged will only be rendered to the output if the last call to ifchanged returned different output.

  Here is an example:

  <h1>Product Listing</h1>
  {% for product in products %}
    {% ifchanged %}<h3>{{ product.created_at | date:"%w" }}</h3>{% endifchanged %}
    <p>{{ product.title }} </p>
     ...
  {% endfor %}
  """
  import NimbleParsec

  def tag do
    open_tag()
    |> optional(parsec(:__parse__))
    |> concat(close_tag())
    |> tag(:ifchanged)
    |> optional(parsec(:__parse__))
  end

  defp open_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("ifchanged"))
    |> parsec(:end_tag)
  end

  defp close_tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("endifchanged"))
    |> parsec(:end_tag)
  end

end
