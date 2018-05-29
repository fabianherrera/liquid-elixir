defmodule Liquid.Combinators.Var do
  @moduledoc """
  Helper to create liquid reserved objects
  """
  import NimbleParsec

  @doc """
  Define a liquid reserved var from a var_name

  The returned var is a combinator which expect a start var `{{` a reserved var name and a end var `}}`

  """
  def define_var(var_name) do
    empty()
    |> parsec(:start_variable)
    |> ignore(string(var_name))
    |> parsec(:end_variable)
    |> tag(String.to_atom(var_name))
    |> optional(parsec(:__parse__))
  end

end
