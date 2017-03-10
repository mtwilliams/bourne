Logger.configure(level: :info)

# TODO(mtwilliams): Test against other adapters.
Application.put_env :bourne, Bourne.Test.Repo, [
  adapter: Ecto.Adapters.Postgres,
  url: System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/bourne",
  pool: Ecto.Adapters.SQL.Sandbox
]

for file <- ~W{support/repo.exs support/schema.exs support/data.exs support/case.exs} do
  Code.require_file(file, __DIR__)
end

# Reset backing storage, start the repository, and run migration.
_   = Ecto.Adapters.Postgres.storage_down(Bourne.Test.Repo.config)
:ok = Ecto.Adapters.Postgres.storage_up(Bourne.Test.Repo.config)

{:ok, _} = Bourne.Test.Repo.start_link()

migrations = Path.join(:code.priv_dir(:bourne), "/repo/migrations")
migration = Path.join(migrations, "1_setup.exs")

Code.require_file(migration)

:ok = Ecto.Migrator.up(Bourne.Test.Repo, 0, Bourne.Test.Repo.Migrations.Setup, log: false)

ExUnit.configure([])
ExUnit.start()

Ecto.Adapters.SQL.Sandbox.mode(Bourne.Test.Repo, :manual)
