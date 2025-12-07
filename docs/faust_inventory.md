# Faust assets inventory (iOS)

This repository already contains the generated Faust outputs stored under `ios/Faust/` for the iOS target. The contents are as follows:

- `ios/Faust/ios-faust.h`: full Faust-generated DSP header ("hello" example, generated with Faust 2.81.10 using ios-coreaudio.cpp architecture). Includes DSP class `mydsp` plus Faust architecture scaffolding.
- `ios/Faust/faust_c_wrapper.cpp`: C ABI wrapper that instantiates `mydsp`, exposes parameter getters/setters, reset, process, and parameter metadata helpers.
- `ios/Faust/faust_c_wrapper.h`: public C header for the wrapper; defines opaque `FaustDspHandle` and exported DSP/parameter functions.
- `ios/Faust/osclib/`: bundled Faust OSC library sources and README. Contains `oscpack` sources and supporting docs for OSC control. The top-level `.gitignore` and `README.md` are present; subfolders include `faust/`, `oscpack/`, and `android/` (from upstream Faust OSC distribution).
- `ios/Faust/README.md`: notes for integrating the Faust wrapper directly into the Runner target (Xcode compiles from source) and keeping `ios-faust.h`/`faust_c_wrapper.h` in sync with generated outputs.

Additional static asset:

- `ios_example/ios-libsndfile.a`: linked library noted in the Faust README for DSPs requiring libsndfile.

These files will be used when wiring the Faust DSP into the existing iOS audio engine in the next steps.
