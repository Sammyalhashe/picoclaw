{ config, lib, pkgs, ... }:

with lib;

let
  cfg = config.programs.picoclaw;
  jsonFormat = pkgs.formats.json {};
in {
  options.programs.picoclaw = {
    enable = mkEnableOption "PicoClaw AI Assistant";

    package = mkOption {
      type = types.package;
      default = pkgs.picoclaw;
      defaultText = literalExpression "pkgs.picoclaw";
      description = "The picoclaw package to use. Make sure the picoclaw overlay is applied or this package is available in pkgs.";
    };

    settings = mkOption {
      type = jsonFormat.type;
      default = {};
      description = "Configuration for picoclaw, written to config.json.";
      example = literalExpression ''
        {
          agents = {
            defaults = {
              model_name = "gpt4";
            };
          };
        }
      '';
    };

    environmentFile = mkOption {
      type = types.nullOr types.path;
      default = null;
      description = "Path to an environment file (e.g., from sops-nix) to load API keys and other secrets into the picoclaw gateway environment.";
    };
  };

  config = mkIf cfg.enable {
    home.packages = [ cfg.package ];

    xdg.configFile."picoclaw/config.json" = mkIf (cfg.settings != {}) {
      source = jsonFormat.generate "picoclaw-config.json" cfg.settings;
    };

    systemd.user.services.picoclaw-gateway = {
      Unit = {
        Description = "PicoClaw Gateway Service";
        After = [ "network.target" ];
      };
      Install = {
        WantedBy = [ "default.target" ];
      };
      Service = {
        ExecStart = "${cfg.package}/bin/picoclaw gateway";
        Restart = "always";
        Environment = [
          "PICOCLAW_CONFIG_PATH=${config.xdg.configHome}/picoclaw/config.json"
        ];
        EnvironmentFile = mkIf (cfg.environmentFile != null) cfg.environmentFile;
      };
    };
  };
}
