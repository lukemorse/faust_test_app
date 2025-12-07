# iOS audio engine entry points

Current iOS target (as in the latest `main`) is the default Flutter runner without a native audio engine. Audio-specific code paths are limited to the standard Flutter `AppDelegate` bootstrap and a bridging header that exposes the generated Faust C wrapper to Swift.

## Existing native touchpoints
- **`ios/Runner/AppDelegate.swift`**: Default Flutter entry point that simply registers plugins in `application(_:didFinishLaunchingWithOptions:)`. No audio session configuration, audio graphs, or render callbacks exist.
- **`ios/Runner/Runner-Bridging-Header.h`**: Imports `faust_c_wrapper.h`, making the generated Faust DSP shim visible to Swift. Nothing in the Runner currently instantiates or drives the DSP.

## Implications for integration
- Because there is no pre-existing audio engine, you will need to add one (e.g., based on `AVAudioEngine` or a custom Core Audio render callback) before wiring in the Faust DSP.
- The bridging header already exposes the Faust wrapper to Swift, so a Swift audio engine module can directly call `faust_create`, `faust_process`, and parameter getters/setters once implemented.
- Decide whether the audio engine will live in the Runner target or a separate Swift module; either way, you will also need to create the Flutter platform channel/FFI surface for Dart to control it.
