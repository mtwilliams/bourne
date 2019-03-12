defmodule Bourne.Test.Actor do
  use Ecto.Schema

  schema "actors" do
    field(:name, :string)

    has_many(:credits, Bourne.Test.Credit)
    has_many(:movies, through: [:credits, :movie])
  end
end

defmodule Bourne.Test.Movie do
  use Ecto.Schema

  schema "movies" do
    field(:title, :string)
    field(:year, :integer)

    has_many(:credits, Bourne.Test.Credit)
    has_many(:actors, through: [:credits, :actor])
  end
end

defmodule Bourne.Test.Credit do
  use Ecto.Schema

  schema "credits" do
    belongs_to(:actor, Bourne.Test.Actor)
    belongs_to(:movie, Bourne.Test.Movie)
  end
end
