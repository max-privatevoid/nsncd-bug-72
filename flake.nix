{
  description = "Repro for nsncd issue #72 - see https://github.com/twosigma/nsncd/issues/72";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [ "x86_64-linux" "aarch64-linux" ];
      perSystem = { config, lib, pkgs, ... }: {
        packages.default = pkgs.callPackage ./test.nix { };
        apps.interactive.program = lib.getExe config.packages.default.driverInteractive;
      };
    };
}
