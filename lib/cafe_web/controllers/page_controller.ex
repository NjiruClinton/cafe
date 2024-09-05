defmodule CafeWeb.PageController do
  use CafeWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
