defmodule Cafe.Inventory.Ingredient do
  @moduledoc """
  Stocked ingredient used by recipes.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cafe.Inventory.RecipeItem

  @units ~w(g kg ml l unit shot)

  schema "ingredients" do
    field :active, :boolean, default: true
    field :cost_per_unit_cents, :integer
    field :name, :string
    field :on_hand, :decimal
    field :par_level, :decimal
    field :unit, :string

    has_many :recipe_items, RecipeItem

    timestamps(type: :utc_datetime)
  end

  def units, do: @units

  def changeset(ingredient, attrs) do
    ingredient
    |> cast(attrs, [:active, :cost_per_unit_cents, :name, :on_hand, :par_level, :unit])
    |> validate_required([:cost_per_unit_cents, :name, :on_hand, :par_level, :unit])
    |> validate_inclusion(:unit, @units)
    |> validate_number(:cost_per_unit_cents, greater_than_or_equal_to: 0)
    |> validate_number(:on_hand, greater_than_or_equal_to: 0)
    |> validate_number(:par_level, greater_than_or_equal_to: 0)
    |> unique_constraint(:name)
  end
end
