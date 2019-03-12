defmodule Bourne.Test.Repo do
  use Ecto.Repo,
    otp_app: :bourne,
    adapter: Ecto.Adapters.Postgres

  use Bourne
end
