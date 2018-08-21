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
  Parse a `Liquid` IfChanged tag.
  """
  def tag do
    Tag.define_closed("ifchanged", & &1, fn combinator ->
      optional(combinator, parsec(:__parse__))
    end)
  end
end
