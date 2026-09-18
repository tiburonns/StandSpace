#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
temp_dir="$(mktemp -d /tmp/standspace-tests.XXXXXX)"
test_binary="$temp_dir/standspace-layout-tests"
trap 'rm -rf "$temp_dir"' EXIT

xcrun swiftc -parse-as-library \
  "$repo_root/StandSpace/Models/DashboardModels.swift" \
  "$repo_root/StandSpace/Shared/DashboardGridLayout.swift" \
  "$repo_root/Tests/LayoutIntegration.swift" \
  -o "$test_binary"

"$test_binary"
