defmodule Liquid.Combinators.Tags.EndBlock do
  @moduledoc """
  Verifies when block is closed and send the AST to end the block
  ```
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

  def check_closed_blocks(_rest, [tag_name: [tag_name]] = acc, %{tags: [current_tag | tags]} = context, _, _) do
    IO.puts("processing opening: #{tag_name} closing: #{current_tag}")
    if tag_name == current_tag do
      IO.puts("processing tag_name #{current_tag} closing: #{current_tag}")
      {[end_block: acc], %{context | tags: tags}}
    else
      IO.puts("tag_name different of current_tag: #{current_tag} closing: #{current_tag}")
      {:error, "The '#{tag_name}' tag has not been correctly closed"}
    end
  end
end
