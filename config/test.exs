import Config

config :cafe, Cafe.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cafe_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10

config :cafe, CafeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "2PoFwXMvvZtEhvHr8ykvJiHdExIoMFMA80mIzrgjBYN5PW3IIXgzPUajEi4XAgE3",
  server: false

config :cafe, Cafe.Mailer, adapter: Swoosh.Adapters.Test

config :logger, level: :warning

config :phoenix, :plug_init_mode, :runtime
