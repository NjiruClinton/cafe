defmodule Cafe.OrdersTest do
  use Cafe.DataCase

  alias Cafe.Inventory
  alias Cafe.Inventory.Ingredient
  alias Cafe.Menu
  alias Cafe.Orders
  alias Cafe.Orders.Order
  alias Cafe.Repo

  setup do
    {:ok, beans} =
      Inventory.create_ingredient(%{
        cost_per_unit_cents: 3,
        name: "Test espresso beans",
        on_hand: "40",
        par_level: "10",
        unit: "g"
      })

    {:ok, latte} =
      Menu.create_menu_item(%{
        category: "coffee",
        name: "Test Latte",
        prep_seconds: 180,
        price_cents: 500,
        sku: "TEST-LATTE"
      })

    {:ok, _recipe} = Inventory.attach_ingredient(latte, beans, %{quantity: "18"})

    %{beans: beans, latte: latte}
  end

  test "place_order/2 snapshots prices and decrements inventory", %{beans: beans, latte: latte} do
    Orders.subscribe()

    assert {:ok, %Order{} = order} =
             Orders.place_order(
               %{customer_name: "Amina", source: "counter"},
               [%{menu_item_id: latte.id, quantity: 2}]
             )

    assert order.total_cents == 1000
    assert [%{item_name: "Test Latte", quantity: 2, line_total_cents: 1000}] = order.lines

    beans = Repo.get!(Ingredient, beans.id)
    assert Decimal.equal?(beans.on_hand, Decimal.new("4.000"))

    assert_receive {:order_placed, %Order{id: order_id}}
    assert order_id == order.id
  end

  test "place_order/2 rejects orders that exceed stock", %{latte: latte} do
    assert {:error, :inventory, {:out_of_stock, "Test espresso beans"}, _changes} =
             Orders.place_order(
               %{customer_name: "Nia", source: "counter"},
               [%{menu_item_id: latte.id, quantity: 3}]
             )
  end

  test "update_status/2 broadcasts order changes", %{latte: latte} do
    {:ok, order} =
      Orders.place_order(
        %{customer_name: "Sam", source: "counter"},
        [%{menu_item_id: latte.id, quantity: 1}]
      )

    Orders.subscribe()

    assert {:ok, %Order{status: "preparing"} = order} = Orders.update_status(order, "preparing")
    assert_receive {:order_updated, %Order{id: order_id, status: "preparing"}}
    assert order_id == order.id
  end
end
