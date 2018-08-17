defmodule Liquid.Template do
  @moduledoc """
  Main Liquid module, all further render and parse processing passes through it.
  """

  defstruct root: nil, presets: %{}, blocks: [], errors: []
  alias Liquid.{Context, Render, Template}

  @doc """
  Function that renders passed template and context to string.
  """
  @spec render(%Template{}, %Context{}) :: {atom(), String.t(), %Context{}}
  def render(t, c \\ %{})

  def render(%Template{} = t, %Context{} = c) do
    c = %{c | blocks: t.blocks, presets: t.presets, template: t}
    Render.render(t, c)
  end

  def render(%Template{} = t, assigns), do: render(t, assigns, [])

  def render(_, _) do
    raise Liquid.SyntaxError, message: "You can use only maps/structs to hold context data"
  end

  def render(%Template{} = t, %Context{global_filter: _global_filter} = context, options) do
    registers = Keyword.get(options, :registers, %{})
    context = %{context | registers: registers}
    render(t, context)
  end

  def render(%Template{} = t, assigns, options) when is_map(assigns) do
    context = %Context{assigns: assigns}

    context =
      case {Map.has_key?(assigns, "global_filter"), Map.has_key?(assigns, :global_filter)} do
        {true, _} ->
          %{context | global_filter: Map.fetch!(assigns, "global_filter")}

        {_, true} ->
          %{context | global_filter: Map.fetch!(assigns, :global_filter)}

        _ ->
          %{
            context
            | global_filter: Application.get_env(:liquid, :global_filter),
              extra_tags: Application.get_env(:liquid, :extra_tags, %{})
          }
      end

    render(t, context, options)
  end

  @doc """
  Function to parse markup with given presets (if any).
  """
  @spec parse(String.t(), %{}) :: %Template{}
  def parse(value, presets \\ %{})

  def parse(<<markup::binary>>, presets) do
    result = Liquid.NimbleParser.parse(markup)

    template =
      case result do
        {:ok, _value} -> Liquid.NimbleTranslator.translate(result)
        {:error, value} -> raise value
        _ -> ""
      end

    %{template | presets: presets}
  end

  @spec parse(nil, map) :: Liquid.Template
  def parse(nil, presets) do
    Liquid.Parse.parse("", %Template{presets: presets})
  end

  # TODO: delete this when new parser is finished
  @doc """
  OLD_PARSER for TEST ONLY Function to parse markup with given presets (if any).
  """
  @spec old_parse(String.t(), map) :: Liquid.Template
  def old_parse(value, presets \\ %{})

  def old_parse(<<markup::binary>>, presets) do
    Liquid.Parse.parse(markup, %Template{presets: presets})
  end

  @spec old_parse(nil, map) :: Liquid.Template
  def old_parse(nil, presets) do
    Liquid.Parse.parse("", %Template{presets: presets})
  end
end
