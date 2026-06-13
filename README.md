# Faust + Flutter Template

A starter template for Flutter apps that use a [Faust](https://faust.grame.fr/)-generated
DSP core for real-time audio. The native side owns the generated `DspFaust` engine and
exposes lifecycle + parameter control to Flutter over platform channels; the Dart side is a
thin, platform-agnostic service plus a small demo UI.

The same Dart API drives **iOS** (Core Audio) and **Android** (miniaudio / AAudio + OpenSL|ES).

## Architecture

```
dsp/demo.dsp                          your Faust program (source of truth)
   │  scripts/generate.sh
   ▼
iOS:     ios/Runner/DSP/DspFaust.{cpp,h}          ← generated
         ios/Runner/FaustAudioEngine.{h,mm}       Obj-C++ wrapper (stable)
         ios/Runner/FaustPlatformPlugin.swift     method/event channels (stable)
Android: android/app/src/main/cpp/*.{cpp,h}       ← generated (+ CMakeLists.txt, stable)
         android/app/src/main/java/com/DspFaust/  ← generated SWIG bindings
         android/app/src/main/kotlin/dev/faust/FaustPlatformPlugin.kt   (stable)
   │
   ▼
lib/faust_engine.dart                 Dart service over channels (stable)
lib/main.dart                         demo control surface
```

Everything marked **(stable)** is written against the fixed `DspFaust` API and does **not**
change when you swap the `.dsp` source. Only the generated files change.

## Prerequisites

- Flutter 3.44+ and the Dart SDK.
- The **Faust toolchain** on your `PATH` (provides `faust` and `faust2api`):
  `brew install faust`, or build from <https://github.com/grame-cncm/faust>.
- **iOS:** Xcode, a configured signing team.
- **Android:** the Android SDK, the **NDK** (CMake build), and a JDK — all standard with
  Android Studio.

## Quick start

```bash
# 1. Rebrand the template (Dart package, bundle ids, display name).
scripts/rename.sh my_synth_app com.acme "My Synth App"

# 2. Generate the native DSP from dsp/demo.dsp for both platforms.
scripts/generate.sh all

# 3. Run.
flutter pub get
flutter run            # pick an iOS or Android target
```

In the app: press **Initialize**, then **Start**, then tap a parameter chip to read/set it.

## Swapping in your own DSP

1. Edit `dsp/demo.dsp`, or copy one of the synths in `dsp/examples/` over it, or point the
   generator at any file:

   ```bash
   scripts/generate.sh all dsp/examples/glitch_suite.dsp
   ```

2. Rebuild (`flutter run`). The new parameter addresses appear automatically in the demo UI
   via `listParameters()`.

`scripts/generate.sh [ios|android|all] [path/to.dsp]` — defaults to `all` and `dsp/demo.dsp`.

### Parameter addresses

Addresses come from the Faust UI labels. `dsp/demo.dsp` publishes:

| Address              | Kind      | Notes                                            |
| -------------------- | --------- | ------------------------------------------------ |
| `/FaustDemo/freq`    | hslider   | Oscillator frequency (Hz)                        |
| `/FaustDemo/gain`    | hslider   | Output gain                                       |
| `/FaustDemo/gate`    | button    | 0/1 note gate driving the ADSR                    |
| `/FaustDemo/level`   | hbargraph | **Real** smoothed output level — read-only meter |

Group your sliders under `h:Name/...` or `declare name "Name";` to control the address prefix.

## Real meters

A Faust `*bargraph` is a read-only parameter. The demo's `/FaustDemo/level` follows the actual
output amplitude, so the meter `EventChannel` reports a true level rather than echoing a control
value. The meter stream simply polls every published address at ~30 Hz; bargraph addresses are
the ones that carry meaningful meter data.

## Renaming

`scripts/rename.sh <package_name> <org> ["Display Name"]` updates, from a clean tree:

- Dart package (`pubspec.yaml`, test imports)
- Android `applicationId` / `namespace`, manifest label, and the Kotlin package directory
- iOS `PRODUCT_BUNDLE_IDENTIFIER` (camelCase) and display name

Review with `git diff`, then `flutter pub get && flutter analyze`. The generated Faust Java
package stays `com.DspFaust` (it is independent of your app id).

## Using the Dart API

```dart
final engine = FaustEngineService();

final ok = await engine.initialize(sampleRate: 44100, bufferSize: 512);
if (!ok) throw Exception('Faust engine failed to initialize');

await engine.start();
await engine.setParameter('/FaustDemo/freq', 660);
await engine.setParameter('/FaustDemo/gate', 1); // trigger the envelope

final params = await engine.listParameters();
final level = await engine.getParameter('/FaustDemo/level');

final sub = engine.meterStream().listen((e) {
  debugPrint('level: ${e.meters['/FaustDemo/level']}');
});
```

## Platform notes

### iOS
- The generated `DspFaust.{cpp,h}` are already referenced by the Runner target; regeneration
  overwrites them in place, so no Xcode changes are needed.
- C++17 is enabled (`CLANG_CXX_LANGUAGE_STANDARD = c++17`). Linked frameworks: `AudioToolbox`,
  `AVFoundation` (add `CoreMIDI` only if you regenerate with `-midi`).
- `AppDelegate` primes `AVAudioSession` at 44.1 kHz / 512 frames; the wrapper falls back to the
  resolved hardware format if it differs.

### Android
- The native engine builds via CMake (`android/app/src/main/cpp/CMakeLists.txt`) into
  `libdsp_faust.so`, loaded by the generated `com.DspFaust` SWIG classes.
- Audio backend is **miniaudio**, which runtime-links AAudio (API 26+) and falls back to
  OpenSL|ES — no Oboe dependency. Playback needs no runtime permission.
- `abiFilters` is set to `armeabi-v7a, arm64-v8a, x86_64`; trim it in `build.gradle.kts` to
  speed up local builds.

> **Verification status:** the iOS path is the original, working integration. The Android
> engine is newly added and is statically wired but has not yet been built on a device in this
> repo (no NDK/JDK in the authoring environment). Before relying on it, confirm:
> 1. `flutter build apk --debug` compiles the native library;
> 2. audio plays on a physical device;
> 3. `listParameters` / `setParameter` / the meter stream behave as on iOS.

## Additional references
- `ios/Runner/DSP/docs/FAUST_INVENTORY.md` — generated file inventory, licensing, build flags.
- `ios/Runner/DSP/docs/AUDIO_ENGINE_ENTRYPOINTS.md` — where the iOS driver and render callback run.
- `ios/Runner/DSP/docs/FLUTTER_BRIDGE_API.md` — the method/event channel contract.

## Licensing
Faust-generated sources carry GPLv3 **with the Faust architecture exception**, which permits
inclusion in larger works (including closed-source apps) without licensing the non-Faust parts.
See `FAUST_INVENTORY.md` for details.
