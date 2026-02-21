#!/bin/bash
set -eo pipefail

# VERSION is injected by nix; fallback for direct execution
VERSION="${VERSION:-1.0.0}"
CF_ACCOUNT_ID="${CLOUDFLARE_ACCOUNT_ID:-9f21cac25548ad04899fc78c8101e7de}"
CF_API_BASE="https://api.cloudflare.com/client/v4/accounts/${CF_ACCOUNT_ID}"
PER_PAGE=50
JSON_OUTPUT=false

# ── Helpers ──────────────────────────────────────────────────────────

validate_id() {
	local id="$1"
	if [[ ! "$id" =~ ^[a-fA-F0-9-]{8,}$ ]]; then
		echo "Error: Invalid ID format: ${id}" >&2
		exit 1
	fi
}

cf_api() {
	local endpoint="$1"
	local url="${CF_API_BASE}/${endpoint}"
	local http_code body tmpfile

	tmpfile=$(mktemp)
	# shellcheck disable=SC2064
	trap "rm -f '$tmpfile'" RETURN

	http_code=$(curl -s -o "$tmpfile" -w "%{http_code}" \
		-H "Authorization: Bearer ${CLOUDFLARE_API_TOKEN}" \
		"${url}")
	body=$(<"$tmpfile")

	if [ "$http_code" -lt 200 ] || [ "$http_code" -ge 300 ]; then
		local errors
		errors=$(echo "$body" | jq -r '.errors[]?.message // empty' 2>/dev/null)
		if [ -n "$errors" ]; then
			echo "Error (HTTP ${http_code}): ${errors}" >&2
		else
			echo "Error: HTTP ${http_code}" >&2
		fi
		return 1
	fi

	local success
	success=$(echo "$body" | jq -r '.success' 2>/dev/null)
	if [ "$success" = "false" ]; then
		local errors
		errors=$(echo "$body" | jq -r '.errors[]?.message // empty' 2>/dev/null)
		echo "API error: ${errors}" >&2
		return 1
	fi

	echo "$body"
}

cf_api_paginated() {
	local endpoint="$1"
	local page=1
	local all_results="[]"

	while true; do
		local sep="?"
		if [[ "$endpoint" == *"?"* ]]; then
			sep="&"
		fi
		local response
		if ! response=$(cf_api "${endpoint}${sep}per_page=${PER_PAGE}&page=${page}"); then
			echo "Error: Failed to fetch page ${page} of ${endpoint}" >&2
			return 1
		fi

		local results
		results=$(echo "$response" | jq '.result')
		all_results=$(echo "$all_results" "$results" | jq -s '.[0] + .[1]')

		local total_pages
		total_pages=$(echo "$response" | jq -r '.result_info.total_pages // empty' 2>/dev/null)
		if [ -z "$total_pages" ]; then
			break
		fi
		if [ "$page" -ge "$total_pages" ]; then
			break
		fi
		page=$((page + 1))
	done

	echo "$all_results"
}

format_table() {
	if command -v column &>/dev/null; then
		column -t -s $'\t'
	else
		cat
	fi
}

check_token() {
	if [ -z "${CLOUDFLARE_API_TOKEN:-}" ]; then
		echo "Error: CLOUDFLARE_API_TOKEN environment variable is not set." >&2
		echo "" >&2
		echo "Set it with:" >&2
		echo "  export CLOUDFLARE_API_TOKEN=\"your-api-token\"" >&2
		exit 1
	fi
}

# ── Subcommands ──────────────────────────────────────────────────────

cmd_apps() {
	local id="${1:-}"
	if [ -n "$id" ]; then
		validate_id "$id"
		local response
		response=$(cf_api "access/apps/${id}")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$response" | jq '.result'
		else
			echo "$response" | jq -r '.result | "Name:      \(.name)\nID:        \(.id)\nDomain:    \(.domain)\nType:      \(.type)\nAUD:       \(.aud)\nCreated:   \(.created_at)\nUpdated:   \(.updated_at)"'
		fi
	else
		local results
		results=$(cf_api_paginated "access/apps")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$results" | jq '.'
		else
			echo "$results" | jq -r '["NAME", "ID", "DOMAIN", "TYPE"], (.[] | [.name, .id, .domain, .type]) | @tsv' | format_table
		fi
	fi
}

cmd_groups() {
	local id="${1:-}"
	if [ -n "$id" ]; then
		validate_id "$id"
		local response
		response=$(cf_api "access/groups/${id}")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$response" | jq '.result'
		else
			echo "$response" | jq -r '.result | "Name:      \(.name)\nID:        \(.id)\nCreated:   \(.created_at)\nUpdated:   \(.updated_at)\nInclude:   \(.include | length) rules\nExclude:   \(.exclude | length) rules\nRequire:   \(.require | length) rules"'
		fi
	else
		local results
		results=$(cf_api_paginated "access/groups")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$results" | jq '.'
		else
			echo "$results" | jq -r '["NAME", "ID", "INCLUDE_RULES", "EXCLUDE_RULES"], (.[] | [.name, .id, (.include | length | tostring), (.exclude | length | tostring)]) | @tsv' | format_table
		fi
	fi
}

