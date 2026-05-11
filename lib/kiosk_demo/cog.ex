defmodule KioskDemo.Cog do
  @moduledoc """
  D-Bus client for the Cog browser.

  Cog exports an `org.gtk.Actions` action group on the session bus at
  `com.igalia.Cog` / `/com/igalia/Cog`. Calling
  `org.gtk.Actions.Activate(name, params, platform_data)` triggers actions
  registered by `cog-launcher.c`: `open` (URL), `previous`, `next`, `reload`,
  `quit`.

  See `cogctl(1)` and the source at `launcher/cogctl.c` in the Cog repo.
  """

  require Record

  Record.defrecordp(:dbus_variant, :dbus_variant, type: :string, value: "")

  @service "com.igalia.Cog"
  @path "/com/igalia/Cog"
  @actions_iface "org.gtk.Actions"
  @peer_iface "org.freedesktop.DBus.Peer"

  @spec open_url(String.t()) :: :ok | {:error, term()}
  def open_url(url) when is_binary(url) do
    activate("open", [variant(:string, url)])
  end

  @spec back() :: :ok | {:error, term()}
  def back(), do: activate("previous", [])

  @spec forward() :: :ok | {:error, term()}
  def forward(), do: activate("next", [])

  @spec reload() :: :ok | {:error, term()}
  def reload(), do: activate("reload", [])

  @spec quit() :: :ok | {:error, term()}
  def quit(), do: activate("quit", [])

  @spec ping() :: :ok | {:error, term()}
  def ping(), do: call(@peer_iface, "Ping", [])

  defp activate(action_name, params) when is_binary(action_name) and is_list(params) do
    call(@actions_iface, "Activate", [action_name, params, %{}])
  end

  # The bus, service, and object proxies are cached gen_servers — keep them
  # alive across calls. Releasing the object stops the service, which then
  # leaves a stale pid in dbus_bus_reg's cache for the next call.
  defp call(iface_name, method_name, args) do
    with {:ok, bus} <- :dbus_bus_reg.get_bus(:session),
         {:ok, service} <- :dbus_bus.get_service(bus, @service),
         {:ok, proxy} <- :dbus_remote_service.get_object(service, @path) do
      normalize(:dbus_proxy.call(proxy, iface_name, method_name, args))
    end
  end

  defp variant(type, value), do: dbus_variant(type: type, value: value)

  defp normalize(:ok), do: :ok
  defp normalize({:ok, _}), do: :ok
  defp normalize({:error, _} = err), do: err
end
