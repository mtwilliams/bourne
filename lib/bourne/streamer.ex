if Code.ensure_loaded?(GenStage) do
  defmodule Bourne.Streamer do
    @moduledoc false

    use GenStage

    defstruct [
      :method,
      :forwarder,
      :consumers,
      :exhausted
    ]

    def init({repo, queryable, options}) do
      # TODO(mtwilliams): Don't use a forwarder for `keyset` pagination.
      method = Keyword.get(options, :method, :cursor)
      chunk = Keyword.get(options, :chunk, 1_000)
      stream = repo.stream(queryable, options) |> Stream.chunk(chunk, chunk, [])
      {:ok, forwarder} = forward(repo, stream, self(), transaction: (method == :cursor))

      consumers = case Keyword.get(options, :consumers, :temporary) do
        :temporary -> :temporary
        :permanent -> []
      end

      state = %__MODULE__{
        method: method,
        forwarder: forwarder,
        consumers: consumers,
        exhausted: false
      }

      passthrough = Keyword.take(options, [:dispatcher, :demand])
                 |> Keyword.merge(buffer_size: chunk)

      {:producer, state, passthrough}
    end

    def handle_subscribe(_, _, _from, %__MODULE__{consumers: :temporary} = state) do
      {:automatic, state}
    end
    def handle_subscribe(_, _, {_, ref}, state) do
      {:automatic, %__MODULE__{state | consumers: [ref | state.consumers]}}
    end

    def handle_cancel(_, _, %__MODULE__{consumers: :temporary} = state) do
      {:noreply, [], state}
    end
    def handle_cancel(_, {_, ref}, state) do
      case List.delete(state.consumers, ref) do
        [] ->
          {:stop, :normal, %__MODULE__{state | consumers: []}}
        consumers ->
          {:noreply, [], %__MODULE__{state | consumers: consumers}}
      end
    end

    def handle_demand(_, %__MODULE__{exhausted: true} = state) do
      {:noreply, [], state}
    end
    def handle_demand(demand, state) when demand > 0 do
      send(state.forwarder, {:demand, demand})
      {:noreply, [], state}
    end

    def handle_info({:supply, rows}, state) do
      {:noreply, rows, state}
    end
    def handle_info(:exhausted, state) do
      GenStage.async_notify(self(), :exhausted)
      {:noreply, [], %__MODULE__{state | exhausted: true}}
    end

    defp forward(repo, stream, to, options \\ []) do
      transaction = Keyword.get(options, :transaction, false)

      Task.start_link fn ->
        forward_on_demand = fn ->
          Stream.each(stream, fn (supply) ->
            demand =
              case Process.get(:demand, 0) do
                0 -> receive do {:demand, demand} -> demand end
                demand -> demand
              end

            send(to, {:supply, supply})

            Process.put(:demand, max(demand - length(supply), 0))
          end) |> Stream.run
        end

        if transaction do
          repo.transaction(forward_on_demand)
        else
          forward_on_demand.()
        end

        send(to, :exhausted)
      end
    end
  end
end
