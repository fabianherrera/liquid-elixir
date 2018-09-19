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

  def check_closed_blocks(
        _rest,
        [tag_name: [tag_name]] = acc,
        %{tags: [current_tag | tags]} = context,
        _,
        _
      ) do
    IO.puts("close: #{inspect(context)}")

    if tag_name == current_tag do
      {[end_block: acc], %{context | tags: tags}}
    else
      {:error, "The '#{tag_name}' tag has not been correctly closed"}
    end
  end
end
