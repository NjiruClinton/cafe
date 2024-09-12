defmodule Cafe.Inventory do
  @moduledoc """
  Inventory and recipe context.

  The functions in this context prefer explicit quantities over boolean flags so
  callers can use the same API for both single drinks and batch orders.
  """

  import Ecto.Query

  alias Cafe.Inventory.{Ingredient, RecipeItem}
  alias Cafe.Menu.MenuItem
  alias Cafe.Repo

  def list_ingredients do
    Ingredient
    |> order_by([ingredient], asc: ingredient.name)
    |> Repo.all()
  end

  def low_stock_ingredients do
    Ingredient
    |> where([ingredient], ingredient.active and ingredient.on_hand <= ingredient.par_level)
    |> order_by([ingredient], asc: ingredient.name)
    |> Repo.all()
  end

  def get_ingredient!(id), do: Repo.get!(Ingredient, id)

  def create_ingredient(attrs) do
    %Ingredient{}
    |> Ingredient.changeset(attrs)
    |> Repo.insert()
  end

  def update_ingredient(%Ingredient{} = ingredient, attrs) do
    ingredient
    |> Ingredient.changeset(attrs)
    |> Repo.update()
  end

  def change_ingredient(%Ingredient{} = ingredient, attrs \\ %{}) do
    Ingredient.changeset(ingredient, attrs)
  end

  def attach_ingredient(%MenuItem{} = item, %Ingredient{} = ingredient, attrs) do
    attrs =
      attrs
      |> Map.new()
      |> Map.put(:menu_item_id, item.id)
      |> Map.put(:ingredient_id, ingredient.id)

    %RecipeItem{}
    |> RecipeItem.changeset(attrs)
    |> Repo.insert()
  end

  def recipe_for_menu_item(menu_item_id) do
    RecipeItem
    |> where([recipe_item], recipe_item.menu_item_id == ^menu_item_id)
    |> preload(:ingredient)
    |> order_by([recipe_item], asc: recipe_item.id)
    |> Repo.all()
  end

  def menu_item_available?(%MenuItem{} = item, quantity \\ 1) do
    item
    |> Repo.preload(recipe_items: :ingredient)
    |> Map.fetch!(:recipe_items)
    |> Enum.all?(fn recipe_item ->
      needed = Decimal.mult(recipe_item.quantity, Decimal.new(quantity))
      Decimal.compare(recipe_item.ingredient.on_hand, needed) in [:gt, :eq]
    end)
  end

  def consume_menu_items(repo, items) when is_list(items) do
    Enum.reduce_while(items, {:ok, []}, fn item, {:ok, consumed} ->
      case consume_menu_item(repo, item.menu_item.id, item.quantity) do
        {:ok, changes} -> {:cont, {:ok, changes ++ consumed}}
        {:error, reason} -> {:halt, {:error, reason}}
      end
    end)
  end

  defp consume_menu_item(repo, menu_item_id, quantity) do
    recipe_items =
      RecipeItem
      |> where([recipe_item], recipe_item.menu_item_id == ^menu_item_id)
      |> join(:inner, [recipe_item], ingredient in assoc(recipe_item, :ingredient))
      |> lock("FOR UPDATE")
      |> preload([_recipe_item, ingredient], ingredient: ingredient)
      |> repo.all()

    Enum.reduce_while(recipe_items, {:ok, []}, fn recipe_item, {:ok, consumed} ->
      required = Decimal.mult(recipe_item.quantity, Decimal.new(quantity))
      ingredient = recipe_item.ingredient

      if Decimal.compare(ingredient.on_hand, required) == :lt do
        {:halt, {:error, {:out_of_stock, ingredient.name}}}
      else
        new_on_hand = Decimal.sub(ingredient.on_hand, required)

        case ingredient |> Ingredient.changeset(%{on_hand: new_on_hand}) |> repo.update() do
          {:ok, updated} -> {:cont, {:ok, [{updated, required} | consumed]}}
          {:error, changeset} -> {:halt, {:error, changeset}}
        end
      end
    end)
  end
end
