import Config

config :cafe, CafeWeb.Endpoint,
  cache_static_manifest: "priv/static/cache_manifest.json"

config :logger, level: :info

config :swoosh, api_client: Swoosh.ApiClient.Finch, finch_name: Cafe.Finch
