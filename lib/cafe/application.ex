defmodule Cafe.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      CafeWeb.Telemetry,
      Cafe.Repo,
      {DNSCluster, query: Application.get_env(:cafe, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: Cafe.PubSub},
      {Finch, name: Cafe.Finch},
      Cafe.Kitchen.TicketBoard,
      CafeWeb.Endpoint
    ]

    opts = [strategy: :one_for_one, name: Cafe.Supervisor]
    Supervisor.start_link(children, opts)
  end

  @impl true
  def config_change(changed, _new, removed) do
    CafeWeb.Endpoint.config_change(changed, removed)
    :ok
  end
end
