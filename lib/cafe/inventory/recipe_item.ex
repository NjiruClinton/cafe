defmodule Cafe.Inventory.RecipeItem do
  @moduledoc """
  Ingredient quantity required to prepare one menu item.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cafe.Inventory.Ingredient
  alias Cafe.Menu.MenuItem

  schema "recipe_items" do
    field :quantity, :decimal

    belongs_to :ingredient, Ingredient
    belongs_to :menu_item, MenuItem

    timestamps(type: :utc_datetime)
  end

  def changeset(recipe_item, attrs) do
    recipe_item
    |> cast(attrs, [:ingredient_id, :menu_item_id, :quantity])
    |> validate_required([:ingredient_id, :menu_item_id, :quantity])
    |> validate_number(:quantity, greater_than: 0)
    |> foreign_key_constraint(:ingredient_id)
    |> foreign_key_constraint(:menu_item_id)
    |> unique_constraint([:menu_item_id, :ingredient_id])
  end
end
