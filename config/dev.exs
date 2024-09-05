import Config

config :cafe, Cafe.Repo,
  username: "postgres",
  password: "postgres",
  hostname: "localhost",
  database: "cafe_dev",
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :cafe, CafeWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4000],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: "LHoOy9GzRgT3Ee6RZA24OiKb1n9vHS96hWiYjdCGnk3VIhyzZkaYsnoSjj1dRwpu",
  watchers: [
    esbuild: {Esbuild, :install_and_run, [:cafe, ~w(--sourcemap=inline --watch)]},
    tailwind: {Tailwind, :install_and_run, [:cafe, ~w(--watch)]}
  ]

config :cafe, CafeWeb.Endpoint,
  live_reload: [
    patterns: [
      ~r"priv/static/(?!uploads/).*(js|css|png|jpeg|jpg|gif|svg)$",
      ~r"priv/gettext/.*(po)$",
      ~r"lib/cafe_web/(controllers|live|components)/.*(ex|heex)$"
    ]
  ]

config :cafe, dev_routes: true

config :logger, :console, format: "[$level] $message\n"

config :phoenix, :stacktrace_depth, 20
config :phoenix, :plug_init_mode, :runtime

config :swoosh, :api_client, false
