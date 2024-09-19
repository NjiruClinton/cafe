defmodule Cafe.Kitchen.TicketBoard do
  @moduledoc """
  In-memory projection of active orders for the bar.

  The database remains the source of truth; this process gives LiveViews a cheap
  way to render and update a short-lived queue.
  """

  use GenServer

  alias Cafe.Orders.Order

  def start_link(opts) do
    name = Keyword.get(opts, :name, __MODULE__)
    GenServer.start_link(__MODULE__, %{}, name: name)
  end

  def tickets(server \\ __MODULE__) do
    GenServer.call(server, :tickets)
  end

  def acknowledge(order_id) do
    acknowledge(__MODULE__, order_id)
  end

  def acknowledge(server, order_id) do
    GenServer.cast(server, {:acknowledge, order_id})
  end

  @impl true
  def init(state) do
    Phoenix.PubSub.subscribe(Cafe.PubSub, "orders")
    {:ok, state}
  end

  @impl true
  def handle_call(:tickets, _from, state) do
    tickets =
      state
      |> Map.values()
      |> Enum.sort_by(& &1.inserted_at, DateTime)

    {:reply, tickets, state}
  end

  @impl true
  def handle_cast({:acknowledge, order_id}, state) do
    state =
      case Map.fetch(state, order_id) do
        {:ok, ticket} -> Map.put(state, order_id, %{ticket | acknowledged?: true})
        :error -> state
      end

    {:noreply, state}
  end

  @impl true
  def handle_info({:order_placed, %Order{} = order}, state) do
    {:noreply, Map.put(state, order.id, ticket_from_order(order))}
  end

  def handle_info({:order_updated, %Order{status: status} = order}, state)
      when status in ~w(completed canceled) do
    {:noreply, Map.delete(state, order.id)}
  end

  def handle_info({:order_updated, %Order{} = order}, state) do
    {:noreply, Map.put(state, order.id, ticket_from_order(order))}
  end

  def handle_info(_message, state), do: {:noreply, state}

  defp ticket_from_order(%Order{} = order) do
    %{
      acknowledged?: false,
      customer_name: order.customer_name,
      id: order.id,
      inserted_at: order.inserted_at,
      line_count: Enum.count(order.lines),
      lines: Enum.map(order.lines, &line_summary/1),
      status: order.status,
      total_cents: order.total_cents
    }
  end

  defp line_summary(line) do
    %{
      item_name: line.item_name,
      notes: line.notes,
      quantity: line.quantity
    }
  end
end
