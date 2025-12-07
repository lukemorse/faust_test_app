# Faust iOS Artifacts Inventory

## Generated Sources
- `ios/Runner/DSP/DspFaust.cpp`: Generated Faust C++ DSP implementation targeting iOS. Header comments note Faust 2.81.10 and the compile invocation (`-a api/DspFaust.cpp -lang cpp -i -ct 1 -es 1 -mcd 16 -mdd 1024 -mdy 33 -single -ftz 0`). Also defines `IOS_DRIVER` for the build. Licensing is GPLv3 with the Faust architecture exception and includes LGPL components (e.g., `misc.h`).
- `ios/Runner/DSP/DspFaust.h`: Generated C++ API surface for the Faust DSP object with GPLv3 + exception notice.
- `ios/Runner/DSP/README.md`: Generated integration guide covering framework requirements (AudioToolbox and optional CoreMIDI) and API usage.

## Project Integration
- Xcode project entries add `DspFaust.h` and `DspFaust.cpp` to the Runner target sources in `ios/Runner.xcodeproj/project.pbxproj`. No custom Faust build script phases are present.
- `ios/Runner/Runner-Bridging-Header.h` is available for exposing C++ symbols to Swift, but no additional Objective-C/Swift Faust sources were generated beyond the stock Flutter template files.

## Licensing Notes
- Both generated C++ files carry a GPLv3 license with the Faust architecture exception allowing inclusion in larger works without altering the Faust sections. Embedded utility headers (e.g., `misc.h`) are under LGPL-2.1+ with the same exception.

## Build Flags and Dependencies
- Compile options used by Faust: `-a api/DspFaust.cpp -lang cpp -i -ct 1 -es 1 -mcd 16 -mdd 1024 -mdy 33 -single -ftz 0`.
- Macro defined at the top of `DspFaust.cpp`: `IOS_DRIVER` (set to 1) to select the iOS audio driver layer.
- Required frameworks noted by the generator docs: `AudioToolbox` (always) and `CoreMIDI` when MIDI support is enabled.
