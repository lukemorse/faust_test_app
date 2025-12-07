# iOS audio engine entry points

This note summarizes where the generated Faust iOS code instantiates and drives the audio engine, and highlights insertion points for adding an extra DSP node or Audio Unit.

## Engine surfaces

* The generated `audio` abstract base (`audio.h` portion of `DspFaust.cpp`) defines the lifecycle used by all platform drivers: `init(...)`, `start()`, `stop()`, and the control callback hooks invoked from the render loop.【F:ios/Runner/DSP/DspFaust.cpp†L98491-L98570】
* `TiPhoneCoreAudioRenderer` wraps Core Audio’s RemoteIO unit. Its static `Render` trampoline forwards to the instance `Render` method, which gathers interleaved buffers and calls the current Faust DSP’s `compute` before running queued control callbacks.【F:ios/Runner/DSP/DspFaust.cpp†L108401-L108509】
* `iosaudio` is the iOS-specific driver that owns `TiPhoneCoreAudioRenderer`. During `init` it forwards sample rate/buffer size to the generated `dsp` instance and opens the Core Audio renderer. `start()`/`stop()` simply delegate to the renderer, and the driver reports the hardware channel counts and buffer configuration used by Faust.【F:ios/Runner/DSP/DspFaust.cpp†L109040-L109085】

## Where the engine is constructed

* The `DspFaust` wrapper is the public API surfaced to Swift/Obj‑C. The constructor that accepts a sample rate and buffer size calls `createDriver`, which selects `iosaudio` when `IOS_DRIVER` is defined, then calls `init` with a freshly created `mydsp` instance and that driver.【F:ios/Runner/DSP/DspFaust.cpp†L121425-L121455】
* `createDriver` centralizes driver selection. On iOS it builds `iosaudio` with the provided buffer size and sample rate, so any new node that needs to see the hardware format should be threaded through here.【F:ios/Runner/DSP/DspFaust.cpp†L121459-L121497】
* The `init` routine wires up optional OSC/MIDI/Soundfile interfaces and constructs `FaustPolyEngine`, which owns the active `dsp` and starts/stops it via the selected driver. `start()` and `stop()` on `DspFaust` simply forward to this poly engine after bootstrapping ancillary interfaces.【F:ios/Runner/DSP/DspFaust.cpp†L121500-L121624】

## Insertion points for a new DSP node or Audio Unit

* **Within the render callback:** `TiPhoneCoreAudioRenderer::Render` currently deinterleaves the input buffers, calls `fDSP->compute`, and then triggers `audio::runControlCallbacks`. Inserting another DSP node directly in this method (either pre- or post-`compute`) would place it in the realtime signal path that already holds the Faust graph.【F:ios/Runner/DSP/DspFaust.cpp†L108488-L108507】
* **Before driver startup:** If a new audio unit needs setup that depends on the driver format, extend `iosaudio::init` to open/configure it alongside `fAudioDevice.Open(...)` so it shares the same buffer size and sample rate as the Faust DSP.【F:ios/Runner/DSP/DspFaust.cpp†L109055-L109085】
* **At wrapper construction:** For higher-level integration, augment `DspFaust::createDriver` or `DspFaust::init` to allocate and register your node with `FaustPolyEngine` (for example, by wrapping `mydsp` in a composite or chaining another `dsp` implementation) before `start()` is called.【F:ios/Runner/DSP/DspFaust.cpp†L121425-L121624】
