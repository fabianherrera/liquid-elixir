defmodule Liquid.Combinators.Translators.General do
  @moduledoc false

  def variable(markup) do
    parts = Enum.map(markup, &variable_in_parts/1)
    name = variable_to_string(parts)
    %Liquid.Variable{name: name, parts: parts}
  end

  def variable_in_parts(value) do
    cond do
      is_binary(value) == true ->
        "#{value}"

      is_tuple(value) == true ->
        position = value |> elem(1)
        "[#{position}]"

      is_float(value) == true ->
        "#{value}"

      is_integer(value) == true ->
        "#{value}"
    end
  end

  def variable_to_string(variable_in_parts) do
    Enum.join(variable_in_parts, ".")
      |> String.replace(".[", "[")
  end

  def filters_to_string([filter_name]) do
    "| #{filter_name} "
  end

  def filters_to_string([filter_name, filter_atom]) do
    filter_param_value = filter_atom |> elem(1)
    value = filter_param_value
    |> Keyword.get(:value)
    |> Enum.map(&variable_in_parts(&1))
    |> variable_to_string()
    "| #{filter_name}: #{value}"
  end
end
