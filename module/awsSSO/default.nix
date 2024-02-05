{ trivialBuilders, awsExportCreds, nixpkgs ? import <nixpkgs> { } }:

let name = "gt-aws-login"; in
let version = "1.7.0"; in
let script = builtins.readFile ./default.sh; in
trivialBuilders.writeShellApplication {
  name = name;
  version = version;
  runtimeShell = "${nixpkgs.bash}/bin/bash";
  runtimeInputs = (
    with nixpkgs;
    [ coreutils gnugrep awscli2 jq awsExportCreds ] ++ (if stdenv.isDarwin then [ ] else [ expect ])
  );
  text = ''
    aws="${nixpkgs.awscli2}/bin/aws"
    ${script}
  '';
}
