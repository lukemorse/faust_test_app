# Faust C wrapper for iOS (FFI entry points)

This lightweight C ABI sits in `ios_example/faust_c_wrapper.cpp`/`.h` and wraps the generated `mydsp` class from `ios-faust.h` so Flutter can bind to stable C symbols.

## Exposed functions
- `FaustDspHandle* faust_create(int sample_rate)`: construct the DSP, wire up the MapUI, and initialize at the requested sample rate.
- `void faust_destroy(FaustDspHandle* handle)`: free the handle.
- `void faust_reset(FaustDspHandle* handle, int sample_rate)`: reset UI defaults and reinitialize at a new rate.
- `void faust_process(FaustDspHandle* handle, float* output_left, float* output_right, int frame_count)`: render stereo audio (no inputs needed because the DSP is source-only).
- `int faust_get_sample_rate(FaustDspHandle* handle)`: read back the active sample rate.
- `void faust_set_parameter(FaustDspHandle* handle, const char* path, float value)` / `float faust_get_parameter(...)`: set/get by label/path/shortname (e.g., "Pitch", "Randomization").
- `int faust_get_parameter_count(FaustDspHandle* handle)`: enumerate parameters.
- `int faust_get_parameter_info(...)`: pull path, label, shortname, and range/init/step metadata for a parameter index.

## Notes for Flutter FFI bindings
- Use `DynamicLibrary.process()` on iOS to link these symbols from the app binary when the static library is added to the Xcode target.
- Parameter names match the labels in `ios-faust.h` (`Pitch`, `Randomization`, `Tempo (BPM)`, `Shimmer`, `Decay`, `Sparkle`).
- The DSP has **0 inputs** and **2 outputs**. Provide two float buffers of `frame_count` samples to `faust_process`.
