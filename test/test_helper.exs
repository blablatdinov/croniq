ExUnit.start()

# Configure Mox for HTTPoison mocking
Mox.defmock(Croniq.HttpClientMock, for: Croniq.HttpClient)

# Configure the database for testing
Ecto.Adapters.SQL.Sandbox.mode(Croniq.Repo, :manual)

ExUnit.configure(seed: :rand.uniform(100_000))
