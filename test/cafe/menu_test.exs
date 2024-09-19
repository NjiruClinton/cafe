defmodule Cafe.MenuTest do
  use Cafe.DataCase, async: true

  alias Cafe.Menu
  alias Cafe.Menu.MenuItem

  describe "create_menu_item/1" do
    test "validates required commercial fields" do
      assert {:error, changeset} = Menu.create_menu_item(%{})

      assert %{
               category: ["can't be blank"],
               name: ["can't be blank"],
               price_cents: ["can't be blank"],
               sku: ["can't be blank"]
             } = errors_on(changeset)
    end

    test "accepts a valid coffee item" do
      assert {:ok, %MenuItem{} = item} =
               Menu.create_menu_item(%{
                 category: "coffee",
                 name: "Batch Brew",
                 prep_seconds: 90,
                 price_cents: 300,
                 sku: "BREW"
               })

      assert item.active
      assert item.price_cents == 300
    end
  end
end
