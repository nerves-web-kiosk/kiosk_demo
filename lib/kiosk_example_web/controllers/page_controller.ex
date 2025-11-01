defmodule KioskExampleWeb.PageController do
  use KioskExampleWeb, :controller

  def home(conn, _params) do
    render(conn, :home)
  end
end
