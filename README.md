<!--
  SPDX-FileCopyrightText: None
  SPDX-License-Identifier: CC0-1.0
-->
# KioskDemo

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/nerves-web-kiosk/kiosk_demo/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nerves-web-kiosk/kiosk_demo/tree/main)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-web-kiosk/kiosk_demo)](https://api.reuse.software/info/github.com/nerves-web-kiosk/kiosk_demo)

This is the example kiosk application for the following Nerves kiosk systems:

- [kiosk_system_rpi4](https://github.com/nerves-web-kiosk/kiosk_system_rpi4)
- [kiosk_system_rpi5](https://github.com/nerves-web-kiosk/kiosk_system_rpi5)

It runs a Phoenix LiveView web application full-screen on a Raspberry Pi using a
Wayland compositor (Weston) and browser (Cog). The home screen shows system
information, IP addresses, and links to a GPIO control page and Phoenix
LiveDashboard.

## Getting started

```sh
git clone https://github.com/nerves-web-kiosk/kiosk_demo.git
cd kiosk_demo
export MIX_TARGET=rpi4  # or rpi5
mix setup
mix firmware
mix burn
```

If you want WiFi credentials to be written to the MicroSD card, initialize the
MicroSD card like this instead:

```sh
NERVES_WIFI_SSID='access_point' NERVES_WIFI_PASSPHRASE='passphrase' mix burn
```

You can still change the WiFi credentials at runtime using
`VintageNetWiFi.quick_configure/2`, but this helps when you don't have an easy
alternative way of accessing the device to configure WiFi.

Then:

1. Insert the MicroSD into your Raspberry Pi 4 or 5
2. Connect your Pi to a display
3. Boot it!

## SSH access

Connect over SSH to control the kiosk from the IEx console:

```sh
ssh kiosk@nerves-xxxx.local  # password: "kiosk"
```

The `KioskDemo` module provides functions for navigating the browser:

- `KioskDemo.home()` - return to the home page
- `KioskDemo.gpio()` - open the GPIO control page
- `KioskDemo.live_dashboard()` - open Phoenix LiveDashboard
- `KioskDemo.change_url("http://example.com")` - navigate to any URL

## Host development

You can run the Phoenix web app locally for development without hardware:

```sh
mix setup
mix phx.server
```

Then visit <http://localhost:4000>. Hardware-specific features like GPIO will not
be functional on the host.

## With Raspberry Pi Touch Display 2

To change the screen orientation, use the method described below.

1. Create `rootfs_overlay/etc/xdg/weston/weston.ini`
2. Edit it like the following:

```ini
[output]
name=DSI-1
mode=720x1280@60.0
transform=rotate-270
```

The transform key can be `rotate-(90|180|270)`.

## More about weston.ini

The original source is available [here](https://gitlab.freedesktop.org/wayland/weston/-/blob/main/man/weston.ini.man),
but it's not very human-readable. For a more readable version, see [this man page](https://manpages.ubuntu.com/manpages/noble/man5/weston.ini.5.html).
