import Config

# Only in tests, remove the complexity from the password hashing algorithm
config :bcrypt_elixir, :log_rounds, 1

# Configure your database
#
# The MIX_TEST_PARTITION environment variable can be used
# to provide built-in test partitioning in CI environment.
# Run `mix help test` for more information.
config :croniq, Croniq.Repo,
  username: "almazilaletdinov",
  password: "",
  hostname: "localhost",
  database: "croniq_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: System.schedulers_online() * 2

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :croniq, CroniqWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "QKHv9tfwFhA/FCJf65poSxcv2pi0PUFrookMo4EpOsLeteysOeAV2fbfRI+WcT6M",
  server: false

# In test we don't send emails
config :croniq, Croniq.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime

# Enable helpful, but potentially expensive runtime checks
config :phoenix_live_view,
  enable_expensive_runtime_checks: true

# Configure reCAPTCHA for tests
config :croniq, :recaptcha,
  site_key: "test_site_key",
  secret_key: "test_secret_key",
  site_key_v2: "test_site_key_v2",
  secret_key_v2: "test_secret_key_v2",
  verify_url: "https://www.google.com/recaptcha/api/siteverify"

# Use mock for reCAPTCHA in tests
config :croniq, :recaptcha_module, Croniq.RecaptchaMock

config :croniq, :http_client, Croniq.HttpClientMock

config :redix, url: System.get_env("REDIS_URL") || "redis://localhost:6379"
