defmodule Liquid.Combinators.Translators.Assign do
  alias Liquid.Combinators.Translators.General

  def translate(
        variable_name: variable_name,
        value: {:variable, [variable_parts: variable_parts]}
      ) do
    variable_right =
      General.variable_in_parts(variable_parts)
      |> General.variable_to_string()

    markup_string = "#{variable_name} = #{variable_right}"

    %Liquid.Tag{
      name: :assign,
      markup: markup_string,
      blank: true
    }
  end

  def translate(
        variable_name: variable_name,
        value: {:variable, [variable_parts: variable_parts, filters: filters]}
      ) do
    variable_right =
      General.variable_in_parts(variable_parts)
      |> General.variable_to_string()

    filters =
      Enum.map(filters, fn x -> General.filters_to_string(x) end)
      |> List.to_string()

    markup_string = "#{variable_name} = #{variable_right} #{filters}"

    %Liquid.Tag{
      name: :assign,
      markup: markup_string,
      blank: true
    }
  end

  def translate(
        variable_name: variable_name,
        value: value,
        filters: filters
      ) do
    filters =
      Enum.map(filters, fn x -> General.filters_to_string(x) end)
      |> List.to_string()

    markup_string =
      case is_bitstring(value) do
        true -> "#{variable_name} = '#{value}' #{filters}"
        false -> "#{variable_name} = #{value} #{filters}"
      end

    %Liquid.Tag{
      name: :assign,
      markup: markup_string,
      blank: true
    }
  end

  def translate(variable_name: variable_name, value: value) do
    markup_string =
      case is_bitstring(value) do
        true -> "#{variable_name} = '#{value}'"
        false -> "#{variable_name} = #{value}"
      end

    %Liquid.Tag{
      name: :assign,
      markup: markup_string,
      blank: true
    }
  end
end
