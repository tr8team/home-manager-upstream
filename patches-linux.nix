{ nixpkgs, atomi }:
with nixpkgs;
let modules = import ./module/default.nix { inherit nixpkgs atomi; }; in
with modules;
{
  tools = [
    awsLogin
    k8sSetup
    kubectx
    awscli2
    ciEnter
  ];

  preZSH = ''
    # This is to initialize nix
    if [ -e '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh' ]; then
        . '/nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh'
    fi
    if [ -e $HOME/.nix-profile/etc/profile.d/nix.sh ]; then . $HOME/.nix-profile/etc/profile.d/nix.sh; fi
  '';
  postZSH = ''
  '';

  envVars = {
    AWS_PROFILE = "default";
  };

  path = [ ];

  programs = {
    home-manager = {
      enable = true;
    };
    direnv = {
      enable = true;
      enableZshIntegration = true;
      stdlib = ''
        : "''${XDG_CACHE_HOME:="''${HOME}/.cache"}"
        declare -A direnv_layout_dirs
        direnv_layout_dir() {
            local hash path
            echo "''${direnv_layout_dirs[$PWD]:=$(
                hash="$(sha1sum - <<< "$PWD" | head -c40)"
                path="''${PWD//[^a-zA-Z0-9]/-}"
                echo "''${XDG_CACHE_HOME}/direnv/layouts/''${hash}''${path}"
            )}"
        }
      '';
      nix-direnv = {
        enable = true;
      };
    };
  };

  oh-my-zsh-plugins = [ ];

  shellAliases = {
    start-ci = "aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters 'Name=tag:LPSD,Values=runner.systems.github-runner.instance' --output text | xargs aws ec2 start-instances --instance-ids | cat";
    stop-ci = "aws ec2 describe-instances --query 'Reservations[*].Instances[*].[InstanceId]' --filters 'Name=tag:LPSD,Values=runner.systems.github-runner.instance' --output text | xargs aws ec2 stop-instances --instance-ids | cat";
    awsl = "gt-aws-login";
    k8s-setup = "gt-k8s-setup";
    kctx = "kubectx";
    kns = "kubens";
  };

}
