defmodule KioskDemo do
  @moduledoc """
  Kiosk demo top-level helpers.

  Browser navigation (changing the displayed URL) was previously done by
  restarting Cog with new command-line arguments. That has been removed —
  a future change will drive Cog over its D-Bus API instead.
  """

  @doc false
  @spec ssh_check_pass(charlist(), charlist()) :: boolean()
  def ssh_check_pass(_provided_username, provided_password) do
    correct_password = Application.get_env(:kiosk_demo, :password, "kiosk")

    provided_password == to_charlist(correct_password)
  end

  @doc false
  @spec ssh_show_prompt(:ssh.ip_port(), charlist(), charlist()) ::
          {charlist(), charlist(), charlist(), boolean()}
  def ssh_show_prompt(_peer, _username, _service) do
    {:ok, name} = :inet.gethostname()

    msg = """
    https://github.com/nerves-web-kiosk/kiosk_demo

    ssh kiosk@#{name}.local # Use password "kiosk"
    """

    {~c"Nerves Web Kiosk Example", to_charlist(msg), ~c"Password: ", false}
  end
end
