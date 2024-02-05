#!/bin/bash
set -eo pipefail

figlet -f starwars -c ESD K8S KIT

echo "🗂️ Version: $VERSION"
echo ""

echo "📁 Deleting directory..."
if [ -d "${HOME}/.kube/configs" ]; then
  echo "Deleting folder configs"
  rm -rf ~/.kube/configs
else echo "Folder configs does not exist"; fi
if [ -d "${HOME}/.kube/cache/oidc-login" ]; then
  echo "Deleting folder oidc-login"
  rm -rf ~/.kube/cache/oidc-login
else echo "Folder oidc-login does not exist"; fi
echo "✅ Directories deleted!"
echo ""
echo "📤 Backing up previous kubeconfig if it exist..."
mkdir -p "$HOME/.kube/backups"
[ -f "${HOME}/.kube/config" ] && cp ~/.kube/config "${HOME}/.kube/backups/config-$(date +"%Y-%m-%d-%H-%M-%S").bak"
echo "✅ Backup completed!"
echo ""
echo "📁 Creating necessary directory..."
mkdir -p ~/.kube/configs
mkdir -p ~/.kube/k3dconfigs
echo "✅ Directories created!"
echo ""
echo "⏬ Using gattai to retrieve kube configs..."
gattai run kubeconfig_files all "${FILEPATH}"
echo "✅ Kubeconfig obtained!"
echo ""
echo "🧩 Merging all kubeconfigs together..."
KUBECONFIG=$(cd ~/.kube/configs && find "$(pwd)"/* | awk 'ORS=":"')$(cd ~/.kube/k3dconfigs && find "$(pwd)"/* | awk 'ORS=":"') kubectl config view --flatten >~/.kube/config
chmod 600 ~/.kube/config
echo "✅ Final kube config completed!"
echo ""
echo "🚀 You can now access the clusters!"
