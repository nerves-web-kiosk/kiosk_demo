defmodule KioskExampleWeb.GPIOLive do
  @moduledoc """
  This implementation is very lazy.
  Idiomatically the HW logic should be located in `KioskExample` side and
  for local development, we should use like [mox](https://github.com/dashbitco/mox) things.
  """

  use KioskExampleWeb, :live_view

  def render(assigns) do
    ~H"""
    <div class="h-screen flex flex-col">
      <div class="bg-base-200 border-b border-base-300 px-4 py-3 flex items-center gap-3">
        <a href="/" class="btn btn-sm btn-primary gap-2">
          <.icon name="hero-home" class="size-4" /> Home
        </a>
        <span class="text-lg font-semibold">GPIO Control</span>
      </div>

      <div class="px-4 py-4">
        <div class="bg-base-200 rounded-box p-4 mb-4">
          <p class="text-sm text-base-content/80">
            Click on any GPIO button below to toggle its state between low (gray) and high (amber).
            This allows you to control GPIO pins on your device.
          </p>
        </div>

        <div class="grid grid-rows-10 grid-flow-col gap-4">
          <%= for %{label: label} <- enumerate_gpio() do %>
            <button
              id={"gpio-button-#{label}"}
              class={["p-3 rounded-md", bg_color(Map.get(@gpios, label))]}
              phx-click="push"
              value={label}
            >
              {label}
            </button>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  def mount(_params, _session, socket) do
    initial_value = 0

    gpios =
      for %{label: label} <- enumerate_gpio(), into: %{} do
        :ok = write_gpio(label, initial_value)
        {label, initial_value}
      end

    {:ok, assign(socket, :gpios, gpios)}
  end

  def handle_event("push", %{"value" => label}, socket) do
    gpios = socket.assigns.gpios
    value = Map.get(gpios, label) |> Bitwise.bxor(1)

    :ok = write_gpio(label, value)

    {:noreply, assign(socket, :gpios, Map.put(gpios, label, value))}
  end

  if Mix.target() == :host do
    defp enumerate_gpio() do
      2..27
      |> Enum.map(&%{label: "GPIO#{&1}"})
      |> reject_already_used_gpios()
    end

    defp write_gpio(_label, _value) do
      :ok
    end
  else
    defp enumerate_gpio() do
      Circuits.GPIO.enumerate()
      |> Enum.filter(fn %{label: label} -> String.starts_with?(label, "GPIO") end)
      |> reject_already_used_gpios()
    end

    defp write_gpio(label, value) do
      Circuits.GPIO.write_one(label, value)
    end
  end

  defp reject_already_used_gpios(gpios) do
    Enum.reject(gpios, fn %{label: label} -> label in ["GPIO7", "GPIO8"] end)
  end

  defp bg_color(0), do: "bg-gray-200"
  defp bg_color(1), do: "bg-amber-300"
end
