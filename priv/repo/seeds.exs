alias Cafe.Inventory
alias Cafe.Inventory.{Ingredient, RecipeItem}
alias Cafe.Menu
alias Cafe.Orders.{Order, OrderLine}
alias Cafe.Repo

Repo.delete_all(OrderLine)
Repo.delete_all(Order)
Repo.delete_all(RecipeItem)

Repo.delete_all(Cafe.Menu.MenuItem)
Repo.delete_all(Ingredient)

{:ok, espresso_beans} =
  Inventory.create_ingredient(%{
    cost_per_unit_cents: 3,
    name: "Espresso beans",
    on_hand: "5000",
    par_level: "1200",
    unit: "g"
  })

{:ok, milk} =
  Inventory.create_ingredient(%{
    cost_per_unit_cents: 1,
    name: "Whole milk",
    on_hand: "12000",
    par_level: "3000",
    unit: "ml"
  })

{:ok, oat_milk} =
  Inventory.create_ingredient(%{
    cost_per_unit_cents: 2,
    name: "Oat milk",
    on_hand: "6000",
    par_level: "1800",
    unit: "ml"
  })

{:ok, croissant} =
  Inventory.create_ingredient(%{
    cost_per_unit_cents: 120,
    name: "Butter croissant",
    on_hand: "24",
    par_level: "8",
    unit: "unit"
  })

{:ok, latte} =
  Menu.create_menu_item(%{
    category: "coffee",
    description: "Double espresso with steamed milk.",
    name: "House Latte",
    prep_seconds: 210,
    price_cents: 475,
    sku: "LATTE"
  })

{:ok, flat_white} =
  Menu.create_menu_item(%{
    category: "coffee",
    description: "Velvety double espresso with a shorter milk pour.",
    name: "Flat White",
    prep_seconds: 190,
    price_cents: 450,
    sku: "FLATWHITE"
  })

{:ok, pastry} =
  Menu.create_menu_item(%{
    category: "food",
    description: "Baked fresh each morning.",
    name: "Butter Croissant",
    prep_seconds: 60,
    price_cents: 325,
    sku: "CROISSANT"
  })

{:ok, _} = Inventory.attach_ingredient(latte, espresso_beans, %{quantity: "18"})
{:ok, _} = Inventory.attach_ingredient(latte, milk, %{quantity: "220"})
{:ok, _} = Inventory.attach_ingredient(flat_white, espresso_beans, %{quantity: "18"})
{:ok, _} = Inventory.attach_ingredient(flat_white, oat_milk, %{quantity: "180"})
{:ok, _} = Inventory.attach_ingredient(pastry, croissant, %{quantity: "1"})
