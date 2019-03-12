defmodule Bourne.Test.Repo.Migrations.Setup do
  use Ecto.Migration

  def change do
    create table(:actors) do
      add(:name, :string)
    end

    create table(:movies) do
      add(:title, :string)
      add(:year, :integer)
    end

    create table(:credits) do
      add(:actor_id, references(:actors))
      add(:movie_id, references(:movies))
    end
  end
end
