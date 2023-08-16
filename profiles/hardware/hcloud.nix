{
  modulesPath,
  hostName,
  pkgs,
  inputs,
  config,
  lib,
  ...
}: {
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    ../../cachix.nix
  ];
  boot.loader.grub.device = "/dev/sda";
  boot.initrd.availableKernelModules = ["ata_piix" "uhci_hcd" "xen_blkfront" "vmw_pvscsi"];
  boot.initrd.kernelModules = ["nvme"];
  fileSystems."/" = {
    device = "/dev/sda1";
    fsType = "ext4";
    autoResize = true;
  };
  boot.kernelPackages = pkgs.linuxPackages_latest;
  boot.tmp.cleanOnBoot = true;
  boot.growPartition = true;
  zramSwap.enable = true;
  services.openssh.enable = true;

  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  networking.dhcpcd.enable = false; ## we're using cloud-init
  networking.hostName = "";
  networking.useNetworkd = true;
  systemd.network.enable = true;

  nix = {
    settings.trusted-users = ["root"];
    extraOptions = ''
      experimental-features = nix-command flakes
      accept-flake-config = true
      keep-outputs = true
      keep-derivations = true
      tarball-ttl = 900
    '';

    registry.nixpkgs.flake = inputs.nixpkgs;

    nixPath = ["nixpkgs=${inputs.nixpkgs}"];

    gc = {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 7d";
    };

    package = pkgs.nix;
  };

  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = [
    pkgs.binutils
    pkgs.cacert
    pkgs.curl
    pkgs.fd
    pkgs.file
    pkgs.git
    pkgs.iptables
    pkgs.jq
    pkgs.lsof
    pkgs.man-pages
    pkgs.mkpasswd
    pkgs.nmap
    pkgs.openssl
    pkgs.procs
    pkgs.psmisc
    pkgs.ripgrep
    pkgs.sd
    pkgs.tree
    pkgs.unzip
    pkgs.vim
    pkgs.wget
    pkgs.zip
  ];
}
