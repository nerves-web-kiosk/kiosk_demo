defmodule KioskDemo.Cog do
  @moduledoc """
  Control the Cog browser by shelling out to `cogctl`.

  `cogctl` talks to the running Cog instance over the session bus
  (`com.igalia.Cog` / `/com/igalia/Cog`) and supports `open`, `previous`,
  `next`, `reload`, `quit`, and `ping`. The session bus address is taken
  from `DBUS_SESSION_BUS_ADDRESS`, which `KioskDemo.KioskSupervisor` sets
  on the BEAM before starting any children.
  """

  @spec open_url(String.t()) :: :ok | {:error, term()}
  def open_url(url) when is_binary(url), do: cogctl(["open", url])

  @spec back() :: :ok | {:error, term()}
  def back(), do: cogctl(["previous"])

  @spec forward() :: :ok | {:error, term()}
  def forward(), do: cogctl(["next"])

  @spec reload() :: :ok | {:error, term()}
  def reload(), do: cogctl(["reload"])

  @spec quit() :: :ok | {:error, term()}
  def quit(), do: cogctl(["quit"])

  @spec ping() :: :ok | {:error, term()}
  def ping(), do: cogctl(["ping"])

  defp cogctl(args) do
    case System.cmd("cogctl", args, stderr_to_stdout: true) do
      {_, 0} -> :ok
      {output, code} -> {:error, {code, output}}
    end
  end
end
