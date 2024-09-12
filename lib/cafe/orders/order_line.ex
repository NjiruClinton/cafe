defmodule Cafe.Orders.OrderLine do
  @moduledoc """
  Immutable price and menu snapshots for a placed order.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cafe.Menu.MenuItem
  alias Cafe.Orders.Order

  schema "order_lines" do
    field :item_name, :string
    field :line_total_cents, :integer
    field :notes, :string
    field :quantity, :integer
    field :unit_price_cents, :integer

    belongs_to :menu_item, MenuItem
    belongs_to :order, Order

    timestamps(type: :utc_datetime)
  end

  def changeset(order_line, attrs) do
    order_line
    |> cast(attrs, [
      :item_name,
      :line_total_cents,
      :menu_item_id,
      :notes,
      :order_id,
      :quantity,
      :unit_price_cents
    ])
    |> validate_required([
      :item_name,
      :line_total_cents,
      :menu_item_id,
      :order_id,
      :quantity,
      :unit_price_cents
    ])
    |> validate_number(:quantity, greater_than: 0)
    |> validate_number(:unit_price_cents, greater_than_or_equal_to: 0)
    |> validate_number(:line_total_cents, greater_than_or_equal_to: 0)
    |> foreign_key_constraint(:menu_item_id)
    |> foreign_key_constraint(:order_id)
  end
end
