defmodule Liquid.Combinators.Variable do
  @moduledoc """
  Helper to create liquid reserved variables
  """
  import NimbleParsec

  @doc """
  Define a liquid reserved variable

  The returned variable is a combinator which expect a
  start `{{` a reserved variable_name and a end `}}`

  """
  def define(variable_name) do
    empty()
    |> parsec(:start_variable)
    |> ignore(string(variable_name))
    |> parsec(:end_variable)
    |> tag(String.to_atom(variable_name))
    |> optional(parsec(:__parse__))
  end
end
