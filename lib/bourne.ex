# TODO(mtwilliams): Support raw SQL.

defmodule Bourne do
  @moduledoc ~S"""
  """

  @type method :: :cursor | :keyset

  # TODO(mtwilliams): Specify all possible options.
  @type option :: {:method, method}
  @type options :: [option]

  defmacro __using__(_) do
    quote location: :keep do
      defoverridable [stream: 1, stream: 2]

      @spec stream(queryable :: Ecto.Queryable.t, options :: Bourne.options) :: Enum.t
      @doc ~S"""
      """
      def stream(queryable, options \\ []) do
        case Keyword.pop(options, :method, :cursor) do
          {:cursor, options} ->
            super(queryable, options)
          {:keyset, options} ->
            Bourne.Stream.__build__(__MODULE__, queryable, options)
        end
      end

      @spec streamer(queryable :: Ecto.Queryable.t, options :: Bourne.options) :: GenServer.on_start
      @doc ~S"""
      """
      def streamer(queryable, options \\ []) do
        case Keyword.pop(options, :link, true) do
          {true, options} ->
            GenStage.start_link(Bourne.Streamer, {__MODULE__, queryable, options}, options)
          {false, options} ->
            GenStage.start(Bourne.Streamer, {__MODULE__, queryable, options}, options)
        end
      end
    end
  end
end
