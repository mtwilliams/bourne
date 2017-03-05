defmodule Bourne.StreamTest do
  use Bourne.Test.Case, async: true

  describe "cursor" do
    @tag db: true
    test "streams a single chunk" do
      count = Repo.aggregate(Actor, :count, :id)
      rows = stream(Actor, method: :cursor, chunk: count)
      assert Enum.count(rows) == count
    end

    @tag db: true
    test "streams multiple chunks" do
      count = Repo.aggregate(Actor, :count, :id)
      rows = stream(Actor, method: :cursor, chunk: round(count / 2))
      assert Enum.count(rows) == count
    end

    @tag db: true
    test "ascending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.id])
      rows = stream(q, method: :cursor, direction: :asc)
      assert ascending?(rows), "rows are not ascending!"
    end

    @tag db: true
    test "descending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [desc: actor.id])
      rows = stream(q, method: :cursor, direction: :desc)
      assert descending?(rows), "rows are not descending!"
    end

    @tag db: true
    test "different keys" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.name])
      rows = stream(q, method: :cursor, key: :name)
      assert ascending?(rows, key: :name), "rows are not ascending!"
    end
  end

  describe "keyset" do
    @tag db: true
    test "streams a single chunk" do
      count = Repo.aggregate(Actor, :count, :id)
      rows = stream(Actor, method: :keyset, chunk: count)
      assert Enum.count(rows) == count
    end

    @tag db: true
    test "streams multiple chunks" do
      count = Repo.aggregate(Actor, :count, :id)
      rows = stream(Actor, method: :keyset, chunk: round(count / 2))
      assert Enum.count(rows) == count
    end

    @tag db: true
    test "ascending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.id])
      rows = stream(q, method: :keyset, direction: :asc)
      assert ascending?(rows), "rows are not ascending!"
    end

    @tag db: true
    test "descending" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [desc: actor.id])
      rows = stream(q, method: :keyset, direction: :desc)
      assert descending?(rows), "rows are not descending!"
    end

    @tag db: true
    test "different keys" do
      import Ecto.Query
      q = from(actor in Actor, order_by: [asc: actor.name])
      rows = stream(q, method: :keyset, key: :name)
      assert ascending?(rows, key: :name), "rows are not ascending!"
    end
  end

  defp stream(queryable, options \\ []) do
    stream = Repo.stream(queryable, options)
    {:ok, rows} = Repo.transaction fn -> Enum.to_list(stream) end
    rows
  end

  defp ascending?(rows, options \\ []), do: ordered?(rows, &>/2, options)
  defp descending?(rows, options \\ []), do: ordered?(rows, &</2, options)

  defp ordered?(rows, comparer, options \\ []) do
    key = Keyword.get(options, :key, :id)

    {_, ordered} = Enum.reduce rows, {nil, true}, fn
      (%{^key => current}, {nil, true}) -> {current, true}
      (%{^key => current}, {_, false}) -> {current, false}
      (%{^key => current}, {prev, true}) -> {current, comparer.(current, prev)}
    end

    ordered
  end
end
