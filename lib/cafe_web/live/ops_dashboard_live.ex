defmodule CafeWeb.OpsDashboardLive do
  use CafeWeb, :live_view

  alias Cafe.Inventory
  alias Cafe.Kitchen.TicketBoard
  alias Cafe.Orders

  @impl true
  def mount(_params, _session, socket) do
    if connected?(socket), do: Orders.subscribe()

    {:ok,
     socket
     |> assign(:page_title, "Operations")
     |> refresh()}
  end

  @impl true
  def handle_event("advance", %{"id" => id}, socket) do
    order = Orders.get_order!(id)

    case Orders.update_status(order, next_status(order.status)) do
      {:ok, _order} ->
        {:noreply, refresh(socket)}

      {:error, _changeset} ->
        {:noreply, put_flash(socket, :error, "Could not update that ticket.")}
    end
  end

  @impl true
  def handle_info({event, _order}, socket) when event in [:order_placed, :order_updated] do
    {:noreply, refresh(socket)}
  end

  defp refresh(socket) do
    assign(socket,
      low_stock: Inventory.low_stock_ingredients(),
      summary: Orders.daily_summary(),
      tickets: TicketBoard.tickets()
    )
  end

  defp next_status("queued"), do: "preparing"
  defp next_status("preparing"), do: "ready"
  defp next_status("ready"), do: "completed"
  defp next_status(status), do: status

  defp action_label("queued"), do: "Start"
  defp action_label("preparing"), do: "Ready"
  defp action_label("ready"), do: "Complete"
  defp action_label(_status), do: "Update"

  defp format_cents(nil), do: "$0.00"

  defp format_cents(cents) do
    dollars = div(cents, 100)
    remainder = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "$#{dollars}.#{remainder}"
  end

  defp stock_level(%{on_hand: on_hand, par_level: par_level}) do
    cond do
      Decimal.compare(on_hand, Decimal.new(0)) == :eq -> "out"
      Decimal.compare(on_hand, par_level) in [:lt, :eq] -> "low"
      true -> "ok"
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mx-auto max-w-6xl px-6 py-8">
      <div class="flex flex-col gap-6 md:flex-row md:items-end md:justify-between">
        <div>
          <p class="text-sm font-semibold uppercase tracking-wide text-amber-700">Live board</p>
          <h1 class="mt-2 text-3xl font-bold text-stone-950">Today at the counter</h1>
        </div>
        <dl class="grid grid-cols-2 gap-3 sm:grid-cols-3">
          <div class="rounded-lg border border-stone-200 bg-white p-4 shadow-sm">
            <dt class="text-xs font-medium uppercase tracking-wide text-stone-500">Orders</dt>
            <dd class="mt-2 text-2xl font-bold text-stone-950"><%= @summary.order_count %></dd>
          </div>
          <div class="rounded-lg border border-stone-200 bg-white p-4 shadow-sm">
            <dt class="text-xs font-medium uppercase tracking-wide text-stone-500">Revenue</dt>
            <dd class="mt-2 text-2xl font-bold text-stone-950"><%= format_cents(@summary.revenue_cents) %></dd>
          </div>
          <div class="rounded-lg border border-stone-200 bg-white p-4 shadow-sm">
            <dt class="text-xs font-medium uppercase tracking-wide text-stone-500">Low stock</dt>
            <dd class="mt-2 text-2xl font-bold text-stone-950"><%= Enum.count(@low_stock) %></dd>
          </div>
        </dl>
      </div>

      <div class="mt-8 grid gap-6 lg:grid-cols-[1fr_20rem]">
        <section>
          <div class="flex items-center justify-between">
            <h2 class="text-lg font-semibold text-stone-950">Active tickets</h2>
            <span class="text-sm text-stone-500"><%= Enum.count(@tickets) %> in queue</span>
          </div>

          <div class="mt-4 grid gap-4">
            <article
              :for={ticket <- @tickets}
              class="rounded-lg border border-stone-200 bg-white p-5 shadow-sm"
            >
              <div class="flex flex-col gap-4 sm:flex-row sm:items-start sm:justify-between">
                <div>
                  <p class="text-sm font-semibold text-stone-500">Order #<%= ticket.id %></p>
                  <h3 class="mt-1 text-xl font-bold text-stone-950"><%= ticket.customer_name %></h3>
                  <p class="mt-1 text-sm capitalize text-stone-600"><%= ticket.status %></p>
                </div>
                <button
                  :if={ticket.status in ~w(queued preparing ready)}
                  type="button"
                  phx-click="advance"
                  phx-value-id={ticket.id}
                  class="rounded-md bg-stone-950 px-3 py-2 text-sm font-semibold text-white hover:bg-stone-800"
                >
                  <%= action_label(ticket.status) %>
                </button>
              </div>

              <ul class="mt-5 divide-y divide-stone-100 text-sm">
                <li :for={line <- ticket.lines} class="flex justify-between gap-4 py-2">
                  <span class="font-medium text-stone-900">
                    <%= line.quantity %> x <%= line.item_name %>
                  </span>
                  <span class="text-stone-500"><%= line.notes %></span>
                </li>
              </ul>
            </article>

            <div :if={@tickets == []} class="rounded-lg border border-dashed border-stone-300 bg-white p-8 text-center">
              <p class="text-sm font-medium text-stone-600">No active tickets right now.</p>
            </div>
          </div>
        </section>

        <aside>
          <h2 class="text-lg font-semibold text-stone-950">Stock watch</h2>
          <div class="mt-4 divide-y divide-stone-100 rounded-lg border border-stone-200 bg-white shadow-sm">
            <div :for={ingredient <- @low_stock} class="p-4">
              <div class="flex items-center justify-between gap-3">
                <p class="font-medium text-stone-950"><%= ingredient.name %></p>
                <span class={[
                  "rounded-full px-2 py-1 text-xs font-semibold uppercase",
                  stock_level(ingredient) == "out" && "bg-rose-100 text-rose-800",
                  stock_level(ingredient) == "low" && "bg-amber-100 text-amber-800"
                ]}>
                  <%= stock_level(ingredient) %>
                </span>
              </div>
              <p class="mt-2 text-sm text-stone-600">
                <%= ingredient.on_hand %> <%= ingredient.unit %> on hand,
                par <%= ingredient.par_level %>
              </p>
            </div>
            <div :if={@low_stock == []} class="p-6 text-sm text-stone-600">
              Inventory is above par.
            </div>
          </div>
        </aside>
      </div>
    </section>
    """
  end
end
