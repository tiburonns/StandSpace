#!/usr/bin/env python3
import plistlib
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
project = (ROOT / "StandSpace.xcodeproj/project.pbxproj").read_text(encoding="utf-8")
readme = (ROOT / "README.md").read_text(encoding="utf-8")
changelog = (ROOT / "CHANGELOG.md").read_text(encoding="utf-8")
app_language = (ROOT / "StandSpace/Shared/AppLanguage.swift").read_text(encoding="utf-8")
testing_en = (ROOT / "docs/TESTING.md").read_text(encoding="utf-8")
testing_es = (ROOT / "docs/TESTING.es.md").read_text(encoding="utf-8")

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

if not testing_en.startswith(f"# StandSpace {version} "):
    raise SystemExit("version contract failed: English physical test plan is stale")
if not testing_es.startswith(f"# StandSpace {version} "):
    raise SystemExit("version contract failed: Spanish physical test plan is stale")
if "docs/TESTING.md" not in readme or "docs/TESTING.es.md" not in readme:
    raise SystemExit("documentation contract failed: README does not link both physical test plans")

for required_region in ["en", "es"]:
    if f"\t\t\t\t{required_region}," not in project:
        raise SystemExit(f"localization contract failed: missing {required_region} project region")

if "InfoPlist.strings in Resources" not in project:
    raise SystemExit("localization contract failed: InfoPlist.strings is not bundled")
if "AppLanguage.swift in Sources" not in project:
    raise SystemExit("localization contract failed: AppLanguage.swift is not compiled")
for language_case in ["case system", "case english", "case spanish"]:
    if language_case not in app_language:
        raise SystemExit(f"localization contract failed: missing {language_case}")
for localized_file in [
    ROOT / "StandSpace/en.lproj/InfoPlist.strings",
    ROOT / "StandSpace/es.lproj/InfoPlist.strings",
]:
    if not localized_file.exists():
        raise SystemExit(f"localization contract failed: missing {localized_file}")

localization_sources = {
    "EditorView.swift": (ROOT / "StandSpace/Views/EditorView.swift").read_text(encoding="utf-8"),
    "DashboardView.swift": (ROOT / "StandSpace/Views/DashboardView.swift").read_text(encoding="utf-8"),
    "StandbyPages.swift": (ROOT / "StandSpace/Views/StandbyPages.swift").read_text(encoding="utf-8"),
}
forbidden_localization_regressions = {
    "EditorView.swift": [
        'Section("Diseño")',
        '.navigationTitle("Agregar módulo")',
        'Button("Cerrar")',
    ],
    "DashboardView.swift": [
        'Text("Editar StandSpace")',
        'Text("Listo")',
        '.accessibilityLabel(\n                        "Diseño horizontal"\n                    )',
    ],
    "StandbyPages.swift": [
        'Text("Fotos")',
        'Button("Permitir acceso")',
        '@State private var title = "Música"',
        '@State private var artist = "Nada reproduciéndose"',
    ],
}
for filename, fragments in forbidden_localization_regressions.items():
    source = localization_sources[filename]
    for fragment in fragments:
        if fragment in source:
            raise SystemExit(
                f"localization contract failed: {filename} regressed to a hardcoded user-facing string: {fragment}"
            )

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
