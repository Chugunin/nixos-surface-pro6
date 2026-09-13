# NixOS Surface Pro 6 Live

Reproducible NixOS 26.05 GNOME/Wayland live image for Microsoft Surface Pro 6.

Goals:
- bootable x86_64 UEFI/USB ISO suitable for Ventoy/Sergei Strelec testing;
- official nixos-hardware Surface Pro Intel profile;
- linux-surface patched kernel, IPTS/IPTSD and Surface pen support;
- IIO orientation sensors, Wi-Fi/Bluetooth, PipeWire audio and camera diagnostics;
- no installation or SSD modification required for hardware testing.

Build target: `.#surface-pro6-iso`

The first phase intentionally keeps GNOME and avoids Hyprland, Wine, Waydroid and cosmetic changes so hardware validation stays deterministic.
