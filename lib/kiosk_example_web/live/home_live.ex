defmodule KioskExampleWeb.HomeLive do
  use KioskExampleWeb, :live_view
  use KioskExampleWeb.Live.Screensaver

  def mount(_params, _session, socket) do
    {:ok, name} = :inet.gethostname()

    system_info = %{
      serial_number: get_serial_number(),
      firmware: get_firmware_info()
    }

    socket =
      socket
      |> assign(:hostname, to_string(name))
      |> assign(:system_info, system_info)
      |> init_screensaver()

    {:ok, socket}
  end

  defp get_serial_number do
    if Code.ensure_loaded?(Nerves.Runtime) do
      Nerves.Runtime.serial_number()
    else
      "unconfigured"
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
        architecture: "generic",
        description: "N/A",
        platform: "host",
        version: "0.0.0"
      }
    end
  end

  def render(assigns) do
    ~H"""
    <div
      {screensaver_events()}
      class="relative min-h-screen"
    >
      <.screensaver_overlay :if={@screensaver_active} />

      <div class="px-4 py-10 sm:px-6 sm:py-20 lg:px-8 xl:px-28 xl:py-24">
        <div class="mx-auto max-w-4xl">
          <div class="text-center mb-12">
            <h1 class="text-4xl font-bold mb-4">Nerves Web Kiosk</h1>
          </div>

          <div class="mt-8 rounded-box border bg-base-200 p-6">
            <p class="text-lg font-semibold">What you're seeing</p>
            <p class="mt-2 text-base-content/80">
              A full-screen web browser experience driven by a Phoenix LiveView app running on Nerves.
            </p>

            <div class="mt-6 grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div class="rounded-box bg-base-100 p-4">
                <div class="flex items-center gap-2 mb-2">
                  <.icon name="hero-computer-desktop" class="size-6 text-primary" />
                  <p class="font-semibold">SSH access</p>
                </div>
                <p class="mt-2 text-sm text-base-content/80">You can open an IEx prompt via SSH:</p>
                <pre class="mt-2 bg-base-200 p-2 rounded text-sm"><code>ssh kiosk@{(@hostname || "nerves-xxxx")}.local</code></pre>
                <p class="mt-2 text-sm text-base-content/70">
                  Default password: <strong>kiosk</strong>
                </p>
              </div>

              <div class="rounded-box bg-base-100 p-4">
                <div class="flex items-center gap-2 mb-2">
                  <.icon name="hero-chart-bar" class="size-6 text-primary" />
                  <p class="font-semibold">Phoenix LiveDashboard</p>
                </div>
                <p class="mt-2 text-sm text-base-content/80">
                  View metrics and introspect the running app:
                </p>
                <a href="/dashboard" class="btn btn-sm btn-primary mt-3">Open LiveDashboard</a>
              </div>

              <div class="rounded-box bg-base-100 p-4">
                <div class="flex items-center gap-2 mb-2">
                  <.icon name="hero-information-circle" class="size-6 text-primary" />
                  <p class="font-semibold">More information</p>
                </div>
                <p class="mt-2 text-sm text-base-content/80">
                  Source code, issues, and support can be found at the GitHub repository page:
                </p>
                <a
                  href="https://github.com/nerves-web-kiosk/kiosk_example"
                  class="link link-primary text-sm break-all"
                >
                  https://github.com/nerves-web-kiosk/kiosk_example
                </a>
                <div class="mt-3 flex justify-center">
                  <img
                    alt="QR code for source repository"
                    src={~p"/images/qr_source.png"}
                    width="180"
                    height="180"
                    class="rounded"
                  />
                </div>
              </div>

              <div class="rounded-box bg-base-100 p-4">
                <div class="flex items-center gap-2 mb-2">
                  <.icon name="hero-cpu-chip" class="size-6 text-primary" />
                  <p class="font-semibold">System information</p>
                </div>
                <div class="mt-2">
                  <table class="w-full text-sm">
                    <tbody>
                      <tr class="border-b border-base-300">
                        <td class="py-2 pr-4 font-medium text-base-content/70">Serial Number:</td>
                        <td class="py-2 text-base-content/80 break-all">
                          {@system_info.serial_number}
                        </td>
                      </tr>
                      <tr class="border-b border-base-300">
                        <td class="py-2 pr-4 font-medium text-base-content/70">Architecture:</td>
                        <td class="py-2 text-base-content/80">
                          {@system_info.firmware.architecture}
                        </td>
                      </tr>
                      <tr class="border-b border-base-300">
                        <td class="py-2 pr-4 font-medium text-base-content/70">Platform:</td>
                        <td class="py-2 text-base-content/80">{@system_info.firmware.platform}</td>
                      </tr>
                      <tr class="border-b border-base-300">
                        <td class="py-2 pr-4 font-medium text-base-content/70">Version:</td>
                        <td class="py-2 text-base-content/80">{@system_info.firmware.version}</td>
                      </tr>
                      <tr>
                        <td class="py-2 pr-4 font-medium text-base-content/70">Description:</td>
                        <td class="py-2 text-base-content/80">
                          {@system_info.firmware.description}
                        </td>
                      </tr>
                    </tbody>
                  </table>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
    """
  end
end
