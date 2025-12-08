# Faust Test App

This Flutter sample demonstrates an iOS audio pipeline driven by a Faust-generated DSP core. The iOS host owns the generated `DspFaust` sources and exposes lifecycle/parameter controls to Flutter via platform channels, while the Dart UI offers a small control surface for exercising the DSP.

## Project layout
- `dsp/`: Source `.dsp` programs and JSON metadata used to generate the iOS Faust artifacts.
- `ios/Runner/DSP/`: Generated `DspFaust.cpp`/`DspFaust.h` plus inventory/bridge documentation for the iOS target.
- `ios/Runner/FaustAudioEngine.{h,mm}`: Objective-C++ wrapper that owns the Faust engine instance and exposes parameter/lifecycle helpers.
- `ios/Runner/FaustPlatformPlugin.swift`: Flutter plugin wiring method/event channels to the native engine.
- `lib/faust_engine.dart`: Dart service wrapping the platform channel API.
- `lib/main.dart`: Minimal UI for initializing the engine, starting/stopping audio, tweaking parameters, and viewing meter updates.

## iOS build requirements
1. Ensure the generated Faust sources are part of the Runner target (`ios/Runner/DSP/DspFaust.cpp` and `ios/Runner/DSP/DspFaust.h`).
2. Confirm C++17 is enabled for the Runner target (set via `CLANG_CXX_LANGUAGE_STANDARD = c++17` in `Runner.xcodeproj`).
3. Link the iOS frameworks required by the Faust driver: `AudioToolbox` and `AVFoundation` are already referenced; add `CoreMIDI` if MIDI was enabled during generation.
4. The app primes `AVAudioSession` with a 44.1 kHz sample rate and a 512-frame buffer before instantiating `DspFaust`; the wrapper will fall back to the resolved hardware format if different.
5. Platform channels are registered from `AppDelegate` so no additional Flutter configuration is necessary.

## Using the Flutter API
The Dart surface lives in `FaustEngineService` (`lib/faust_engine.dart`). Typical usage:

```dart
final engine = FaustEngineService();

// One-time setup
final ok = await engine.initialize(sampleRate: 44100, bufferSize: 512);
if (!ok) throw Exception('Faust engine failed to initialize');

// Start audio and tweak a parameter
await engine.start();
await engine.setParameter('/CrystalBells/Decay', 0.75);

// Read back current values or build a UI from published parameter addresses
final params = await engine.listParameters();
final decay = await engine.getParameter('/CrystalBells/Decay');

// Optional: listen for meter snapshots (published ~30 Hz)
final sub = engine.meterStream().listen((meters) {
  debugPrint('Level: ${meters.meters['"'"'/CrystalBells/Decay'"'"']}');
});
```

The included demo page (`lib/main.dart`) wraps these calls with buttons, text inputs, and meter readouts so you can verify that parameter changes affect audio output in real time. Run `flutter run` on an iOS device or simulator and press **Initialize** then **Start** to boot the Faust DSP before adjusting values.

## Additional references
- `ios/Runner/DSP/FAUST_INVENTORY.md`: Generated file inventory, licensing, and build flags.
- `ios/Runner/DSP/AUDIO_ENGINE_ENTRYPOINTS.md`: Notes on where the Faust driver and render callbacks run.
- `ios/Runner/DSP/FLUTTER_BRIDGE_API.md`: Method/event channel contract between Dart and iOS.
