#!/bin/bash
set -eo pipefail

mkdir -p "$HOME/.aws"
# back up prev config if it exist
backup="config-$(date +"%Y-%m-%d-%H-%M-%S").bak"

revert() {
  exit_code="$?"
  if [ "${exit_code}" = '0' ]; then
    echo "✅ AWS Login Suceeded!"
    echo "🗑️ Deleting backup..."
    [ -f "${HOME}/.aws/${backup}" ] && rm "${HOME}/.aws/${backup}"
    echo "✅ Deleted!"

    exit 0
  else
    echo "❌ AWS Login Failed!"
    echo "🔙 Reverting to previous config..."
    [ -f "${HOME}/.aws/${backup}" ] && cp "${HOME}/.aws/${backup}" "${HOME}/.aws/config"
    echo "✅ Reverted!"
    exit "${exit_code}"
  fi
}

trap revert EXIT

if [ -f "${HOME}/.aws/config" ]; then
  echo "🔎 Found existing config!"
  echo "💿 Backing up config to ~/.aws/${backup}..."
  cp "${HOME}/.aws/config" "${HOME}/.aws/${backup}"
  echo "✅ Backup completed!"
fi

echo "🔧 Generating SSO Config..."
touch "${HOME}/.aws/config"

sso_config=$(
  cat <<EndOfMessage
[sso-session okta-gotrade]
sso_start_url = https://gotrade.awsapps.com/start
sso_region = ap-southeast-1
sso_registration_scopes = sso:account:access

[default]
sso_session = okta-gotrade
output = json
sso_start_url = https://gotrade.awsapps.com/start
sso_region = ap-southeast-1

[profile dev]
sso_session = okta-gotrade
region = ap-southeast-1
sso_region = ap-southeast-1
sso_start_url = https://gotrade.awsapps.com/start
sso_account_id = 192819688641
sso_role_name = aws-dev-admin
EndOfMessage
)
echo "$sso_config" >"${HOME}/.aws/config"

echo "🔧 Configuring AWS SSO..."
# shellcheck disable=SC2154
$aws configure sso

echo "🔧 Configuring default profile..."
aws-export-credentials --profile default -c default
echo "🔧 Configuring default dev profile..."
aws-export-credentials --profile dev -c dev
echo "region = ap-southeast-1" >>"${HOME}/.aws/config"
