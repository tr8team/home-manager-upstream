#!/bin/bash
set -eo pipefail

SSO_PORTAL="https://signin-cn-hongkong.alibabacloudsso.com/gotrade/login"
CONFIG_DIR="$HOME/.aliyun"
CONFIG_FILE="$CONFIG_DIR/config.json"

mkdir -p "$CONFIG_DIR"
chmod 700 "$CONFIG_DIR"

# back up prev config if it exists
backup="config-$(date +"%Y-%m-%d-%H-%M-%S").bak"

revert() {
	exit_code="$?"
	if [ "${exit_code}" = '0' ]; then
		echo "✅ Alicloud Login Succeeded!"
		echo "🗑️ Deleting backup..."
		[ -f "${CONFIG_DIR}/${backup}" ] && rm "${CONFIG_DIR}/${backup}"
		echo "✅ Deleted!"
		exit 0
	else
		echo "❌ Alicloud Login Failed!"
		echo "🔙 Reverting to previous config..."
		[ -f "${CONFIG_DIR}/${backup}" ] && cp "${CONFIG_DIR}/${backup}" "${CONFIG_FILE}"
		echo "✅ Reverted!"
		exit "${exit_code}"
	fi
}

trap revert EXIT

if [ -f "${CONFIG_FILE}" ]; then
	echo "🔎 Found existing config!"
	echo "💿 Backing up config to ${CONFIG_DIR}/${backup}..."
	cp "${CONFIG_FILE}" "${CONFIG_DIR}/${backup}"
	echo "✅ Backup completed!"
fi

echo ""
echo "🌐 Opening Alicloud Cloud SSO portal..."
echo "   ${SSO_PORTAL}"
echo ""

# Open browser (macOS: open, Linux: xdg-open)
if command -v open &>/dev/null; then
	open "${SSO_PORTAL}"
elif command -v xdg-open &>/dev/null; then
	xdg-open "${SSO_PORTAL}"
else
	echo "⚠️  Could not open browser automatically. Please visit the URL above."
fi

echo "📋 Instructions:"
echo "   1. Log in with your Cloud SSO credentials"
echo "   2. Select your role (e.g. alicloud-admin)"
echo "   3. Click 'Programmatic Access' to get temporary credentials"
echo ""
echo "🔧 Paste your temporary credentials below:"
echo ""

read -rp "   AccessKey ID: " ak_id
read -rsp "   AccessKey Secret: " ak_secret
echo
read -rsp "   Security Token: " sts_token
echo

if [ -z "$ak_id" ] || [ -z "$ak_secret" ] || [ -z "$sts_token" ]; then
	echo "❌ All three fields are required."
	exit 1
fi

echo ""
echo "🔧 Writing Alicloud CLI config..."

# Use jq for safe JSON construction (no shell injection via special chars)
config=$(jq -n \
	--arg ak_id "$ak_id" \
	--arg ak_secret "$ak_secret" \
	--arg sts_token "$sts_token" \
	'{
		current: "default",
		profiles: [{
			name: "default",
			mode: "StsToken",
			access_key_id: $ak_id,
			access_key_secret: $ak_secret,
			sts_token: $sts_token,
			region_id: "ap-southeast-5",
			output_format: "json",
			language: "en"
		}],
		meta_path: ""
	}')
echo "$config" >"${CONFIG_FILE}"
chmod 600 "${CONFIG_FILE}"

echo "✅ Alicloud CLI configured (profile: default, region: ap-southeast-5)"

# Write env file for Terraform/SDK compatibility
ENV_FILE="${CONFIG_DIR}/env"
cat >"${ENV_FILE}" <<ENDOFENV
export ALICLOUD_ACCESS_KEY="${ak_id}"
export ALICLOUD_SECRET_KEY="${ak_secret}"
export ALICLOUD_SECURITY_TOKEN="${sts_token}"
export ALICLOUD_REGION="ap-southeast-5"
ENDOFENV
chmod 600 "${ENV_FILE}"

echo "✅ Terraform env vars written to ${ENV_FILE}"
echo ""
echo "💡 To load env vars in your current shell, run:"
echo "   source ~/.aliyun/env"
