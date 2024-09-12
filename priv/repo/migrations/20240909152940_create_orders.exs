defmodule Cafe.Repo.Migrations.CreateOrders do
  use Ecto.Migration

  def change do
    create table(:orders) do
      add :completed_at, :utc_datetime
      add :customer_name, :string, null: false
      add :notes, :text
      add :source, :string, null: false, default: "counter"
      add :status, :string, null: false, default: "queued"
      add :total_cents, :integer, null: false, default: 0

      timestamps(type: :utc_datetime)
    end

    create index(:orders, [:status, :inserted_at])
    create index(:orders, [:inserted_at])

    create constraint(:orders, :total_cents_must_be_non_negative,
             check: "total_cents >= 0"
           )

    create table(:order_lines) do
      add :item_name, :string, null: false
      add :line_total_cents, :integer, null: false
      add :notes, :text
      add :quantity, :integer, null: false
      add :unit_price_cents, :integer, null: false
      add :menu_item_id, references(:menu_items), null: false
      add :order_id, references(:orders, on_delete: :delete_all), null: false

      timestamps(type: :utc_datetime)
    end

    create index(:order_lines, [:menu_item_id])
    create index(:order_lines, [:order_id])

    create constraint(:order_lines, :quantity_must_be_positive,
             check: "quantity > 0"
           )

    create constraint(:order_lines, :unit_price_cents_must_be_non_negative,
             check: "unit_price_cents >= 0"
           )

    create constraint(:order_lines, :line_total_cents_must_be_non_negative,
             check: "line_total_cents >= 0"
           )
  end
end
