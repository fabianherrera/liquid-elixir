defmodule Liquid.NimbleParserTransformer do
  alias Liquid.Template

  @literals %{
    "nil" => nil,
    "null" => nil,
    "" => nil,
    "true" => true,
    "false" => false,
    "blank" => :blank?,
    "empty" => :empty?
  }

  @integer ~r/^(-?\d+)$/
  @float ~r/^(-?\d[\d\.]+)$/
  @start_quoted_string ~r/^#{Liquid.quoted_string()}/

  def transformation({:ok, list}) do
    # Enum.filter(list, fn x -> x != "" end)
    # |> Enum.map(&create(&1))
    trans = Enum.map(list, &create(&1))

    block = %Liquid.Block{name: :document, nodelist: trans}
    %Template{root: block}
  end

  def create({:cycle, markup}) do
    value = Enum.join(markup, ", ")
    {name, values} = Liquid.Cycle.get_name_and_values(value)
    %Liquid.Tag{name: :cycle, markup: value, parts: [name | values]}
  end

  def create({:assign, markup}) do
    case markup do
      [var_atom, value_atom] ->
        variable_name = var_atom |> elem(1)
        value = value_atom |> elem(1)
        %Liquid.Tag{name: :assign, markup: "#{variable_name} = #{value}", blank: true}

      [var_atom, value_atom, filter_atom] ->
        variable_name = var_atom |> elem(1)
        value = value_atom |> elem(1)
        filter_list = filter_atom |> elem(1)
        filter_name = Keyword.get(filter_list, :variable_name)
        filter_param_list = Keyword.get(filter_list, :filter_param)
        filter_param_value = Keyword.get(filter_param_list, :value)

        %Liquid.Tag{
          name: :assign,
          markup: "#{variable_name} = #{value} | #{filter_name} #{filter_param_value}",
          blank: true
        }
    end
  end

  def create({:variable, markup}) do
    value = List.to_string(markup)
    variable = %Liquid.Variable{name: value}
    value_in_parts = separate_objects(value)
    Map.merge(variable, value_in_parts)
  end

  defp separate_objects(name) do
    value =
      cond do
        Map.has_key?(@literals, name) ->
          Map.get(@literals, name)

        Regex.match?(@integer, name) ->
          String.to_integer(name)

        Regex.match?(@float, name) ->
          String.to_float(name)

        Regex.match?(@start_quoted_string, name) ->
          Regex.replace(Liquid.quote_matcher(), name, "")

        true ->
          Liquid.variable_parser() |> Regex.scan(name) |> List.flatten()
      end

    if is_list(value), do: %{parts: value}, else: %{literal: value}
  end

  def create(any) do
    any
  end
end
