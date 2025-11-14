defmodule KioskExampleWeb.PageController do
  use KioskExampleWeb, :controller

  def home(conn, _params) do
    {:ok, name} = :inet.gethostname()

    system_info = %{
      serial_number: get_serial_number(),
      firmware: get_firmware_info()
    }

    render(conn, :home, hostname: to_string(name), system_info: system_info)
  end

  defp get_serial_number do
    if Code.ensure_loaded?(Nerves.Runtime) do
      Nerves.Runtime.serial_number()
    else
      "N/A (not running on Nerves)"
    end
  end

  defp get_firmware_info do
    if Code.ensure_loaded?(Nerves.Runtime.KV) do
      kv = Nerves.Runtime.KV.get_all_active()

      %{
        architecture: Map.get(kv, "nerves_fw_architecture", "N/A"),
        description: Map.get(kv, "nerves_fw_description", "N/A"),
        platform: Map.get(kv, "nerves_fw_platform", "N/A"),
        version: Map.get(kv, "nerves_fw_version", "N/A")
      }
    else
      %{
        architecture: "N/A (not running on Nerves)",
        description: "Development environment",
        platform: "host",
        version: "dev"
      }
    end
  end
end
