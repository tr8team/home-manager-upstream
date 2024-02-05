# Gotrade Home-Manager Configuration

A [home-manager](https://github.com/nix-community/home-manager) configuration for gotrade, which include ZSH plugins, configurations and basic binaries used for development.

## Get Started

To use this home-manager configuration, home-manager is needed. Here, I will document both the official way and a convenience script.

### Official

1. Install [nix](https://github.com/NixOS/nix#installation)
2. Install [Home Manager](https://nix-community.github.io/home-manager/index.html#sec-install-standalone)
3. You can edit/update the folder `nixpkgs` at `~/.config/nixpkgs`

### Convenience Script

#### Install Home-Manager

```bash
curl -L https://raw.githubusercontent.com/tr8team/home-manager/main/scripts/home-manager.sh | sh
```

#### Edit your information

Go to `user_config.nix` and edit the fields

| Field     | Description                                                     | Values                                                |
| --------- | --------------------------------------------------------------- | ----------------------------------------------------- |
| `user`    | Your machine's user. You can check this by running `echo $USER` | any                                                   |
| `email`   | Your Github and git's email (must be same)                      | any valid email                                       |
| `gituser` | Github and git's name (must be the same)                        | any valid username/name                               |
| `system`  | Operating system enums                                          | See [Operating System Enums](#operating-system-enums) |

#### Operating System Enums

| Operating System | Value            |
| ---------------- | ---------------- |
| M1 MacBook       | `aarch64-darwin` |
| Intel MacBook    | `x86_64-darwin`  |
| Intel Linux      | `x86_64-linux`   |
| ARM Linux        | `aarch64-linux`  |
