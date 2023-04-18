{inputs, ...}: {
  perSystem = {
    pkgs,
    lib,
    system,
    ...
  }: let
    inherit
      (lib // builtins)
      filterAttrs
      filter
      pathExists
      attrNames
      readDir
      mapAttrs
      ;
    pkgList =
      filter
      (elem:
        ! (inputs.${elem} ? "sourceInfo")
        && pathExists (toString (../packages + "/${elem}")))
      (attrNames inputs);
    locallyDefinedPackages = mapAttrs (
      name: _: (pkgs.callPackage (../packages + "/${name}") {inherit inputs;})
    ) (filterAttrs (filename: type: type == "directory") (readDir ../packages));

    packages =
      locallyDefinedPackages
      // rec {
        inherit (pkgs.callPackage ../utils/world.nix {}) pixieboot world lint;
        mynerdfonts = pkgs.nerdfonts.override {fonts = ["JetBrainsMono" "DroidSansMono"];};

        wayland-122 = pkgs.wayland.overrideAttrs (oa: rec {
          pname = "wayland";
          version = "1.22.0";
          src = pkgs.fetchurl {
            url = "https://gitlab.freedesktop.org/wayland/wayland/-/releases/${version}/downloads/${pname}-${version}.tar.xz";
            hash = "sha256-FUCvHqaYpHHC2OnSiDMsfg/TYMjx0Sk267fny8JCWEI=";
          };
        });

        wayland-protocols-master = pkgs.callPackage ../packages/wayland-protocols-master {
          wayland = wayland-122;
        };

        libxkbcommon-150 = pkgs.libxkbcommon.overrideAttrs (oa: rec {
          pname = "libxkbcommon";
          version = "1.5.0";
          src = pkgs.fetchurl {
            url = "https://xkbcommon.org/download/${pname}-${version}.tar.xz";
            sha256 = "sha256-Vg8RxLu8oQ9JXz7306aqTKYrT4+wtS59RZ0Yom5G4Bc=";
          };
        });
        wlroots-master = pkgs.callPackage ../packages/wlroots-master {
          wayland = wayland-122;
          wayland-protocols = wayland-protocols-master;
          libdisplay-info = libdisplay-info-main;
        };
        libdisplay-info-main = pkgs.libdisplay-info.overrideAttrs (
          oa: rec {
            pname = "libdisplay-info";
            version = "0.1.1";
            src = inputs.libdisplay-info;
          }
        );
        sway-unwrapped = pkgs.callPackage ../packages/sway {
          wlroots = wlroots-master;
          wayland-protocols = locallyDefinedPackages.wayland-protocols-master;
          libxkbcommon = libxkbcommon-150;
        };
        sway = pkgs.callPackage (pkgs.path + "/pkgs/applications/window-managers/sway/wrapper.nix") {};
        swayidle = pkgs.callPackage ../packages/swayidle {
          wayland-protocols = locallyDefinedPackages.wayland-protocols-master;
        };
      }
      // {
        ## packages from other flakes
        inherit (inputs.spotnix.packages.${system}) spotnix;
        inherit (inputs.persway.packages.${system}) persway;
        inherit (inputs.headscale.packages.${system}) headscale;
      };
  in {
    inherit packages;
  };
}
