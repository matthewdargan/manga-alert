{
  inputs = {
    crane = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:ipetkov/crane";
    };
    fenix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:nix-community/fenix";
    };
    nixpkgs.url = "nixpkgs/nixos-unstable";
    parts.url = "github:hercules-ci/flake-parts";
    pre-commit-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:cachix/pre-commit-hooks.nix";
    };
  };
  outputs = inputs:
    inputs.parts.lib.mkFlake {inherit inputs;} {
      imports = [inputs.pre-commit-hooks.flakeModule];
      flake.nixosModules.manga-alert = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.services.manga-alert;
      in {
        config = lib.mkIf cfg.enable {
          systemd.services.manga-alert = {
            after = ["graphical-session.target"];
            description = "Automatically alert about new manga chapters";
            script = "${cfg.package}/bin/manga-alert ${lib.strings.escapeShellArgs cfg.manga}";
            serviceConfig = {
              Type = "oneshot";
              User = cfg.user;
            };
          };
          systemd.timers.manga-alert = {
            timerConfig = {
              OnCalendar = cfg.timer.onCalendar;
              Unit = "manga-alert.service";
            };
            wantedBy = ["timers.target"];
          };
        };
        options.services.manga-alert = {
          enable = lib.mkEnableOption "Enable manga-alert";
          manga = lib.mkOption {
            example = ["One Piece"];
            type = lib.types.listOf lib.types.string;
          };
          package = lib.mkOption {
            default = inputs.self.packages.${pkgs.system}.manga-alert;
            type = lib.types.package;
          };
          timer = {
            enable = lib.mkEnableOption "Enable manga-alert timer";
            onCalendar = lib.mkOption {
              default = "*-*-* 08..23:00:00";
              example = "*-*-* 08..23:00:00";
              type = lib.types.string;
            };
          };
          user = lib.mkOption {
            type = lib.types.string;
          };
        };
      };
      perSystem = {
        config,
        inputs',
        lib,
        pkgs,
        system,
        ...
      }: let
        craneLib = inputs.crane.lib.${system}.overrideToolchain rustToolchain;
        rustToolchain = inputs'.fenix.packages.stable.toolchain;
      in {
        devShells.default = pkgs.mkShell {
          packages = [pkgs.bacon rustToolchain];
          RUST_SRC_PATH = "${rustToolchain}/lib/rustlib/src/rust/src";
          shellHook = "${config.pre-commit.installationScript}";
        };
        packages.manga-alert = craneLib.buildPackage {
          nativeBuildInputs = lib.optionals pkgs.stdenv.isDarwin [pkgs.libiconv];
          src = craneLib.cleanCargoSource (craneLib.path ./.);
        };
        pre-commit = {
          settings = {
            hooks = {
              alejandra.enable = true;
              deadnix.enable = true;
              rustfmt.enable = true;
              statix.enable = true;
            };
            src = ./.;
          };
        };
      };
      systems = ["aarch64-darwin" "aarch64-linux" "x86_64-darwin" "x86_64-linux"];
    };
}
