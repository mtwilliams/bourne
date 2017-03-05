defmodule Bourne.Test.Repo.Migrations.Setup do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add :name, :string

      timestamps()
    end

    create table(:movies) do
      add :title, :string
      add :year, :integer

      timestamps()
    end

    create table(:credits) do
      add :actor_id, references(:actors)
      add :movie_id, references(:movies)

      timestamps()
    end
  end
end
