{
  pkgs,
  lib,
  ...
}: let
  runViaSystemdCat = {
    name,
    cmd,
  }:
    pkgs.writeShellApplication {
      name = "run";
      text = ''
        exec ${pkgs.udev}/bin/systemd-cat --identifier=${name} ${cmd}
      '';
    };

  runViaShell = {
    env ? {},
    sourceHmVars ? true,
    viaSystemdCat ? true,
    name,
    cmd,
  }:
    pkgs.writeShellApplication {
      name = "run";
      text = ''
        ${lib.concatStringsSep "\n" (lib.mapAttrsToList (k: v: "export ${k}=\"${v}\"") env)}
        ${
          if sourceHmVars
          then ''
            if [ -e /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh ]; then
              set +u
              # shellcheck disable=SC1090
              source /etc/profiles/per-user/"$USER"/etc/profile.d/hm-session-vars.sh
              set -u
            fi
          ''
          else ""
        }
        ${
          if viaSystemdCat
          then ''
            exec ${runViaSystemdCat {inherit name cmd;}}/bin/run
          ''
          else ''
            exec ${cmd}
          ''
        }
      '';
    };

  runSway = runViaShell {
    env = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "sway";
      XDG_SESSION_DESKTOP = "sway";
    };
    name = "sway";
    cmd = "${pkgs.sway}/bin/sway";
  };

  runRiver = runViaShell {
    env = {
      XDG_SESSION_TYPE = "wayland";
      XDG_CURRENT_DESKTOP = "river";
      XDG_SESSION_DESKTOP = "river";
    };
    name = "river";
    cmd = "${pkgs.river}/bin/river";
  };

  desktopSession = name: command:
    pkgs.writeText "${name}.desktop" ''
      [Desktop Entry]
      Type=Application
      Name=${name}
      Exec=${command}
    '';

  sessionDir = pkgs.linkFarm "sessions" [
    {
      name = "sway.desktop";
      path = desktopSession "sway" "${runSway}/bin/run";
    }
    {
      name = "river.desktop";
      path = desktopSession "river" "${runRiver}/bin/run";
    }
    {
      name = "shell.desktop";
      path = desktopSession "nu" "${pkgs.nushell}/bin/nu";
    }
  ];
in {
  services.greetd = {
    enable = true;
    restart = true;
    settings = {
      default_session.command = "${pkgs.greetd.tuigreet}/bin/tuigreet --sessions ${sessionDir} --time -r --remember-session --power-shutdown '${pkgs.systemd}/bin/systemctl poweroff' --power-reboot '${pkgs.systemd}/bin/systemctl reboot'";
    };
  };
  ## prevents systemd spewing the console with log messages when greeter is active
  systemd.services.greetd.serviceConfig = {
    ExecStartPre = "${pkgs.util-linux}/bin/kill -SIGRTMIN+21 1";
    ExecStopPost = "${pkgs.util-linux}/bin/kill -SIGRTMIN+20 1";
  };
}
