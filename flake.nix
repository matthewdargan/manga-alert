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
    nix-filter.url = "github:numtide/nix-filter";
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
      flake.homeModules.manga-alert = {
        config,
        lib,
        pkgs,
        ...
      }: let
        cfg = config.manga-alert;
      in {
        config = lib.mkIf cfg.enable {
          systemd.user.services.manga-alert = {
            Unit.Description = "Automatically alert about new manga chapters";
            Install.WantedBy = ["graphical-session.target"];
            Service = {
              ExecStart = "${cfg.package}/bin/manga-alert ${lib.strings.escapeShellArgs cfg.manga}";
              Type = "oneshot";
            };
          };
          systemd.user.timers.manga-alert = {
            Unit.Description = "manga-alert.service";
            Timer = {
              OnCalendar = cfg.timer.onCalendar;
              WantedBy = ["timers.target"];
            };
          };
        };
        options.manga-alert = {
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
          src = inputs.nix-filter.lib {
            include = [
              "Cargo.lock"
              "Cargo.toml"
              "src"
            ];
            root = ./.;
          };
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
