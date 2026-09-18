#!/usr/bin/env python3
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "StandSpace.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")

versions = set(re.findall(r"MARKETING_VERSION = ([0-9.]+);", project))
builds = set(re.findall(r"CURRENT_PROJECT_VERSION = ([0-9]+);", project))
if len(versions) != 1 or len(builds) != 1:
    raise SystemExit(f"version contract failed: versions={sorted(versions)} builds={sorted(builds)}")

version = next(iter(versions))
build = next(iter(builds))

if f"> Current `main`: **{version} (build {build})**" not in readme:
    raise SystemExit("version contract failed: English README status is stale")
if f"> `main` actual: **{version} (build {build})**" not in readme:
    raise SystemExit("version contract failed: Spanish README status is stale")
if f"## {version} (development)" not in changelog:
    raise SystemExit("version contract failed: changelog development version is stale")

with (ROOT / "StandSpace/PrivacyInfo.xcprivacy").open("rb") as handle:
    privacy = plistlib.load(handle)

if privacy.get("NSPrivacyTracking") is not False:
    raise SystemExit("privacy contract failed: tracking must be false")

reasons = {}
for item in privacy.get("NSPrivacyAccessedAPITypes", []):
    reasons[item.get("NSPrivacyAccessedAPIType")] = set(
        item.get("NSPrivacyAccessedAPITypeReasons", [])
    )

if "CA92.1" not in reasons.get("NSPrivacyAccessedAPICategoryUserDefaults", set()):
    raise SystemExit("privacy contract failed: UserDefaults reason CA92.1 is missing")
if "85F4.1" not in reasons.get("NSPrivacyAccessedAPICategoryDiskSpace", set()):
    raise SystemExit("privacy contract failed: disk-space reason 85F4.1 is missing")

hardcoded_teams = [
    value for value in re.findall(r"DEVELOPMENT_TEAM = ([^;]+);", project)
    if value.strip().strip('"')
]
if hardcoded_teams:
    raise SystemExit(f"build contract failed: hardcoded Apple team(s): {hardcoded_teams}")

print(f"PASS: StandSpace {version} (build {build}) version, changelog, privacy, and README contract")
