defmodule Bourne.Stream do
  @moduledoc false

  defstruct [:repo, :queryable, :options, :state]

  def __build__(repo, queryable, options) do
    key = Keyword.get(options, :key, :id)
    direction = Keyword.get(options, :direction, :asc)
    chunk = Keyword.get(options, :chunk, 1_000)

    %__MODULE__{
      repo: repo,
      queryable: queryable,
      options: %{key: key, direction: direction, chunk: chunk},
      state: %{}
    }
  end
end

defmodule Bourne.Stream.Chunk do
  @moduledoc false
  defstruct [:stream, :rows]
end

defimpl Enumerable, for: Bourne.Stream do
  require Ecto.Query

  def count(_), do: {:error, __MODULE__}
  def member?(_, _), do: {:error, __MODULE__}

  def reduce(_, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(stream, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(stream, &1, fun)}
  end

  def reduce(stream, {:cont, acc}, fun) do
    key = stream.options[:key]
    chunk = stream.options[:chunk]

    rows = stream.queryable
           |> offset(stream)
           |> Ecto.Query.limit(^chunk)
           |> stream.repo.all()

    case List.last(rows) do
      nil ->
        {:done, acc}

      %{^key => last_seen_key} ->
        state = Map.put(stream.state, :last_seen_key, last_seen_key)
        stream = %Bourne.Stream{stream | state: state}
        chunk = %Bourne.Stream.Chunk{stream: stream, rows: rows}

        Enumerable.reduce(chunk, {:cont, acc}, fun)
    end
  end

  defp offset(query, %Bourne.Stream{state: state}) when (state == %{}) do
    query
  end

  defp offset(query, stream) do
    key = stream.options[:key]
    direction = stream.options[:direction]
    last_seen_key = stream.state.last_seen_key

    case direction do
      :asc ->
        query |> Ecto.Query.where([r], field(r, ^key) > ^last_seen_key)
      :desc ->
        query |> Ecto.Query.where([r], field(r, ^key) < ^last_seen_key)
    end
  end
end

defimpl Enumerable, for: Bourne.Stream.Chunk do
  def count(_), do: {:error, __MODULE__}
  def member?(_, _), do: {:error, __MODULE__}

  def reduce(_, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  def reduce(chunk, {:suspend, acc}, fun) do
    {:suspended, acc, &reduce(chunk, &1, fun)}
  end

  def reduce(%Bourne.Stream.Chunk{rows: []} = chunk, {:cont, acc}, fun) do
    Enumerable.reduce(chunk.stream, {:cont, acc}, fun)
  end

  def reduce(%Bourne.Stream.Chunk{rows: [row | remaining]} = chunk, {:cont, acc}, fun) do
    reduce(%Bourne.Stream.Chunk{chunk | rows: remaining}, fun.(row, acc), fun)
  end
end
