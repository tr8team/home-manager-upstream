{ nixpkgs, atomi }:
with nixpkgs;
let trivialBuilders = import ./trivialBuilders.nix { inherit lib stdenv stdenvNoCC lndir runtimeShell shellcheck; }; in
{
  awsLogin = import ./awsSSO/default.nix {
    inherit nixpkgs trivialBuilders;
    awsExportCreds = atomi.aws-export-credentials;
  };
  k8sSetup = import ./k8sSetup/default.nix { inherit nixpkgs trivialBuilders atomi; };
  ciEnter = import ./ciEnter/default.nix { inherit nixpkgs trivialBuilders; };
}
