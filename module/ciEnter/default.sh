#!/bin/bash
set -eo pipefail

echo "🗂️ Version: $VERSION"
echo ""

ips="$(aws --profile dev ec2 describe-instances --region ap-southeast-1 --query 'Reservations[*].Instances[*].[PublicIpAddress]' --filters 'Name=tag:LPSD,Values=runner.systems.github-runner.instance' --output text)"

echo "IPs: $ips"

IFS=$'\n'
for i in $ips; do
  echo "🚪 Entering: github-runner@$i..."
  ssh "github-runner@$i"
  echo "🚶 Completed: github-runner@$i"
done
