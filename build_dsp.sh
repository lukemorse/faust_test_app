#!/usr/bin/env bash
set -euo pipefail

DSP_FILE="${1:?Usage: ./build_dsp.sh <file.dsp> [--run]}"
RUN_AFTER="${2:-}"

echo "==> Generating iOS API from $DSP_FILE"
faust2api -ios -nozip "$DSP_FILE"

echo "==> Copying generated sources to ios/Runner/DSP/"
cp dsp-faust/DspFaust.cpp dsp-faust/DspFaust.h ios/Runner/DSP/

echo "==> Cleaning up generated folder"
rm -rf dsp-faust

echo "==> Done. iOS sources updated."

if [ "$RUN_AFTER" = "--run" ]; then
  echo "==> Building and running Flutter app"
  flutter run
fi
