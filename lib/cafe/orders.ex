defmodule Cafe.Orders do
  @moduledoc """
  Order workflow context.

  Orders are placed through one transaction that calculates price snapshots,
  creates line items, decrements inventory, and announces the new ticket to
  real-time consumers.
  """

  import Ecto.Query

  alias Cafe.Inventory
  alias Cafe.Menu.MenuItem
  alias Cafe.Orders.{Order, OrderLine}
  alias Cafe.Repo

  @topic "orders"

  def subscribe do
    Phoenix.PubSub.subscribe(Cafe.PubSub, @topic)
  end

  def list_open_orders do
    Order
    |> where([order], order.status in ^~w(queued preparing ready))
    |> order_by([order], asc: order.inserted_at)
    |> preload(:lines)
    |> Repo.all()
  end

  def recent_orders(limit \\ 25) do
    Order
    |> order_by([order], desc: order.inserted_at)
    |> limit(^limit)
    |> preload(:lines)
    |> Repo.all()
  end

  def get_order!(id) do
    Order
    |> Repo.get!(id)
    |> Repo.preload(:lines)
  end

  def place_order(order_attrs, line_attrs) when is_list(line_attrs) do
    multi =
      Ecto.Multi.new()
      |> Ecto.Multi.run(:items, fn repo, _changes -> hydrate_items(repo, line_attrs) end)
      |> Ecto.Multi.insert(:order, fn %{items: items} ->
        Order.changeset(%Order{}, Map.put(order_attrs, :total_cents, total_cents(items)))
      end)
      |> Ecto.Multi.run(:lines, fn repo, %{order: order, items: items} ->
        insert_lines(repo, order, items)
      end)
      |> Ecto.Multi.run(:inventory, fn repo, %{items: items} ->
        Inventory.consume_menu_items(repo, items)
      end)

    with {:ok, %{order: order}} <- Repo.transaction(multi) do
      order = get_order!(order.id)

      :telemetry.execute(
        [:cafe, :order, :placed],
        %{count: 1, total_cents: order.total_cents},
        %{order_id: order.id, source: order.source}
      )

      broadcast({:order_placed, order})
      {:ok, order}
    end
  end

  def update_status(%Order{} = order, status) when status in ~w(queued preparing ready completed canceled) do
    attrs =
      if status in ~w(completed canceled) do
        %{status: status, completed_at: DateTime.utc_now() |> DateTime.truncate(:second)}
      else
        %{status: status, completed_at: nil}
      end

    order
    |> Order.status_changeset(attrs)
    |> Repo.update()
    |> case do
      {:ok, order} ->
        order = Repo.preload(order, :lines)
        broadcast({:order_updated, order})
        {:ok, order}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def daily_summary(date \\ Date.utc_today()) do
    start_at = DateTime.new!(date, ~T[00:00:00], "Etc/UTC")
    end_at = DateTime.add(start_at, 1, :day)

    Repo.one(
      from order in Order,
        where: order.inserted_at >= ^start_at and order.inserted_at < ^end_at,
        select: %{
          order_count: count(order.id),
          revenue_cents: coalesce(sum(order.total_cents), 0)
        }
    )
  end

  defp hydrate_items(_repo, []), do: {:error, :empty_order}

  defp hydrate_items(repo, line_attrs) do
    normalized =
      Enum.map(line_attrs, fn attrs ->
        attrs = Map.new(attrs)
        menu_item_id = Map.get(attrs, :menu_item_id) || Map.get(attrs, "menu_item_id")
        quantity = attrs |> Map.get(:quantity, Map.get(attrs, "quantity", 1)) |> parse_quantity()

        %{
          menu_item_id: menu_item_id,
          quantity: quantity,
          notes: Map.get(attrs, :notes) || Map.get(attrs, "notes")
        }
      end)

    item_ids = Enum.map(normalized, & &1.menu_item_id)

    menu_items =
      MenuItem
      |> where([item], item.id in ^item_ids and item.active)
      |> repo.all()
      |> Map.new(&{&1.id, &1})

    normalized
    |> Enum.map(fn line -> Map.put(line, :menu_item, menu_items[line.menu_item_id]) end)
    |> validate_hydrated_items()
  end

  defp validate_hydrated_items(items) do
    cond do
      Enum.any?(items, &is_nil(&1.menu_item)) ->
        {:error, :menu_item_not_found}

      Enum.any?(items, &(!is_integer(&1.quantity) or &1.quantity < 1)) ->
        {:error, :invalid_quantity}

      true ->
        {:ok, items}
    end
  end

  defp parse_quantity(quantity) when is_integer(quantity), do: quantity

  defp parse_quantity(quantity) when is_binary(quantity) do
    case Integer.parse(quantity) do
      {quantity, ""} -> quantity
      _ -> :invalid
    end
  end

  defp parse_quantity(_quantity), do: :invalid

  defp insert_lines(repo, order, items) do
    now = DateTime.utc_now() |> DateTime.truncate(:second)

    rows =
      Enum.map(items, fn item ->
        %{
          order_id: order.id,
          menu_item_id: item.menu_item.id,
          item_name: item.menu_item.name,
          quantity: item.quantity,
          unit_price_cents: item.menu_item.price_cents,
          line_total_cents: item.menu_item.price_cents * item.quantity,
          notes: item.notes,
          inserted_at: now,
          updated_at: now
        }
      end)

    {_count, lines} = repo.insert_all(OrderLine, rows, returning: true)
    {:ok, lines}
  end

  defp total_cents(items) do
    Enum.reduce(items, 0, fn item, total ->
      total + item.menu_item.price_cents * item.quantity
    end)
  end

  defp broadcast(message) do
    Phoenix.PubSub.broadcast(Cafe.PubSub, @topic, message)
  end
end
