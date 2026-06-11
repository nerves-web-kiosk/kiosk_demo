defmodule KioskDemo.KioskSupervisor do
  @moduledoc false
  use Supervisor

  @runtime_dir "/run"
  @wayland_display "wayland-1"
  @poll_ms 500
  @max_retries 20
  @dbus_socket_path "/run/dbus-session-bus"
  @dbus_session_bus_address "unix:path=#{@dbus_socket_path}"
  @inspector_address "0.0.0.0:9222"

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @doc """
  Enable the WPE WebKit remote inspector and restart Cog.

  Exposes the inspector on `#{@inspector_address}`. Browse to
  `http://<device>:9222/` from another machine to attach DevTools.
  Not persisted across reboots.
  """
  @spec enable_inspector() :: :ok | {:error, term()}
  def enable_inspector() do
    Application.put_env(:kiosk_demo, :remote_inspector, true)
    restart_cog()
  end

  @doc """
  Disable the remote inspector and restart Cog.
  """
  @spec disable_inspector() :: :ok | {:error, term()}
  def disable_inspector() do
    Application.put_env(:kiosk_demo, :remote_inspector, false)
    restart_cog()
  end

  defp restart_cog() do
    with :ok <- Supervisor.terminate_child(__MODULE__, :cog),
         :ok <- Supervisor.delete_child(__MODULE__, :cog),
         {:ok, _pid} <- start_cog() do
      :ok
    end
  end

  defp start_cog() do
    case Supervisor.start_child(__MODULE__, cog_child_spec()) do
      {:ok, pid, _info} -> {:ok, pid}
      other -> other
    end
  end

  @impl Supervisor
  def init(_args) do
    cgroup_status = KioskDemo.SystemSetup.setup!()
    :persistent_term.put({__MODULE__, :cgroup_status}, cgroup_status)
    System.put_env("DBUS_SESSION_BUS_ADDRESS", @dbus_session_bus_address)

    weston_env = [{"XDG_RUNTIME_DIR", @runtime_dir}]

    dbus_config_path = Application.app_dir(:kiosk_demo, "priv/dbus-session.conf")

    children = [
      Supervisor.child_spec(
        {MuonTrap.Daemon,
         [
           "dbus-daemon",
           [
             "--config-file=#{dbus_config_path}",
             "--nofork"
           ],
           [
             name: KioskDemo.DBusDaemon,
             stderr_to_stdout: true,
             log_output: :info,
             log_prefix: "dbus: "
           ]
         ]},
        id: :dbus
      ),
      Supervisor.child_spec(
        {MuonTrap.Daemon,
         [
           "weston",
           ["--shell=kiosk", "--continue-without-input"],
           [
             name: KioskDemo.WestonDaemon,
             env: weston_env,
             stderr_to_stdout: true,
             log_output: :info,
             log_prefix: "weston: ",
             wait_for: fn ->
               wait_for_ready_card()
             end
           ]
         ]},
        id: :weston
      ),
      cog_child_spec()
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp cog_child_spec() do
    cgroup_status = :persistent_term.get({__MODULE__, :cgroup_status})
    wayland_socket = Path.join(@runtime_dir, @wayland_display)

    Supervisor.child_spec(
      {MuonTrap.Daemon,
       [
         "cog",
         ["--platform=wl", "http://localhost:4000/"],
         cog_opts(cgroup_status, build_cog_env(), wayland_socket)
       ]},
      id: :cog
    )
  end

  defp build_cog_env() do
    base = [
      {"XDG_RUNTIME_DIR", @runtime_dir},
      {"WAYLAND_DISPLAY", @wayland_display},
      {"DBUS_SESSION_BUS_ADDRESS", @dbus_session_bus_address},
      {"HOME", KioskDemo.SystemSetup.cog_home()}
    ]

    if Application.get_env(:kiosk_demo, :remote_inspector, false) do
      base ++ [{"WEBKIT_INSPECTOR_HTTP_SERVER", @inspector_address}]
    else
      base
    end
  end

  defp cog_opts(cgroup_status, cog_env, wayland_socket) do
    base = [
      name: KioskDemo.CogDaemon,
      env: cog_env,
      stderr_to_stdout: true,
      log_output: :info,
      log_prefix: "cog: ",
      uid: "www-data",
      gid: "www-data",
      groups: ["video", "input"],
      wait_for: fn ->
        wait_for_socket(@dbus_socket_path)
        wait_for_socket(wayland_socket)
      end
    ]

    case cgroup_status do
      :cgroups -> base ++ cog_cgroup_opts()
      :no_cgroups -> base
    end
  end

  defp cog_cgroup_opts() do
    [
      cgroup_base: KioskDemo.SystemSetup.parent_cgroup(),
      cgroup: %{
        cpu_weight: 50,
        memory_max: KioskDemo.SystemSetup.cog_memory_limit(),
        memory_oom_group: true,
        pids_max: 200
      }
    ]
  end

  defp wait_for_path(path, retries \\ @max_retries)

  defp wait_for_path(path, 0),
    do: raise(RuntimeError, "#{path} did not appear in time")

  defp wait_for_path(path, retries) do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(@poll_ms)
      wait_for_path(path, retries - 1)
    end
  end

  # weston (mode 0700) and dbus-daemon (mode 0600) create their sockets
  # with restrictive perms. Cog runs as a non-root uid, so loosen them
  # once they appear.
  defp wait_for_socket(path) do
    wait_for_path(path)
    File.chmod!(path, 0o666)
  end

  defp wait_for_ready_card(retries \\ @max_retries)

  defp wait_for_ready_card(0),
    do: raise(RuntimeError, "no DRM card became ready in time")

  defp wait_for_ready_card(retries) do
    case find_ready_card() do
      {:ok, _path} ->
        :ok

      :not_ready ->
        Process.sleep(@poll_ms)
        wait_for_ready_card(retries - 1)
    end
  end

  defp find_ready_card() do
    Path.wildcard("/sys/class/drm/card[0-9]-*")
    |> Enum.find_value(:not_ready, fn conn ->
      if connector_ready?(conn) do
        card = conn |> Path.basename() |> String.split("-", parts: 2) |> hd()
        {:ok, "/dev/dri/" <> card}
      end
    end)
  end

  defp connector_ready?(conn) do
    case File.read(Path.join(conn, "status")) do
      {:ok, s} when s in ["connected\n", "disconnected\n", "unknown\n"] -> true
      _ -> false
    end
  end
end
