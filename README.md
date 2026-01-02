# KioskDemo

[![CircleCI](https://dl.circleci.com/status-badge/img/gh/nerves-web-kiosk/kiosk_demo/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/gh/nerves-web-kiosk/kiosk_demo/tree/main)
[![REUSE status](https://api.reuse.software/badge/github.com/nerves-web-kiosk/kiosk_demo)](https://api.reuse.software/info/github.com/nerves-web-kiosk/kiosk_demo)

This is the example kiosk application for followings,

- [kiosk_nerves_rpi4](https://github.com/nerves-web-kiosk/kiosk_system_rpi4)
- [kiosk_nerves_rpi5](https://github.com/nerves-web-kiosk/kiosk_system_rpi5)

## How to try

```sh
git clone https://github.com/nerves-web-kiosk/kiosk_demo.git
cd kiosk_demo
export MIX_TARGET=rpi4
mix deps.get
mix assets.build
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

Then,

1. Insert the MicroSD to your Raspberry Pi 4 or 5
1. Connect your Pi and a display
1. Boot it!!

We will see Phoenix LiveDashboard on your display!!!

We can change the URL to use `KioskDemo.change_url("http://example.com")`
on IEx console over SSH.

And there are some functions in `KioskDemo` module which lead browser to famous URL. Enjoy!!

## With Raspberry Pi Touch Display2

To change the screen orientation, use the method described below.

1. Create `rootfs_overlay/etc/xdg/weston/weston.ini`
1. Edit it like following

```
[output]
name=DSI-1
mode=720x1280@60.0
transform=rotate-270
```

The transform key can be `rotate-(90|180|270)`.

## More about weston.ini

The original source is available [here](https://gitlab.freedesktop.org/wayland/weston/-/blob/main/man/weston.ini.man),
but it's not very human-readable. For a more readable version, see [this man page](https://manpages.ubuntu.com/manpages/noble/man5/weston.ini.5.html).
