defmodule KioskDemo.WaylandAppsSupervisor do
  @moduledoc false
  use Supervisor

  @runtime_dir "/run"
  @wayland_display "wayland-1"
  @wayland_socket_poll_ms 500
  @wayland_socket_max_retries 20

  @spec start_link(keyword()) :: Supervisor.on_start()
  def start_link(args) do
    Supervisor.start_link(__MODULE__, args, name: __MODULE__)
  end

  @impl Supervisor
  def init(_args) do
    weston_env = [{"XDG_RUNTIME_DIR", @runtime_dir}]

    cog_env = [
      {"XDG_RUNTIME_DIR", @runtime_dir},
      {"WAYLAND_DISPLAY", @wayland_display}
    ]

    wayland_socket = Path.join(@runtime_dir, @wayland_display)

    children = [
      Supervisor.child_spec(
        {MuonTrap.Daemon,
         [
           "weston",
           ["--shell=kiosk", "--continue-without-input"],
           [
             env: weston_env,
             stderr_to_stdout: true,
             log_output: :info,
             log_prefix: "weston: "
           ]
         ]},
        id: :weston
      ),
      Supervisor.child_spec(
        {MuonTrap.Daemon,
         [
           "cog",
           ["--platform=wl", "http://localhost:4000/"],
           [
             env: cog_env,
             stderr_to_stdout: true,
             log_output: :info,
             log_prefix: "cog: ",
             wait_for: fn -> wait_for_path(wayland_socket) end
           ]
         ]},
        id: :cog
      )
    ]

    Supervisor.init(children, strategy: :rest_for_one)
  end

  defp wait_for_path(path, retries \\ @wayland_socket_max_retries)

  defp wait_for_path(path, 0),
    do: raise(RuntimeError, "#{path} did not appear in time")

  defp wait_for_path(path, retries) do
    if File.exists?(path) do
      :ok
    else
      Process.sleep(@wayland_socket_poll_ms)
      wait_for_path(path, retries - 1)
    end
  end
end
