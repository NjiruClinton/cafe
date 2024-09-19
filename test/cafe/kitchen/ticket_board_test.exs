defmodule Cafe.Kitchen.TicketBoardTest do
  use ExUnit.Case, async: true

  alias Cafe.Kitchen.TicketBoard
  alias Cafe.Orders.{Order, OrderLine}

  test "tracks active order events in insertion order" do
    {:ok, pid} = start_supervised({TicketBoard, name: :test_ticket_board})

    first_order = order(1, ~U[2024-09-12 09:30:00Z])
    second_order = order(2, ~U[2024-09-12 09:31:00Z])

    send(pid, {:order_placed, second_order})
    send(pid, {:order_placed, first_order})

    assert [%{id: 1}, %{id: 2}] = TicketBoard.tickets(pid)

    send(pid, {:order_updated, %{first_order | status: "completed"}})

    assert [%{id: 2}] = TicketBoard.tickets(pid)
  end

  defp order(id, inserted_at) do
    %Order{
      customer_name: "Customer #{id}",
      id: id,
      inserted_at: inserted_at,
      lines: [
        %OrderLine{item_name: "Latte", notes: nil, quantity: 1}
      ],
      status: "queued",
      total_cents: 500
    }
  end
end
