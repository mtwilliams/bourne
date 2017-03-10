defmodule Bourne.StreamerTest do
  use Bourne.Test.Case, async: false

  defmodule Forwarder do
    use GenStage

    defstruct [:listener]

    def start_link(options) do
      GenStage.start_link(__MODULE__, options)
    end

    def init([listener: listener]) do
      {:consumer, %__MODULE__{listener: listener}}
    end

    def handle_events(rows, _from, state) do
      send(state.listener, rows)
      {:noreply, [], state}
    end

    def handle_info({{_, _}, :exhausted}, state) do
      send(state.listener, :exhausted)
      {:noreply, [], state}
    end
  end

  describe "cursor" do
    @tag db: true
    test "streams a single chunk" do
      count = Repo.aggregate(Actor, :count, :id)
      :ok = stream(Actor, method: :cursor, chunk: count)
      assert_receive(rows when length(rows) == count)
      assert_receive(:exhausted)
    end

    @tag db: true
    test "streams multiple chunks" do
      count = Repo.aggregate(Actor, :count, :id)
      :ok = stream(Actor, method: :cursor, chunk: round(count / 2))
      assert_receive(rows when length(rows) == round(count / 2))
      assert_receive(rows when length(rows) == round(count / 2))
      assert_receive(:exhausted)
    end

    @tag db: true
    test "ascending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.id])
      :ok = stream(q, method: :cursor, direction: :asc)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert ascending?(rows), "rows are not ascending!"
    end

    @tag db: true
    test "descending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [desc: actor.id])
      :ok = stream(q, method: :cursor, direction: :desc)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert descending?(rows), "rows are not descending!"
    end

    @tag db: true
    test "different keys" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.name])
      :ok = stream(q, method: :cursor, key: :name)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert ascending?(rows, key: :name), "rows are not ascending by `name`!"
    end
  end

  describe "keyset" do
    @tag db: true
    test "streams a single chunk" do
      count = Repo.aggregate(Actor, :count, :id)
      :ok = stream(Actor, method: :keyset, chunk: count)
      assert_receive(rows when length(rows) == count)
      assert_receive(:exhausted)
    end

    @tag db: true
    test "streams multiple chunks" do
      count = Repo.aggregate(Actor, :count, :id)
      :ok = stream(Actor, method: :keyset, chunk: round(count / 2))
      assert_receive(rows when length(rows) == round(count / 2))
      assert_receive(rows when length(rows) == round(count / 2))
      assert_receive(:exhausted)
    end

    @tag db: true
    test "ascending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.id])
      :ok = stream(q, method: :keyset, direction: :asc)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert ascending?(rows), "rows are not ascending!"
    end

    @tag db: true
    test "descending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [desc: actor.id])
      :ok = stream(q, method: :keyset, direction: :desc)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert descending?(rows), "rows are not descending!"
    end

    @tag db: true
    test "different keys" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.name])
      :ok = stream(q, method: :keyset, key: :name)
      rows = assert_receive(rows when is_list(rows))
      assert_receive(:exhausted)
      assert ascending?(rows, key: :name), "rows are not ascending by `name`!"
    end
  end

  defp stream(queryable, options) do
    {:ok, streamer} = Repo.streamer(queryable, options)
    Ecto.Adapters.SQL.Sandbox.allow(Repo, self(), streamer)
    {:ok, forwarder} = Forwarder.start_link(listener: self())
    {:ok, _} = GenStage.sync_subscribe(forwarder, to: streamer)
    :ok
  end
end
