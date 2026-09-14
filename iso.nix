{ config, lib, pkgs, ... }:

let
  surfaceReport = pkgs.writeShellScriptBin "surface-report" (builtins.readFile ./scripts/surface-report.sh);
  bootDiagnostics = pkgs.writeShellScript "surface-boot-diagnostics" ''
    set +e
    OUT=/tmp/surface-boot-diagnostics
    mkdir -p "$OUT"
    date -Is > "$OUT/timestamp.txt"
    cat /proc/cmdline > "$OUT/cmdline.txt" 2>&1
    ${pkgs.systemd}/bin/systemctl --failed --no-pager > "$OUT/failed-units.txt" 2>&1
    ${pkgs.systemd}/bin/systemctl list-jobs --no-pager > "$OUT/jobs.txt" 2>&1
    ${pkgs.systemd}/bin/systemctl status systemd-modules-load.service --no-pager -l > "$OUT/modules-load-status.txt" 2>&1
    ${pkgs.systemd}/bin/journalctl -b --no-pager > "$OUT/journal.txt" 2>&1
    ${pkgs.systemd}/bin/journalctl -b -k --no-pager > "$OUT/kernel-journal.txt" 2>&1
    ${pkgs.kmod}/bin/lsmod > "$OUT/lsmod.txt" 2>&1
    ${pkgs.util-linux}/bin/lsblk -f > "$OUT/lsblk.txt" 2>&1
    ${pkgs.util-linux}/bin/findmnt > "$OUT/findmnt.txt" 2>&1
    ${pkgs.coreutils}/bin/sync
  '';
in
{
  networking.hostName = "surface-pro6-live";
  networking.networkmanager.enable = true;

  # Surface Pro Intel profile enables the patched Surface kernel, IPTSD,
  # redistributable firmware, IIO sensors, thermald and surface-control.
  hardware.microsoft-surface.kernelVersion = "longterm";
  services.iptsd.enable = true;
  hardware.sensor.iio.enable = true;

  # The generic graphical installer image may request Hyper-V guest storage/balloon
  # modules. They fail on physical SP6 hardware and made systemd-modules-load fail
  # during the first hardware boot. They are not required on the target machine.
  boot.blacklistedKernelModules = [ "hv_storvsc" "hv_balloon" ];

  # Enable Wacom input support. libwacom-surface is also present in the live image
  # for Surface-specific diagnostics; NixOS 26.05 has no services.xserver.wacom.package option.
  services.xserver.wacom.enable = true;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
  };

  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # GNOME 50 is Wayland-only here; keep automatic suspend disabled during validation.
  services.displayManager.gdm.autoSuspend = false;

  # Suspend remains available for an explicit test, but hibernation variants are disabled.
  systemd.sleep.settings.Sleep = {
    AllowSuspend = "yes";
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Automatically capture boot state without requiring commands in an emergency shell.
  # /tmp is intentionally used as the reliable baseline; surface-report remains available
  # for interactive hardware validation once the graphical session starts.
  systemd.services.surface-boot-diagnostics = {
    description = "Capture Surface Pro 6 live boot diagnostics";
    wantedBy = [ "multi-user.target" "emergency.target" ];
    after = [ "systemd-modules-load.service" ];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = bootDiagnostics;
      TimeoutStartSec = 60;
    };
  };

  environment.systemPackages = with pkgs; [
    surfaceReport
    libwacom-surface
    libinput
    evtest
    pciutils
    usbutils
    iw
    bluez
    brightnessctl
    upower
    acpi
    lm_sensors
    powertop
    smartmontools
    nvme-cli
    v4l-utils
    libcamera
    cameractrls
    drm_info
    vulkan-tools
    mesa-demos
    inxi
    jq
    ripgrep
  ];

  # Keep diagnostics convenient in a disposable live environment.
  users.users.nixos.extraGroups = [ "video" "input" "audio" "networkmanager" ];

  isoImage = {
    isoName = lib.mkForce "nixos-surface-pro6-live-${config.system.nixos.release}.iso";
    volumeID = lib.mkForce "NIXOS_SP6_LIVE";
    makeEfiBootable = true;
    makeUsbBootable = true;
  };
}
