defmodule WebWeb.PageController do
  use WebWeb, :controller

  def home(conn, _params) do
    # The home page is often custom made,
    # so skip the default app layout.
    conn = assign(conn, :page_title, "Scanner Pipeline")
    render(conn, :home, layout: false)
  end
end
