{
  description = "NixOS 26.05 live image for Microsoft Surface Pro 6";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/24cfdc1f9344b90a1eee329a3906e2f39f4d0f1e";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, nixos-hardware, ... }:
    let
      system = "x86_64-linux";
      live = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          "${nixpkgs}/nixos/modules/installer/cd-dvd/installation-cd-graphical-gnome.nix"
          nixos-hardware.nixosModules.microsoft-surface-pro-intel
          ./iso.nix
        ];
      };
    in {
      nixosConfigurations.surface-pro6-live = live;
      packages.${system} = {
        surface-pro6-iso = live.config.system.build.isoImage;
        default = live.config.system.build.isoImage;
      };
    };
}
