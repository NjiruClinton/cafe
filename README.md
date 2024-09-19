# CafeOps

CafeOps is a Phoenix application for running a small specialty coffee shop: menu management, stock-aware ordering, and a live operations board for the barista team.

The project is intentionally small enough to read in one sitting while still showing the parts of Elixir/Phoenix that matter in production work:

- Context modules with Ecto schemas and changesets
- Transactional order placement with `Ecto.Multi`
- PubSub events for real-time operational screens
- OTP processes for an in-memory kitchen ticket board
- LiveView UI for an order queue and daily metrics
- Focused tests around domain behavior
- Docker and GitHub Actions setup for deployment-minded workflows

## Local setup

```sh
mix setup
mix phx.server
```

The application expects PostgreSQL. Configure connection details through `DATABASE_URL` in production, or use the defaults in `config/dev.exs` while developing locally.

## Notable modules

- `Cafe.Orders` places an order with `Ecto.Multi`, snapshots line prices, consumes inventory with row locks, emits telemetry, and publishes updates.
- `Cafe.Inventory` owns stock levels, recipes, and low-stock reporting.
- `Cafe.Kitchen.TicketBoard` is an OTP projection of active tickets for LiveView.
- `CafeWeb.OpsDashboardLive` renders real-time shop status and lets staff advance ticket state.

## Architecture notes

The application treats Postgres as the source of truth and keeps the live kitchen board as a disposable projection. That gives the UI fast updates while avoiding hidden business state inside LiveView processes.

Inventory is decremented inside the same transaction as order placement. Ingredient rows are locked before updates, which prevents overselling when two counter staff submit orders at the same time.

## Common commands

```sh
mix format
mix test
mix ecto.reset
```

## Environment

Production expects:

- `DATABASE_URL`
- `SECRET_KEY_BASE`
- `PHX_HOST`
- `PORT` (optional, defaults to `4000`)
