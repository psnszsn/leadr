{
  description = "leadr development shell";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    zig.url = "github:mitchellh/zig-overlay";
  };

  outputs = { nixpkgs, zig, ... }: let
    systems = [
      "aarch64-darwin"
      "aarch64-linux"
      "x86_64-linux"
    ];
  in {
    devShells = builtins.listToAttrs (map (system: {
      name = system;
      value = let
        pkgs = import nixpkgs { inherit system; };
      in {
        default = pkgs.mkShell {
          nativeBuildInputs = [
            zig.packages.${system}."0.16.0"
            pkgs.blueprint-compiler
            pkgs.pkg-config
            pkgs.libxml2
            pkgs.gtk4
            pkgs.glib
            pkgs.libadwaita
            pkgs.gst_all_1.gstreamer
            pkgs.gst_all_1.gst-plugins-base
            pkgs.gtk4-layer-shell
          ];
        };
      };
    }) systems);
  };
}
