defmodule Liquid.NimbleRender do
  @moduledoc """
  Intermediate Render Liquid module, it serves as render-nimble_parse interface 
  """
  alias Liquid.{Template, Render, Context, Block, Registers, Variable, Tag, Expression, RangeLookup, Condition}
  @doc """
  Function that converts passed nimble_parser AST into valid intermediate render's template and context to string 
  """
  def render({:ok, [""], rest, _, _, _}) do 
    %Template{root: %Liquid.Block{name: :document}}
  end
 
  def render({:ok, [literal_text], rest, _, _, _}) when is_bitstring(literal_text) do 
    %Template{root: %Liquid.Block{name: :document, nodelist: [literal_text]}}
  end

  def render({:ok, nodelist, rest, _, _, _}) do
  me = self()
  list =
  nodelist
  |> remove_empty_items()
  |> Enum.map(fn (elem) ->
     spawn_link fn -> (send me, { self(), process_node(elem) }) end
     end)
  |> Enum.map(fn (pid) ->
     receive do { ^pid, result } -> result end
     end)
  %Template{root: %Liquid.Block{name: :document, nodelist: list}}
  end

  # When the element its a string literal text
  defp process_node(elem) when is_bitstring(elem) do 
  elem
  end

  # When the element its one string literal text inside a list
  defp process_node([elem]) when is_bitstring(elem) do 
  elem
  end

  # When the element its a tuple
  # defp process_node([elem]) when is_tuple(elem) do 
  # elem
  # end
  
  # When the element its a list
  defp process_node(nodelist) when is_list(nodelist) do 
  me = self()
  nodelist
  |> remove_empty_items()
  |> Enum.map(fn (elem) ->
     spawn_link fn -> (send me, { self(), process_node(elem) }) end
     end)
  |> Enum.map(fn (pid) ->
     receive do { ^pid, result } -> result end
     end)
  end

  defp process_node({:cycle, markup}) do
    value = Enum.join(markup, ", ")
    {name, values} = Liquid.Cycle.get_name_and_values(value)
    %Liquid.Tag{name: :cycle, markup: value, parts: [name | values]}
  end

  defp process_node({:assign, markup}) do
    [var_atom, value_atom] = markup
    variable_name = var_atom |> elem(1)
    value = value_atom |> elem(1)
    %Liquid.Tag{name: :assign, markup: "#{variable_name} = #{value}", blank: true}
  end

  defp process_node({:variable, markup}) do
    value = Keyword.get(markup, :variable_name)
    %Liquid.Variable{name: value, parts: [value]}
  end

  defp process_node(any) do
    any
  end

  defp remove_empty_items(nodelist) do 
    nodelist
    |>Enum.filter(fn x -> x != "" end)
  end
  
end




