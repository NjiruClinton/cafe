defmodule Cafe.Menu do
  @moduledoc """
  Menu catalog context.

  Menu items are intentionally separated from inventory so the shop can sell the
  same drink recipe at different sizes or prices without duplicating ingredient
  records.
  """

  import Ecto.Query

  alias Cafe.Menu.MenuItem
  alias Cafe.Repo

  def list_menu_items(opts \\ []) do
    active = Keyword.get(opts, :active)
    category = Keyword.get(opts, :category)

    MenuItem
    |> maybe_filter_active(active)
    |> maybe_filter_category(category)
    |> order_by([item], asc: item.category, asc: item.name)
    |> Repo.all()
  end

  def get_menu_item!(id), do: Repo.get!(MenuItem, id)

  def create_menu_item(attrs) do
    %MenuItem{}
    |> MenuItem.changeset(attrs)
    |> Repo.insert()
  end

  def update_menu_item(%MenuItem{} = item, attrs) do
    item
    |> MenuItem.changeset(attrs)
    |> Repo.update()
  end

  def change_menu_item(%MenuItem{} = item, attrs \\ %{}) do
    MenuItem.changeset(item, attrs)
  end

  defp maybe_filter_active(query, nil), do: query
  defp maybe_filter_active(query, active), do: where(query, [item], item.active == ^active)

  defp maybe_filter_category(query, nil), do: query
  defp maybe_filter_category(query, category), do: where(query, [item], item.category == ^category)
end
