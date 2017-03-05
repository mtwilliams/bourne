defmodule Bourne.Test.Case do
  use ExUnit.CaseTemplate

  using do
    quote do
      alias Bourne.Test.{Repo, Actor, Movie, Credit}

      import Ecto.Query
    end
  end

  setup context do
    if context[:db] do
      :ok = Ecto.Adapters.SQL.Sandbox.checkout(Bourne.Test.Repo)

      # Move into `Bourne.StreamerTest` cases?
      Ecto.Adapters.SQL.Sandbox.mode(Bourne.Test.Repo, {:shared, self()})

      # Toggle with different tag?
      Bourne.Test.Data.insert!
    end
  end
end
