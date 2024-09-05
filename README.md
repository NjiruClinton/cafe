# CafeOps

CafeOps is a Phoenix application for running a small specialty coffee shop: menu management, stock-aware ordering, and a live operations board for the barista team.

The project is intentionally small enough to read in one sitting while still showing the parts of Elixir/Phoenix that matter in production work:

- Context modules with Ecto schemas and changesets
- Transactional order placement with `Ecto.Multi`
- PubSub events for real-time operational screens
- OTP processes for an in-memory kitchen ticket board
- LiveView UI for an order queue and daily metrics
- Focused tests around domain behavior

## Local setup

```sh
mix setup
mix phx.server
```

The application expects PostgreSQL. Configure connection details through `DATABASE_URL` in production, or use the defaults in `config/dev.exs` while developing locally.
