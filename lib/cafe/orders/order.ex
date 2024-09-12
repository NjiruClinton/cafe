defmodule Cafe.Orders.Order do
  @moduledoc """
  Customer order and its workflow status.
  """

  use Ecto.Schema
  import Ecto.Changeset

  alias Cafe.Orders.OrderLine

  @statuses ~w(queued preparing ready completed canceled)
  @sources ~w(counter phone delivery)

  schema "orders" do
    field :completed_at, :utc_datetime
    field :customer_name, :string
    field :notes, :string
    field :source, :string, default: "counter"
    field :status, :string, default: "queued"
    field :total_cents, :integer, default: 0

    has_many :lines, OrderLine

    timestamps(type: :utc_datetime)
  end

  def statuses, do: @statuses
  def sources, do: @sources

  def changeset(order, attrs) do
    order
    |> cast(attrs, [:customer_name, :notes, :source, :status, :total_cents])
    |> validate_required([:customer_name, :source, :status, :total_cents])
    |> validate_inclusion(:status, @statuses)
    |> validate_inclusion(:source, @sources)
    |> validate_number(:total_cents, greater_than_or_equal_to: 0)
  end

  def status_changeset(order, attrs) do
    order
    |> cast(attrs, [:completed_at, :status])
    |> validate_required([:status])
    |> validate_inclusion(:status, @statuses)
  end
end
