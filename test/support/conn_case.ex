defmodule CafeWeb.ConnCase do
  @moduledoc """
  Shared setup for tests that require a connection.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      @endpoint CafeWeb.Endpoint

      use CafeWeb, :verified_routes

      import Plug.Conn
      import Phoenix.ConnTest
      import CafeWeb.ConnCase
    end
  end

  setup tags do
    Cafe.DataCase.setup_sandbox(tags)
    {:ok, conn: Phoenix.ConnTest.build_conn()}
  end
end
