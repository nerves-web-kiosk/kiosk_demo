defmodule KioskDemo.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Nerves.Runtime.KV

  @impl Application
  def start(_type, _args) do
    setup_wifi()

    children =
      [
        # Children for all targets
        # Starts a worker by calling: KioskDemo.Worker.start_link(arg)
        # {KioskDemo.Worker, arg},
      ] ++ phoenix_children() ++ children()

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: KioskDemo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  # List all child processes to be supervised
  if Mix.target() == :host do
    defp children() do
      [
        # Children that only run on the host
        # Starts a worker by calling: KioskDemo.Worker.start_link(arg)
        # {KioskDemo.Worker, arg},
      ]
    end
  else
    defp children() do
      # NOTE: work around to stop watchers on targets
      Application.get_env(:kiosk_demo, KioskDemoWeb.Endpoint)
      |> Keyword.put(:watchers, [])
      |> then(&Application.put_env(:kiosk_demo, KioskDemoWeb.Endpoint, &1))

      start_node()

      [
        # Children for all targets except host
        # Starts a worker by calling: KioskDemo.Worker.start_link(arg)
        # {KioskDemo.Worker, arg},
        {KioskDemo.DisplaySupervisor, []}
      ]
    end

    defp start_node() do
      {_, 0} = System.cmd("epmd", ~w"-daemon")
      _ = Node.start(:"kiosk_demo@nerves.local")
      Node.set_cookie(Application.get_env(:mix_tasks_upload_hotswap, :cookie))
    end
  end

  defp phoenix_children() do
    [
      KioskDemoWeb.Telemetry,
      {DNSCluster, query: Application.get_env(:kiosk_demo, :dns_cluster_query) || :ignore},
      {Phoenix.PubSub, name: KioskDemo.PubSub},
      # Start a worker by calling: KioskDemo.Worker.start_link(arg)
      # {KioskDemo.Worker, arg},
      # Start to serve requests, typically the last entry
      KioskDemoWeb.Endpoint
    ]
  end

  if Mix.target() == :host do
    defp setup_wifi() do
      :ok
    end
  else
    defp setup_wifi() do
      kv = KV.get_all()

      if true?(kv["wifi_force"]) or not wlan0_configured?() do
        ssid = kv["wifi_ssid"]
        passphrase = kv["wifi_passphrase"]

        if not empty?(ssid) do
          _ = VintageNetWiFi.quick_configure(ssid, passphrase)
          :ok
        end
      end
    end

    defp wlan0_configured?() do
      VintageNet.get_configuration("wlan0") |> VintageNetWiFi.network_configured?()
    catch
      _, _ -> false
    end

    defp true?(""), do: false
    defp true?(nil), do: false
    defp true?("false"), do: false
    defp true?("FALSE"), do: false
    defp true?(_), do: true

    defp empty?(""), do: true
    defp empty?(nil), do: true
    defp empty?(_), do: false
  end
end
