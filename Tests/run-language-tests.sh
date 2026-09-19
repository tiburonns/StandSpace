#!/bin/zsh
set -euo pipefail

repo_root="${0:A:h:h}"
tmp_dir="$(mktemp -d /tmp/standspace-language-tests.XXXXXX)"
trap 'rm -rf "$tmp_dir"' EXIT

xcrun swiftc   "$repo_root/StandSpace/Shared/AppLanguage.swift"   "$repo_root/StandSpace/Models/DashboardModels.swift"   "$repo_root/Tests/LanguageIntegration.swift"   -o "$tmp_dir/standspace-language-tests"

"$tmp_dir/standspace-language-tests"
