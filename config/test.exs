use Mix.Config
config :bourne, ecto_repos: [Bourne.Test.Repo]

config :bourne, Bourne.Test.Repo,
  database: "bourne_test",
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  port: "5432"
