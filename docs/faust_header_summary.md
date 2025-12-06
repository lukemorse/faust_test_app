# Faust DSP header quick reference (ios/Faust/ios-faust.h)

## DSP shape
- `mydsp` implements the Faust `dsp` interface with **0 audio inputs** and **2 audio outputs** (stereo). It seeds a lookup table in `classInit`, tracks the sample rate via `instanceConstants`, and exposes standard lifecycle calls (`init`, `instanceInit`, `instanceResetUserInterface`, `instanceClear`, `compute`, `clone`).

## UI parameters exposed by `buildUserInterface`
The generated UI defines one horizontal box, `CrystalBells`, containing these sliders:
- **Pitch** (`fHslider0`): default 800 Hz, range 200–3000 Hz, step 1.0.
- **Randomization** (`fHslider1`): default 0.3, range 0.0–1.0, step 0.01.
- **Tempo (BPM)** (`fHslider2`): default 45 BPM, range 10–240 BPM, step 1.0.
- **Shimmer** (`fHslider3`): default 0.7, range 0.0–1.0, step 0.01.
- **Decay** (`fHslider4`): default 2.0, range 0.2–8.0, step 0.1.
- **Sparkle** (`fHslider5`): default 0.15, range 0.0–1.0, step 0.01.

## Audio processing notes
- `compute` writes identical synthesized samples to both outputs, so the DSP currently renders a mono signal to stereo buffers.
- The algorithm uses a precomputed sine wavetable (`ftbl0mydspSIG0`), randomization via a linear congruential generator, and several tempo/pitch-dependent phase accumulators to generate percussive “CrystalBells” textures. The processing state is cleared in `instanceClear` and reinitialized in `instanceResetUserInterface`.
