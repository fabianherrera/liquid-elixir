defmodule Liquid.ParallelParser do
  @doc """
  Validates and parse liquid markup.
  """
  @spec parse(String.t()) :: {:ok | :error, any()}
  def parse(markup) do
    markup
    |> Liquid.Tokenizer.tokenize2()
    |> Enum.chunk_every(12)
    |> pmap(fn l -> Enum.map(l, &process_token/1) end)
    |> List.flatten()
  end

  defp pmap(collection, fun) do
    me = self()

    collection
    |> Enum.map(fn elem ->
      spawn_link(fn -> send(me, {self(), fun.(elem)}) end)
    end)
    |> Enum.map(fn pid ->
      receive do
        {^pid, result} -> result
      end
    end)
  end

  defp process_token({:literal, _} = token), do: token
  defp process_token({:liquid, token}) do
    case Liquid.Parser.__parse__(token) do
      {:ok, acc, _, _, _, _} -> acc
      {:error, message, rest, _, _, _} -> {:error, message, rest}
    end
  end
end
