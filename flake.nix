{
  description = ''
    A garnix module for projects using PostgreSQL.

    Note: Enabling PostgreSQL will automatically mark the deployed server as [persistent](https://garnix.io/docs/hosting/persistence).

    [Documentation](https://garnix.io/docs/modules/postgresql) - [Source](https://github.com/garnix-io/postgresql-module).
  '';

  outputs =
    { self }:
    {
      garnixModules.default =
        {
          pkgs,
          lib,
          config,
          ...
        }:
        let
          postgresqlSubmodule.options = {
            port = lib.mkOption {
              type = lib.types.port;
              description = "The port on which to run PostgreSQL.";
              default = 5432;
            };

          };
        in
        {
          options = {
            postgresql = lib.mkOption {
              type = lib.types.attrsOf (lib.types.submodule postgresqlSubmodule);
              description = "An attrset of PostgreSQL databases.";
            };
          };

          config =
            let
              postgres = pkgs.postgresql_17;
            in
            {

              devShells = builtins.mapAttrs (
                name: projectConfig:
                pkgs.mkShell {
                  packages = [ postgres ];
                }
              ) config.postgresql;

              nixosConfigurations.default = builtins.attrValues (
                builtins.mapAttrs (name: projectConfig: {
                  environment.systemPackages = [ postgres ];

                  services.postgresql = {
                    enable = true;
                    package = postgres;
                    settings.port = projectConfig.port;
                  };

                  garnix.server.persistence = {
                    enable = true;
                    name = "postgresql";
                  };
                }) config.postgresql
              );
            };
        };
    };
}
