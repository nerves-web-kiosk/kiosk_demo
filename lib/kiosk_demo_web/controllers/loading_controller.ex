defmodule KioskDemoWeb.LoadingController do
  @moduledoc false
  use KioskDemoWeb, :controller

  @safe_schemes ~w(http https)

  def show(conn, %{"next" => next}) when is_binary(next) do
    if safe?(next) do
      conn
      |> put_resp_content_type("text/html")
      |> send_resp(200, render_html(next))
    else
      send_resp(conn, 400, "invalid `next` URL")
    end
  end

  def show(conn, _params), do: send_resp(conn, 400, "missing `next`")

  defp safe?(url) do
    case URI.parse(url) do
      %URI{scheme: s, host: h} when s in @safe_schemes and is_binary(h) -> true
      _ -> false
    end
  end

  defp render_html(next) do
    """
    <!doctype html>
    <html>
    <head>
      <meta charset="utf-8">
      <title>Loading…</title>
      <style>
        html, body { margin: 0; height: 100%; background: #111; color: #eee;
          font-family: system-ui, sans-serif; overflow: hidden; }
        body { display: flex; align-items: center; justify-content: center; }
        .label { font-size: 3rem; font-weight: 300; letter-spacing: 0.05em; }
      </style>
    </head>
    <body>
      <div class="label">Loading…</div>
      <script>
        window.addEventListener('load', function() {
          requestAnimationFrame(function() {
            window.location.replace(#{Jason.encode!(next)});
          });
        });
      </script>
    </body>
    </html>
    """
  end
end
