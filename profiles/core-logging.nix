{
  services.opentelemetry-collector = {
    enable = true;
    settings = {
      receivers.journald = {
        directory = "/var/log/journal";
        priority = "info";
      };
      exporters.otlphttp.logs_endpoint = "https://victorialogs.9000.dev/insert/opentelemetry/v1/logs";
      service.pipelines.logs = {
        receivers = ["journald"];
        exporters = ["otlphttp"];
      };
    };
  };
}
