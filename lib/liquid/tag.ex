defmodule Liquid.Tag do
  defstruct name: nil, markup: nil, parts: [], attributes: [], blank: false

  @type t :: %Liquid.Tag{
          name: String.t() | nil,
          markup: String.t() | nil,
          parts: List.t(),
          attributes: List.t(),
          blank: Boolean.t()
        }

  def create(markup) do
    destructure [name, rest], String.split(markup, " ", parts: 2)
    %Liquid.Tag{name: name |> String.to_atom(), markup: rest}
  end
end
