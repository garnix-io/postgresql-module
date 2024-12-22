{
  description = "A garnix module for postgreSQL";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.11";

  outputs =
    { self
    , nixpkgs
    ,
    }:
    let
      lib = nixpkgs.lib;

      postgresqlSubmodule.options = {
        port = lib.mkOption {
          type = lib.types.int;
          description = "The port in which to run PostgreSQL";
          default = 5432;
        };

      };
    in
    {
      garnixModules.default = { pkgs, config, ... }: {
        options = {
          postgresql = lib.mkOption {
            type = lib.types.attrsOf (lib.types.submodule postgresqlSubmodule);
            description = "An attrset of postgresql databases";
          };
        };

        config =
        let postgres = pkgs.postgresql17;
        in {

            devShells = builtins.mapAttrs
              (name: projectConfig:
                pkgs.mkShell {
                  packages = [ postgres ] ;
                }
              )
              config.postgresql;


            nixosConfigurations.default =
              builtins.attrValues (builtins.mapAttrs
                (name: projectConfig: {
                  environment.systemPackages = [ postgres ];

                  services.postgres = {
                    enable = true;
                    package = postgres;
                    settings.port = projectConfig.port;
                  };
                })
                config.postgresql);
          };
      };
    };
}
