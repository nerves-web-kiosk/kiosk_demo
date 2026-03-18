<!--
  SPDX-FileCopyrightText: None
  SPDX-License-Identifier: CC0-1.0
-->
# Changelog

## v0.3.0

This is a major update to the Nerves systems used for this demo that adjusts the
on-disk layout. As such, once upgraded, it's not possible to downgrade to v0.2.2
without reprogramming the entire MicroSD.

* Changes
  * Fix hardware cursor issue affecting Mesa3D on Raspberry Pis that would cause
    Weston to crash when using a mouse. This didn't affect touchscreen use.
  * Update Nerves systems to 2.0.1 versions. See Nerves systems for details, but
    the main update is that the demo now uses the Raspberry Pi tryboot feature
    so that early boot issues (like Linux kernel and Erlang boot script crashes)
    revert to previous good firmware rather than cycling.

## v0.2.2

* Changes
  * Update Nerves systems to 0.6.1 versions

## v0.2.1

* Fixes
  * Fix firmware release build script

## v0.2.0

* Changes
  * Changed project focus from being a barebones example to a web kiosk demo
  * Added a new home screen to provide general info and show features
  * Refreshed GPIO screen

## v0.1.0

Initial release
