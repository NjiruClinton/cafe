defmodule CafeWeb.OrderLive do
  use CafeWeb, :live_view

  alias Cafe.Menu
  alias Cafe.Orders

  @impl true
  def mount(_params, _session, socket) do
    menu_items = Menu.list_menu_items(active: true)

    {:ok,
     assign(socket,
       form: order_form(),
       menu_items: menu_items,
       page_title: "New order",
       recent_orders: Orders.recent_orders(8)
     )}
  end

  @impl true
  def handle_event("place_order", %{"order" => params}, socket) do
    order_attrs = %{
      customer_name: params["customer_name"],
      notes: params["notes"],
      source: "counter"
    }

    lines = [
      %{
        menu_item_id: params["menu_item_id"],
        notes: params["line_notes"],
        quantity: params["quantity"]
      }
    ]

    case Orders.place_order(order_attrs, lines) do
      {:ok, order} ->
        {:noreply,
         socket
         |> put_flash(:info, "Order ##{order.id} sent to the bar.")
         |> assign(form: order_form(), recent_orders: Orders.recent_orders(8))}

      {:error, _step, :empty_order, _changes} ->
        {:noreply, put_flash(socket, :error, "Choose at least one menu item.")}

      {:error, _step, {:out_of_stock, ingredient}, _changes} ->
        {:noreply, put_flash(socket, :error, "#{ingredient} is out of stock.")}

      {:error, _step, _reason, _changes} ->
        {:noreply, put_flash(socket, :error, "Could not place that order.")}
    end
  end

  defp order_form do
    Phoenix.Component.to_form(
      %{
        "customer_name" => "",
        "line_notes" => "",
        "menu_item_id" => "",
        "notes" => "",
        "quantity" => "1"
      },
      as: :order
    )
  end

  defp format_cents(cents) do
    dollars = div(cents, 100)
    remainder = cents |> rem(100) |> Integer.to_string() |> String.pad_leading(2, "0")
    "$#{dollars}.#{remainder}"
  end

  @impl true
  def render(assigns) do
    ~H"""
    <section class="mx-auto grid max-w-6xl gap-8 px-6 py-8 lg:grid-cols-[1fr_24rem]">
      <div>
        <p class="text-sm font-semibold uppercase tracking-wide text-amber-700">Counter</p>
        <h1 class="mt-2 text-3xl font-bold text-stone-950">Create an order</h1>

        <.form for={@form} phx-submit="place_order" class="mt-8 space-y-5 rounded-lg border border-stone-200 bg-white p-6 shadow-sm">
          <div>
            <label for={@form[:customer_name].id} class="block text-sm font-medium text-stone-800">
              Customer name
            </label>
            <input
              id={@form[:customer_name].id}
              name={@form[:customer_name].name}
              type="text"
              required
              class="mt-2 block w-full rounded-md border-stone-300 text-stone-950 shadow-sm focus:border-amber-600 focus:ring-amber-600"
            />
          </div>

          <div class="grid gap-5 sm:grid-cols-[1fr_8rem]">
            <div>
              <label for={@form[:menu_item_id].id} class="block text-sm font-medium text-stone-800">
                Menu item
              </label>
              <select
                id={@form[:menu_item_id].id}
                name={@form[:menu_item_id].name}
                required
                class="mt-2 block w-full rounded-md border-stone-300 text-stone-950 shadow-sm focus:border-amber-600 focus:ring-amber-600"
              >
                <option value="">Select item</option>
                <option :for={item <- @menu_items} value={item.id}>
                  <%= item.name %> - <%= format_cents(item.price_cents) %>
                </option>
              </select>
            </div>

            <div>
              <label for={@form[:quantity].id} class="block text-sm font-medium text-stone-800">
                Quantity
              </label>
              <input
                id={@form[:quantity].id}
                name={@form[:quantity].name}
                type="number"
                min="1"
                value="1"
                required
                class="mt-2 block w-full rounded-md border-stone-300 text-stone-950 shadow-sm focus:border-amber-600 focus:ring-amber-600"
              />
            </div>
          </div>

          <div>
            <label for={@form[:line_notes].id} class="block text-sm font-medium text-stone-800">
              Item notes
            </label>
            <input
              id={@form[:line_notes].id}
              name={@form[:line_notes].name}
              type="text"
              class="mt-2 block w-full rounded-md border-stone-300 text-stone-950 shadow-sm focus:border-amber-600 focus:ring-amber-600"
              placeholder="Oat milk, extra hot, no sugar"
            />
          </div>

          <div>
            <label for={@form[:notes].id} class="block text-sm font-medium text-stone-800">
              Order notes
            </label>
            <textarea
              id={@form[:notes].id}
              name={@form[:notes].name}
              rows="3"
              class="mt-2 block w-full rounded-md border-stone-300 text-stone-950 shadow-sm focus:border-amber-600 focus:ring-amber-600"
            ></textarea>
          </div>

          <button
            type="submit"
            disabled={@menu_items == []}
            class="rounded-md bg-stone-950 px-4 py-2.5 text-sm font-semibold text-white shadow-sm hover:bg-stone-800 disabled:cursor-not-allowed disabled:bg-stone-300"
          >
            Send to bar
          </button>
        </.form>
      </div>

      <aside>
        <h2 class="text-lg font-semibold text-stone-950">Recent orders</h2>
        <div class="mt-4 divide-y divide-stone-100 rounded-lg border border-stone-200 bg-white shadow-sm">
          <div :for={order <- @recent_orders} class="p-4">
            <div class="flex items-center justify-between">
              <p class="font-medium text-stone-950">#<%= order.id %> <%= order.customer_name %></p>
              <p class="text-sm font-semibold text-stone-700"><%= format_cents(order.total_cents) %></p>
            </div>
            <p class="mt-1 text-sm capitalize text-stone-500"><%= order.status %></p>
          </div>
          <div :if={@recent_orders == []} class="p-6 text-sm text-stone-600">
            No orders have been placed yet.
          </div>
        </div>
      </aside>
    </section>
    """
  end
end
