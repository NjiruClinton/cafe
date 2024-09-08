defmodule Cafe.Menu.MenuItem do
  @moduledoc """
  Sellable item shown to the counter team.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cafe.Inventory.RecipeItem
  alias Cafe.Orders.OrderLine

  @categories ~w(coffee tea food retail)

  schema "menu_items" do
    field :active, :boolean, default: true
    field :category, :string
    field :description, :string
    field :name, :string
    field :prep_seconds, :integer, default: 180
    field :price_cents, :integer
    field :sku, :string

    has_many :recipe_items, RecipeItem
    has_many :order_lines, OrderLine

    timestamps(type: :utc_datetime)
  end

  def categories, do: @categories

  def changeset(menu_item, attrs) do
    menu_item
    |> cast(attrs, [:active, :category, :description, :name, :prep_seconds, :price_cents, :sku])
    |> validate_required([:category, :name, :prep_seconds, :price_cents, :sku])
    |> validate_inclusion(:category, @categories)
    |> validate_number(:prep_seconds, greater_than: 0, less_than_or_equal_to: 1_800)
    |> validate_number(:price_cents, greater_than_or_equal_to: 0)
    |> unique_constraint(:sku)
  end
end
