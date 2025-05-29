defmodule Croniq.Repo do
  use Ecto.Repo,
    otp_app: :croniq,
    adapter: Ecto.Adapters.Postgres
end
