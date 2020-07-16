{ stdenv
, sops
, git
, btrfs-progs
, update-wireguard-keys
, update-wifi-networks
, writeStrictShellScriptBin
, ...
}:

writeStrictShellScriptBin "initialize-user" ''
  PATH=${sops}/bin:${git}/bin:${update-wireguard-keys}/bin:${update-wifi-networks}/bin''${PATH:+:}$PATH
  export PATH
  cd ~

  chmod 0700 .gnupg

  if [ ! -e Development/world ]; then
    git clone --recursive git@github.com:johnae/world Development/world
  else
    echo world already exists at Development/world
  fi

  if [ ! -e Development/nixos-metadata ]; then
    git clone --recursive git@github.com:johnae/nixos-metadata Development/nixos-metadata
  else
    echo world already exists at Development/nixos-metadata
  fi

  if [ ! -e "$PASSWORD_STORE_DIR" ]; then
    echo Cloning password store to "$PASSWORD_STORE_DIR"
    git clone git@github.com:johnae/passwords "$PASSWORD_STORE_DIR"
  else
    echo Password store "$PASSWORD_STORE_DIR" already present
  fi

  mu init --maildir ~/.mail

  sudo mkdir -p /root/.ssh
  sudo chmod 0700 /root/.ssh
  sops -d Development/nixos-metadata/backup_id_ed25519 | \
          sudo tee /root/.ssh/backup_id_ed25519 >/dev/null
  sudo chmod 0600 /root/.ssh/backup_id_ed25519

  sops -d Development/nixos-metadata/builder_id_ed25519 | \
          sudo tee /root/.ssh/id_ed25519 >/dev/null
  sudo chmod 0600 /root/.ssh/id_ed25519

  update-wifi-networks
  update-wireguard-keys
''
