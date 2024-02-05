{
  description = "Home Manager configuration for GoTrade";

  inputs = {
    # util
    flake-utils.url = "github:numtide/flake-utils";
    treefmt-nix.url = "github:numtide/treefmt-nix";
    pre-commit-hooks.url = "github:cachix/pre-commit-hooks.nix";

    nixpkgs.url = "nixpkgs/79a13f1437e149dc7be2d1290c74d378dad60814";
    nixpkgs-2305.url = "nixpkgs/nixos-23.05";
    nixpkgs-feb-05-24.url = "nixpkgs/057f9aecfb71c4437d2b27d3323df7f93c010b7e";
    atomipkgs.url = "github:kirinnee/test-nix-repo/v22.2.0";
    atomipkgs_classic.url = "github:kirinnee/test-nix-repo/classic";
  };

  outputs =
    { self

      # utils
    , flake-utils
    , treefmt-nix
    , pre-commit-hooks

      # registries
    , atomipkgs
    , atomipkgs_classic
    , nixpkgs
    , nixpkgs-2305
    , nixpkgs-feb-05-24
    } @inputs:
    (
      flake-utils.lib.eachDefaultSystem
        (system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          pkgs-2305 = nixpkgs-2305.legacyPackages.${system};
          pkgs-feb-05-24 = nixpkgs-feb-05-24.legacyPackages.${system};
          atomi = atomipkgs.packages.${system};
          atomi_classic = atomipkgs_classic.packages.${system};
          pre-commit-lib = pre-commit-hooks.lib.${system};
        in
        let
          out = rec {
            lib = {
              mutate = import ./default.nix { inherit atomi; };
            };
            pre-commit = import ./nix/pre-commit.nix {
              inherit pre-commit-lib formatter packages;
            };
            formatter = import ./nix/fmt.nix {
              inherit treefmt-nix pkgs;
            };
            packages = import ./nix/packages.nix {
              inherit pkgs atomi atomi_classic pkgs-2305 pkgs-feb-05-24;
            };
            env = import ./nix/env.nix {
              inherit pkgs packages;
            };
            devShells = import ./nix/shells.nix {
              inherit pkgs env packages;
              shellHook = checks.pre-commit-check.shellHook;
            };
            checks = {
              pre-commit-check = pre-commit;
              format = formatter;
            };
          };
        in
        with out;
        {
          inherit checks formatter packages devShells lib;
        }
        )

    );
}
