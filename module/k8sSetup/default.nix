{ trivialBuilders, nixpkgs ? import <nixpkgs> { } }:
let name = "gt-k8s-setup"; in
let version = "1.7.0"; in
let script = builtins.readFile ./default.sh; in
let gattaifile = builtins.readFile ./GattaiFile.yaml; in
let
  write_gattaifile = trivialBuilders.writeTextFile {
    name = "Gattaifile";
    text = gattaifile;
  };
in
trivialBuilders.writeShellApplication {
  name = name;
  version = version;
  runtimeShell = "${nixpkgs.bash}/bin/bash";
  runtimeInputs = (
    with nixpkgs;
    with import (fetchTarball "https://github.com/kirinnee/test-nix-repo/archive/refs/tags/v13.0.0.tar.gz");
    [ gattai figlet gawk coreutils kubectl awscli2 jq ]
  );
  text = ''
    FILEPATH=${write_gattaifile}
    VERSION=${version}
    ${script}
  '';
}
