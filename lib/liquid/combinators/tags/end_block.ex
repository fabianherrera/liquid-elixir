defmodule Liquid.Combinators.Tags.EndBlock do
  @moduledoc """
  Verifies when block is closed and send the AST to end the block
  """
  alias Liquid.Combinators.General

  import NimbleParsec

  def tag do
    empty()
    |> parsec(:start_tag)
    |> ignore(string("end"))
    |> concat(General.valid_tag_name())
    |> tag(:tag_name)
    |> parsec(:end_tag)
    |> traverse({__MODULE__, :check_closed_blocks, []})
  end

  def check_closed_blocks(_, [tag_name: [tag]], %{tags: []} = context, _, _) do
    {[error: "The tag '#{tag}' was not opened"], context}
  end

  def check_closed_blocks(_, [tag_name: [tag]] = acc, %{tags: [last_tag | tags]} = context, _, _) do
    if tag == last_tag do
      {[end_block: acc], %{context | tags: tags}}
    else
      {[error: "The '#{last_tag}' tag has not been correctly closed"], %{context | tags: tags}}
    end
  end
end
