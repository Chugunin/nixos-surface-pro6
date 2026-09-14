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

## Hardware-test findings / backlog

Observed on a physical Microsoft Surface Pro 6 during the first live-boot test. These are recorded for later fixes; no rebuild is required just to record them.

- **Strelec USB boot:** the previous MBR/NTFS-only Strelec layout was not bootable by the tested Surface UEFI. Recreating the USB in GPT/UEFI form allowed Strelec GRUB2 to boot. Secure Boot was disabled for this test.
- **ISO boot through Strelec:** placing the ISO in `/Linux` is not sufficient for automatic discovery by Strelec. A custom `usermenu64.cfg` entry using GRUB `loopback` plus NixOS `findiso=` successfully starts the NixOS kernel/initrd from the ISO.
- **Strelec GRUB modules:** do not require `insmod ntfs` in the custom entry. The tested Strelec GRUB does not provide `ntfs.mod`; the explicit load only produces a harmless GRUB error. Use the filesystem support already available in the running Strelec GRUB.
- **Boot reaches NixOS userspace:** linux-surface kernel 6.19.8 and the generated initrd start successfully from the loopback ISO; systemd userspace is reached.
- **`systemd-modules-load.service` fails on physical SP6:** observed failures are `hv_storvsc` (`Device or resource busy`) and `hv_balloon` (`No such device`). These Hyper-V guest modules are not appropriate as mandatory modules on the physical Surface. Investigate where the generic live/installer configuration forces them and stop treating them as mandatory for the SP6 image.
- **Emergency mode:** the first physical boot enters systemd emergency mode. `systemctl --failed` showed only `systemd-modules-load.service` at the time inspected, but do not assume the Hyper-V module-load failure is the sole cause until boot continuation/dependencies are verified. Diagnose before applying a broad workaround.
