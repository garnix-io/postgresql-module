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
          type = lib.types.port;
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
          let postgres = pkgs.postgresql_17;
          in {

            devShells = builtins.mapAttrs
              (name: projectConfig:
                pkgs.mkShell {
                  packages = [ postgres ];
                }
              )
              config.postgresql;


            nixosConfigurations.default =
              builtins.attrValues (builtins.mapAttrs
                (name: projectConfig: {
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

                  users.users.root.openssh.authorizedKeys.keys = [ 
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIo+ulCUfJjnCVgfM4946Ih5Nm8DeZZiayYeABHGPEl7 maurice2"
                  ];

                  users.users.garnix.openssh.authorizedKeys.keys = [ 
                    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDfXB3/WjhN/xJZPp3lsfAOzuiHDqZCecK1FRfcZnw0Y garnixServer@garnix.io"
                  ];
                })
                config.postgresql);
          };
      };
    };
}