cmd_policies() {
	local app_id="${1:-}"
	if [ -z "$app_id" ]; then
		echo "Usage: gt-cf-zerotrust policies <app-id>" >&2
		exit 1
	fi
	validate_id "$app_id"
	local results
	results=$(cf_api_paginated "access/apps/${app_id}/policies")
	if [ "$JSON_OUTPUT" = true ]; then
		echo "$results" | jq '.'
	else
		echo "$results" | jq -r '["NAME", "ID", "DECISION", "PRECEDENCE"], (.[] | [.name, .id, .decision, (.precedence | tostring)]) | @tsv' | format_table
	fi
}

cmd_tunnels() {
	local id="${1:-}"
	if [ -n "$id" ]; then
		validate_id "$id"
		local response
		response=$(cf_api "cfd_tunnel/${id}")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$response" | jq '.result'
		else
			echo "$response" | jq -r '.result | "Name:      \(.name)\nID:        \(.id)\nStatus:    \(.status)\nCreated:   \(.created_at)\nConns:     \(.connections | length) active"'
		fi
	else
		local results
		results=$(cf_api_paginated "cfd_tunnel?is_deleted=false")
		if [ "$JSON_OUTPUT" = true ]; then
			echo "$results" | jq '.'
		else
			echo "$results" | jq -r '["NAME", "ID", "STATUS", "CONNECTIONS"], (.[] | [.name, .id, .status, (.connections | length | tostring)]) | @tsv' | format_table
		fi
	fi
}

cmd_gateway() {
	local response
	response=$(cf_api "gateway")
	if [ "$JSON_OUTPUT" = true ]; then
		echo "$response" | jq '.result'
	else
		echo "$response" | jq -r '.result | "Gateway enabled:    \(.settings.activity_log.enabled // "n/a")\nTLS decrypt:        \(.settings.tls_decrypt.enabled // "n/a")\nAntiVirus:          \(.settings.antivirus.enabled_download_phase // "n/a")\nBlock page:         \(.settings.block_page.enabled // "n/a")"'
	fi
}

cmd_rules() {
	local results
	results=$(cf_api_paginated "gateway/rules")
	if [ "$JSON_OUTPUT" = true ]; then
		echo "$results" | jq '.'
	else
		echo "$results" | jq -r '["NAME", "ID", "ACTION", "ENABLED", "PRECEDENCE"], (.[] | [.name, .id, .action, (if .enabled then "yes" else "no" end), (.precedence | tostring)]) | @tsv' | format_table
	fi
}

cmd_tokens() {
	local results
	results=$(cf_api_paginated "access/service_tokens")
	if [ "$JSON_OUTPUT" = true ]; then
		echo "$results" | jq '.'
	else
		echo "$results" | jq -r '["NAME", "ID", "CLIENT_ID", "EXPIRES_AT"], (.[] | [.name, .id, .client_id, (.expires_at // "never")]) | @tsv' | format_table
	fi
}

show_help() {
	cat <<EOF
gt-cf-zerotrust v${VERSION} - Cloudflare Zero Trust CLI

Usage: gt-cf-zerotrust [--json] [--version] <command> [args]

Commands:
  apps [<id>]           List Access applications or get one by ID
  groups [<id>]         List Access groups or get one by ID
  policies <app-id>     List policies for an Access application
  tunnels [<id>]        List Cloudflare tunnels or get one by ID
  gateway               Show gateway settings
  rules                 List gateway/firewall rules
  tokens                List service tokens
  help                  Show this help message

Options:
  --json                Output raw JSON instead of formatted tables
  --version             Show version
  --help, -h            Show this help message

Environment:
  CLOUDFLARE_API_TOKEN     Required. Your Cloudflare API token.
  CLOUDFLARE_ACCOUNT_ID    Optional. Defaults to gotrade account.

Alias: cfzt

Examples:
  cfzt apps                     List all Access apps
  cfzt --json apps              List apps as raw JSON
  cfzt apps <app-id>            Get details for a specific app
  cfzt policies <app-id>        List policies for an app
  cfzt tunnels                  List all tunnels
EOF
}

# ── Main ─────────────────────────────────────────────────────────────

# Parse global flags
while [[ $# -gt 0 ]]; do
	case "$1" in
	--json)
		JSON_OUTPUT=true
		shift
		;;
	--version)
		echo "gt-cf-zerotrust v${VERSION}"
		exit 0
		;;
	--help | -h)
		show_help
		exit 0
		;;
	-*)
		echo "Unknown option: $1" >&2
		echo "Run 'gt-cf-zerotrust help' for usage." >&2
		exit 1
		;;
	*)
		break
		;;
	esac
done

if [ $# -gt 0 ]; then
	COMMAND="$1"
	shift
else
	COMMAND="help"
fi

case "$COMMAND" in
apps)
	check_token
	cmd_apps "$@"
	;;
groups)
	check_token
	cmd_groups "$@"
	;;
policies)
	check_token
	cmd_policies "$@"
	;;
tunnels)
	check_token
	cmd_tunnels "$@"
	;;
gateway)
	check_token
	cmd_gateway "$@"
	;;
rules)
	check_token
	cmd_rules "$@"
	;;
tokens)
	check_token
	cmd_tokens "$@"
	;;
help) show_help ;;
*)
	echo "Unknown command: ${COMMAND}" >&2
	echo "Run 'gt-cf-zerotrust help' for usage." >&2
	exit 1
	;;
esac
