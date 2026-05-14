defmodule KioskDemo.SystemSetup do
  @moduledoc false
  # Runtime fixup that prepares the system for running Cog as a non-root
  # user inside a cgroup. Called from `KioskDemo.KioskSupervisor.init/1`
  # before any MuonTrap.Daemon child starts.
  #
  # Steps:
  #   1. If /sys/fs/cgroup is a cgroup v2 unified hierarchy, enable the
  #      controllers we need and create the parent cgroup. If it isn't,
  #      log a warning and continue without cgroup setup; the supervisor
  #      will start Cog unconstrained.
  #   2. Loosen /run permissions so that Cog (running as a non-root uid)
  #      can reach the wayland and D-Bus sockets that root daemons
  #      create there.
  #   3. Pre-create Cog's HOME directory owned by the unprivileged uid
  #      so WPE/WebKit has somewhere to write its profile and caches.

  require Logger

  @cgroup_fs "/sys/fs/cgroup"
  @parent_cgroup "kiosk_demo"
  @controllers ["cpu", "memory", "pids"]
  @run_dir "/run"
  @cog_uid 33
  @cog_gid 33
  @cog_home "/tmp/cog"

  @type cgroup_status :: :cgroups | :no_cgroups

  @spec setup!() :: cgroup_status()
  def setup!() do
    status = setup_cgroups()
    relax_run_perms!()
    prepare_cog_home!()
    status
  end

  @spec parent_cgroup() :: String.t()
  def parent_cgroup(), do: @parent_cgroup

  @spec cog_home() :: String.t()
  def cog_home(), do: @cog_home

  # Compute Cog's memory.max as (MemTotal - reservation). The reservation
  # holds back enough RAM for the BEAM, base Linux, and slack; everything
  # else is given to the browser. Tiered rather than a flat percentage so
  # the reservation doesn't balloon on large-RAM devices that still run
  # the same Elixir workload.
  @spec cog_memory_limit() :: pos_integer()
  def cog_memory_limit() do
    total = mem_total_bytes()
    reserve = reservation_bytes(total)
    max(total - reserve, 256 * 1024 * 1024)
  end

  defp reservation_bytes(total_bytes) do
    gb = 1024 * 1024 * 1024
    mb = 1024 * 1024

    cond do
      total_bytes <= 1 * gb -> 384 * mb
      total_bytes <= 2 * gb -> 512 * mb
      total_bytes <= 4 * gb -> 640 * mb
      true -> 768 * mb
    end
  end

  defp mem_total_bytes() do
    content = File.read!("/proc/meminfo")
    [_, kb] = Regex.run(~r/^MemTotal:\s+(\d+) kB/m, content)
    String.to_integer(kb) * 1024
  end

  defp setup_cgroups() do
    if v2_mounted?() do
      enable_controllers!()
      create_parent_cgroup!()
      :cgroups
    else
      Logger.warning(
        "SystemSetup: #{@cgroup_fs} is not a cgroup v2 unified hierarchy; " <>
          "starting Cog without cgroup limits"
      )

      :no_cgroups
    end
  end

  defp v2_mounted?() do
    File.exists?(Path.join(@cgroup_fs, "cgroup.controllers"))
  end

  defp enable_controllers!() do
    value = Enum.map_join(@controllers, " ", &("+" <> &1))
    Logger.info("Enabling controllers: #{value}")
    File.write!(Path.join(@cgroup_fs, "cgroup.subtree_control"), value)
  end

  defp create_parent_cgroup!() do
    File.mkdir_p!(Path.join(@cgroup_fs, @parent_cgroup))
  end

  defp relax_run_perms!() do
    File.chmod!(@run_dir, 0o777)
  end

  defp prepare_cog_home!() do
    File.mkdir_p!(@cog_home)
    :ok = :file.change_owner(@cog_home, @cog_uid, @cog_gid)
  end
end
