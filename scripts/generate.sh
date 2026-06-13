#!/usr/bin/env bash
#
# Regenerate the native Faust DSP sources for this template from a .dsp file.
#
# Usage:
#   scripts/generate.sh [ios|android|all] [path/to/source.dsp]
#
# Defaults: target = all, source = dsp/demo.dsp
#
# Requires the Faust toolchain on PATH (provides `faust` and `faust2api`).
#   macOS:  brew install faust   (or build from https://github.com/grame-cncm/faust)
#
# What it does:
#   - iOS:     writes ios/Runner/DSP/DspFaust.{cpp,h}
#   - android: writes android/app/src/main/cpp/{DspFaust.cpp,DspFaust.h,java_interface_wrap.cpp}
#              and android/app/src/main/java/com/DspFaust/*.java
#
# The native wrappers (FaustAudioEngine.mm, FaustPlatformPlugin.swift, the
# Kotlin plugin and CMakeLists.txt) are written against the stable DspFaust API
# and do NOT need to change when you swap the .dsp source.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET="${1:-all}"
DSP_SRC="${2:-$ROOT/dsp/demo.dsp}"

# Faust package name for the generated Android Java classes. Kept constant and
# independent of the app's applicationId; the Kotlin plugin imports from here.
ANDROID_JAVA_PKG="com.DspFaust"

if ! command -v faust2api >/dev/null 2>&1; then
  echo "error: faust2api not found on PATH. Install the Faust toolchain first." >&2
  exit 1
fi
if [[ ! -f "$DSP_SRC" ]]; then
  echo "error: dsp source not found: $DSP_SRC" >&2
  exit 1
fi

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
cp "$DSP_SRC" "$WORK/"
DSP_NAME="$(basename "$DSP_SRC")"

gen_ios() {
  echo "==> Generating iOS DSP from $DSP_NAME"
  ( cd "$WORK" && faust2api -ios -nozip -target ios_out "$DSP_NAME" )
  local dst="$ROOT/ios/Runner/DSP"
  mkdir -p "$dst"
  cp "$WORK/ios_out/DspFaust.cpp" "$dst/DspFaust.cpp"
  cp "$WORK/ios_out/DspFaust.h"   "$dst/DspFaust.h"
  echo "    wrote $dst/DspFaust.{cpp,h}"
}

gen_android() {
  echo "==> Generating Android DSP from $DSP_NAME"
  ( cd "$WORK" && faust2api -android -nozip -target android_out "$DSP_NAME" )
  local cpp_dst="$ROOT/android/app/src/main/cpp"
  local java_dst="$ROOT/android/app/src/main/java/${ANDROID_JAVA_PKG//.//}"
  mkdir -p "$cpp_dst" "$java_dst"
  cp "$WORK/android_out/cpp/DspFaust.cpp"           "$cpp_dst/DspFaust.cpp"
  cp "$WORK/android_out/cpp/DspFaust.h"             "$cpp_dst/DspFaust.h"
  cp "$WORK/android_out/cpp/java_interface_wrap.cpp" "$cpp_dst/java_interface_wrap.cpp"
  cp "$WORK/android_out/java/"*.java                "$java_dst/"

  # faust2api -android emits the Oboe-based ANDROID_DRIVER, which requires the Oboe
  # headers/lib. We instead use the self-contained miniaudio backend (it runtime-links
  # AAudio/OpenSL|ES via dlopen), so CMakeLists only links log + android and needs no
  # Oboe dependency. The DspFaust(int SR, int BS) constructor used by the Kotlin plugin
  # supports the miniaudio code path.
  sed -i '' '1s/^#define ANDROID_DRIVER 1$/#define MINIAUDIO_DRIVER 1/' "$cpp_dst/DspFaust.cpp"
  echo "    wrote $cpp_dst/*.cpp,*.h and $java_dst/*.java (miniaudio backend)"
}

case "$TARGET" in
  ios)     gen_ios ;;
  android) gen_android ;;
  all)     gen_ios; gen_android ;;
  *) echo "error: unknown target '$TARGET' (expected ios|android|all)" >&2; exit 1 ;;
esac

echo "Done."
