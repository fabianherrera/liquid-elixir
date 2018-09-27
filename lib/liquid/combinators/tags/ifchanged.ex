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
  alias Liquid.Combinators.Tag

  @doc """
  Parses a `Liquid` IfChanged tag, creates a Keyword list where the key is the name of the tag
  (ifchanged in this case) and the value is another keyword list which represent the internal
  structure of the tag.
  """
  @spec tag() :: NimbleParsec.t()
  def tag do
    Tag.define_closed("ifchanged", & &1, fn combinator ->
      optional(combinator, parsec(:__parse__))
    end)
  end

  def tag2 do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("ifchanged"))
    |> parsec(:end_tag)
    |> tag(:ifchanged)
    |> tag(:block)
    |> traverse({Tag, :store_tag_in_context, []})
  end
end
