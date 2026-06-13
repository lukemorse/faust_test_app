#!/usr/bin/env bash
#
# Rebrand this template: replace the default app identity everywhere.
#
# Usage:
#   scripts/rename.sh <package_name> <org> ["Display Name"]
#
#   package_name : snake_case Dart/Android app name, e.g. my_synth_app
#   org          : reverse-DNS organization prefix, e.g. com.acme
#   Display Name : human-facing app name (optional; defaults from package_name)
#
# Example:
#   scripts/rename.sh my_synth_app com.acme "My Synth App"
#
# Resulting identifiers:
#   Dart package         : my_synth_app
#   Android applicationId: com.acme.my_synth_app
#   iOS bundle id        : com.acme.mySynthApp
#
# Run from a clean git tree so you can review (and revert) the diff.
set -euo pipefail

if [[ $# -lt 2 ]]; then
  echo "usage: scripts/rename.sh <package_name> <org> [\"Display Name\"]" >&2
  exit 1
fi

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

NEW_PKG="$1"
NEW_ORG="$2"

if [[ ! "$NEW_PKG" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "error: package_name must be lower_snake_case (got '$NEW_PKG')" >&2
  exit 1
fi
if [[ ! "$NEW_ORG" =~ ^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$ ]]; then
  echo "error: org must be reverse-DNS like com.acme (got '$NEW_ORG')" >&2
  exit 1
fi

camel() { echo "$1" | awk -F_ '{o=$1; for(i=2;i<=NF;i++){o=o toupper(substr($i,1,1)) substr($i,2)} print o}'; }
title() { echo "$1" | awk -F_ '{for(i=1;i<=NF;i++){$i=toupper(substr($i,1,1)) substr($i,2)} print}' OFS=' '; }

NEW_CAMEL="$(camel "$NEW_PKG")"
NEW_DISPLAY="${3:-$(title "$NEW_PKG")}"

OLD_PKG="faust_test_app"
OLD_CAMEL="faustTestApp"
OLD_ORG="com.example"
OLD_DISPLAY="Faust Test App"

# In-place sed that works on both BSD (macOS) and GNU sed.
sedi() { if sed --version >/dev/null 2>&1; then sed -i "$@"; else sed -i '' "$@"; fi; }

echo "==> Renaming: $OLD_PKG -> $NEW_PKG | $OLD_ORG -> $NEW_ORG | \"$OLD_DISPLAY\" -> \"$NEW_DISPLAY\""

# iOS camelCase bundle segment first (does not overlap snake_case form).
sedi "s/${OLD_CAMEL}/${NEW_CAMEL}/g" ios/Runner.xcodeproj/project.pbxproj

# Snake-case Dart/Android name (pubspec, test imports, CFBundleName, manifest label).
sedi "s/${OLD_PKG}/${NEW_PKG}/g" \
  pubspec.yaml \
  test/widget_test.dart \
  test/faust_engine_test.dart \
  ios/Runner/Info.plist \
  android/app/build.gradle.kts \
  android/app/src/main/AndroidManifest.xml

# Org prefix (Android namespace/applicationId, iOS bundle prefix, Kotlin package).
sedi "s/${OLD_ORG}/${NEW_ORG}/g" \
  ios/Runner.xcodeproj/project.pbxproj \
  android/app/build.gradle.kts

# Human-facing display name.
sedi "s/${OLD_DISPLAY}/${NEW_DISPLAY}/g" ios/Runner/Info.plist

# Move the Kotlin source into its new package directory and fix the package decl.
OLD_KT_DIR="android/app/src/main/kotlin/${OLD_ORG//.//}/${OLD_PKG}"
NEW_KT_DIR="android/app/src/main/kotlin/${NEW_ORG//.//}/${NEW_PKG}"
if [[ -d "$OLD_KT_DIR" ]]; then
  mkdir -p "$NEW_KT_DIR"
  for kt in "$OLD_KT_DIR"/*.kt; do
    [[ -e "$kt" ]] || continue
    sedi "s/package ${OLD_ORG}\.${OLD_PKG}/package ${NEW_ORG}.${NEW_PKG}/g" "$kt"
    git mv "$kt" "$NEW_KT_DIR/$(basename "$kt")" 2>/dev/null \
      || mv "$kt" "$NEW_KT_DIR/$(basename "$kt")"
  done
  # Prune now-empty old package directories up to the kotlin root.
  find android/app/src/main/kotlin -type d -empty -delete
fi

echo "Done. Review the diff with: git status && git diff"
echo "Then run: flutter pub get && flutter analyze"
