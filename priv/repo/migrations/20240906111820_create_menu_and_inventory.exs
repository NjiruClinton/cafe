defmodule Cafe.Repo.Migrations.CreateMenuAndInventory do
  use Ecto.Migration

  def change do
    create table(:menu_items) do
      add :active, :boolean, null: false, default: true
      add :category, :string, null: false
      add :description, :text
      add :name, :string, null: false
      add :prep_seconds, :integer, null: false, default: 180
      add :price_cents, :integer, null: false
      add :sku, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:menu_items, [:sku])
    create index(:menu_items, [:active, :category])

    create constraint(:menu_items, :price_cents_must_be_non_negative,
             check: "price_cents >= 0"
           )

    create constraint(:menu_items, :prep_seconds_must_be_positive,
             check: "prep_seconds > 0"
           )

    create table(:ingredients) do
      add :active, :boolean, null: false, default: true
      add :cost_per_unit_cents, :integer, null: false
      add :name, :string, null: false
      add :on_hand, :decimal, precision: 10, scale: 3, null: false
      add :par_level, :decimal, precision: 10, scale: 3, null: false
      add :unit, :string, null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:ingredients, [:name])
    create index(:ingredients, [:active])

    create constraint(:ingredients, :on_hand_must_be_non_negative,
             check: "on_hand >= 0"
           )

    create constraint(:ingredients, :par_level_must_be_non_negative,
             check: "par_level >= 0"
           )

    create table(:recipe_items) do
      add :quantity, :decimal, precision: 10, scale: 3, null: false
      add :ingredient_id, references(:ingredients, on_delete: :delete_all), null: false
      add :menu_item_id, references(:menu_items, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create unique_index(:recipe_items, [:menu_item_id, :ingredient_id])
    create index(:recipe_items, [:ingredient_id])

    create constraint(:recipe_items, :quantity_must_be_positive,
             check: "quantity > 0"
           )
  end
end
