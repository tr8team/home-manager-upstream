{ atomi }:
{ nixpkgs, outputs, user_config }:
# Check operating system
let linux = user_config.kernel == "linux"; in

# Obtain Patch
let
  darwinPatch = import ./patches-darwin.nix {
    inherit atomi nixpkgs;
  };
in
let
  linuxPatch = import ./patches-linux.nix {
    inherit atomi nixpkgs;
  };
in
let patches = if linux then linuxPatch else darwinPatch; in

# inject tools
let tools = outputs.home.packages ++ patches.tools; in
let
  output1 = builtins.mapAttrs
    (n: v:
      if n == "home" then
        (
          builtins.mapAttrs (n1: v1: if n1 == "packages" then tools else v1) v
        ) else v)
    outputs;
in

#inject ZSH
let zsh = output1.programs.zsh.initExtra; in
let zshNew = patches.preZSH + zsh + patches.postZSH; in
let
  output2 = builtins.mapAttrs
    (n: v:
      if n == "programs" then
        (
          builtins.mapAttrs
            (n1: v1:
              if n1 == "zsh" then
                (
                  builtins.mapAttrs (n2: v2: if n2 == "initExtra" then zshNew else v2) v1
                ) else v1)
            v
        ) else v)
    output1;
in

# inject envVars
let envVars = output2.home.sessionVariables // patches.envVars; in
let
  output3 = builtins.mapAttrs
    (n: v:
      if n == "home" then
        (
          builtins.mapAttrs (n1: v1: if n1 == "sessionVariables" then envVars else v1) v
        ) else v)
    output2;
in

# inject PATH
let path = output3.home.sessionPath ++ patches.path; in
let
  output4 = builtins.mapAttrs
    (n: v:
      if n == "home" then
        (
          builtins.mapAttrs (n1: v1: if n1 == "sessionPath" then path else v1) v
        ) else v)
    output3;
in


# inject program configurations
let programs = output4.programs // patches.programs; in
let
  output5 = builtins.mapAttrs (n: v: if n == "programs" then programs else v) output4;
in

# inject oh-my-zsh-plugins
let omz-plugins = output5.programs.zsh.oh-my-zsh.plugins ++ patches.oh-my-zsh-plugins; in
let
  output6 = builtins.mapAttrs
    (n: v:
      if n == "programs" then
        (
          builtins.mapAttrs
            (n1: v1:
              if n1 == "zsh" then
                (
                  builtins.mapAttrs
                    (n2: v2:
                      if n2 == "oh-my-zsh" then
                        (
                          builtins.mapAttrs (n3: v3: if n3 == "plugins" then omz-plugins else v3) v2
                        ) else v2)
                    v1
                ) else v1)
            v
        ) else v)
    output5;
in


# inject shell aliases
let aliases = output6.programs.zsh.shellAliases // patches.shellAliases; in
let
  output7 = builtins.mapAttrs
    (n: v:
      if n == "programs" then
        (
          builtins.mapAttrs
            (n1: v1:
              if n1 == "zsh" then
                (
                  builtins.mapAttrs (n2: v2: if n2 == "shellAliases" then aliases else v2) v1
                ) else v1)
            v
        ) else v)
    output6;
in

# return
output7
