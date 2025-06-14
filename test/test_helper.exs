ExUnit.start()
ExUnit.configure(seed: :rand.uniform(100_000))
Ecto.Adapters.SQL.Sandbox.mode(Croniq.Repo, :manual)
