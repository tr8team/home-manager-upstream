{ trivialBuilders, nixpkgs }:
let name = "gt-ci-enter"; in
let version = "1.0.0"; in
let script = builtins.readFile ./default.sh; in
trivialBuilders.writeShellApplication {
  name = name;
  version = version;
  runtimeShell = "${nixpkgs.bash}/bin/bash";
  runtimeInputs = (
    with nixpkgs;
    [ coreutils awscli2 ]
  );
  text = ''
    VERSION=${version}
    ${script}
  '';
}
