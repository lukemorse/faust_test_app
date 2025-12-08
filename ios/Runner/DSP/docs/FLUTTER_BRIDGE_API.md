# Flutter platform channel surface for Faust

This note defines the Dart↔︎iOS API surface used to drive the embedded Faust DSP from Flutter. The initial integration favors `MethodChannel`/`EventChannel` for their ergonomics and hot-reload friendliness. The audio engine continues to run wholly on the native side; channels only configure DSP parameters or report meters.

## Channels

* **Control:** `dev.faust/engine`
  * Registered from `AppDelegate` against the root `FlutterViewController`.
  * Methods complete on the main thread but dispatch into `FaustAudioEngine` synchronously (control calls are cheap relative to render callbacks).
* **Meters/Events:** `dev.faust/engine/meters`
  * `EventChannel` backed by a custom `FlutterStreamHandler`.
  * Emits periodic dictionaries containing parameter/meter values so Flutter can render level meters without polling.

## Methods

| Method | Arguments | Returns | Notes |
| --- | --- | --- | --- |
| `initialize` | `sampleRate` (int), `bufferSize` (int) | `bool` | Lazily constructs `FaustAudioEngine` if missing; safe to call multiple times (no-op after first). |
| `start` | — | `bool` | Starts the Faust render loop; reuses the existing engine instance. |
| `stop` | — | `void` | Stops audio rendering but keeps the engine alive for subsequent starts. |
| `teardown` | — | `void` | Stops and releases the native engine; `initialize` must be called again before further use. |
| `isRunning` | — | `bool` | Mirrors `FaustAudioEngine.isRunning`. |
| `setParameter` | `address` (string), `value` (double) | `void` | Proxies to `setParameter:value:`. Invalid addresses are ignored and logged. |
| `getParameter` | `address` (string) | `double` | Reads the parameter by address; returns `0.0` if the engine is not ready. |
| `listParameters` | — | `List<String>` | Enumerates addresses from `parameterAddresses`. Useful for building dynamic UIs. |

## Meter updates

The event channel publishes periodic snapshots with the shape:

```json
{
  "timestampMs": 1712345678901,
  "meters": {
    "/outputLevel": -6.4,
    "/gain": 0.73
  }
}
```

The Swift stream handler should:

1. Install a CADisplayLink or `Timer` on the main run loop (e.g., 30–60 Hz) once a Dart listener subscribes.
2. Pull current values via `FaustAudioEngine.getParameter` for any addresses marked as meters (hard-coded list or future JSON metadata tag parsing).
3. Post the dictionary over the `EventSink` until the listener cancels, then tear down the timer.

## Dart scaffolding

* Create a singleton `FaustNativeClient` that holds the `MethodChannel`/`EventChannel` objects and exposes typed wrappers around the methods above.
* Manage lifecycle alongside `WidgetsBindingObserver` hooks (start in `didChangeAppLifecycleState(resumed)`, stop in `inactive/paused`).
* Surface a `Stream<FaustMeters>` for UI consumption; the stream is optional so the engine can still run headless.

## Rationale

* **Method channels first:** Control traffic (start/stop/parameter changes) is low-frequency and tolerant of channel overhead, while keeping the audio thread native avoids FFI threading complexities.
* **Upgrade path:** If future profiling shows channel overhead during dense automation, we can move parameter writes to a small `dart:ffi` layer that calls directly into a C shim exposing `setParamValue` while leaving lifecycle on the existing method channel.
