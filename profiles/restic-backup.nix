{
  adminUser,
  config,
  ...
}: {
  age.secrets = {
    restic-env = {
      file = ../secrets/restic.age;
      owner = "1337";
    };
    restic-pw = {
      file = ../secrets/restic-pw.age;
      owner = "1337";
    };
    restic-local-env = {
      file = ../secrets/restic-local.age;
      owner = "1337";
    };
    restic-local-pw = {
      file = ../secrets/restic-local-pw.age;
      owner = "1337";
    };
  };

  services.restic = {
    backups = {
      local = {
        paths = [
          "/home/${adminUser.name}/Development"
          "/home/${adminUser.name}/Documents"
          "/home/${adminUser.name}/Sync"
          "/home/${adminUser.name}/Photos"
          "/home/${adminUser.name}/Mail"
        ];
        environmentFile = config.age.secrets.restic-local-env.path;
        passwordFile = config.age.secrets.restic-local-pw.path;
        repository = "s3:https://storage.9000.dev/backup";
        initialize = true;
        timerConfig.OnCalendar = "*-*-* *:00:00";
        timerConfig.RandomizedDelaySec = "5m";
        extraBackupArgs = [
          "--exclude=\".direnv\""
          "--exclude=\".terraform\""
          "--exclude=\"node_modules/*\""
        ];
      };
      remote = {
        paths = [
          "/home/${adminUser.name}/Development"
          "/home/${adminUser.name}/Documents"
          "/home/${adminUser.name}/Sync"
          "/home/${adminUser.name}/Photos"
          "/home/${adminUser.name}/Mail"
        ];
        environmentFile = config.age.secrets.restic-env.path;
        passwordFile = config.age.secrets.restic-pw.path;
        repository = "s3:https://hel1.your-objectstorage.com/9000";
        initialize = true;
        timerConfig.OnCalendar = "*-*-* *:00:00";
        timerConfig.RandomizedDelaySec = "5m";
        extraBackupArgs = [
          "--exclude=\".direnv\""
          "--exclude=\".terraform\""
          "--exclude=\"node_modules/*\""
        ];
      };
    };
  };
}
