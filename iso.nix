{ config, lib, pkgs, ... }:

let
  surfaceReport = pkgs.writeShellScriptBin "surface-report" (builtins.readFile ./scripts/surface-report.sh);
in
{
  networking.hostName = "surface-pro6-live";
  networking.networkmanager.enable = true;

  # Surface Pro Intel profile enables the patched Surface kernel, IPTSD,
  # redistributable firmware, IIO sensors, thermald and surface-control.
  hardware.microsoft-surface.kernelVersion = "longterm";
  services.iptsd.enable = true;
  hardware.sensor.iio.enable = true;

  # Surface-specific Wacom database includes an explicit Surface Pro 6 entry.
  services.xserver.wacom.enable = true;
  services.xserver.wacom.package = pkgs.libwacom-surface;

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

  # GNOME/Wayland is supplied by the graphical GNOME installation image.
  services.displayManager.gdm.wayland = true;
  services.displayManager.gdm.autoSuspend = false;

  # Suspend remains available for an explicit test, but the live desktop does
  # not auto-suspend while diagnostics are running.
  systemd.sleep.extraConfig = ''
    AllowSuspend=yes
    AllowHibernation=no
    AllowHybridSleep=no
    AllowSuspendThenHibernate=no
  '';

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
