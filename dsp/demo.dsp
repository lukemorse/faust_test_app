declare name "FaustDemo";
declare author "Faust Flutter Template";
declare license "MIT";

import("stdfaust.lib");

// ---------------------------------------------------------------------------
// Canonical template synth.
//
// A single sine voice with gain and an ADSR gate, plus a real output level
// meter. The meter is an `hbargraph`, so it is published as a *read-only*
// parameter address ("/FaustDemo/level") that the meter EventChannel reports
// as the true smoothed output level -- not just an echo of a control value.
//
// Swap this file for any of the synths in dsp/examples/ (or your own) and run
// `scripts/generate.sh` to regenerate the native DSP for iOS and/or Android.
// ---------------------------------------------------------------------------

freq = hslider("freq [unit:Hz]", 440, 50, 2000, 0.01);
gain = hslider("gain", 0.2, 0, 1, 0.001);
gate = button("gate");

env = en.adsr(0.01, 0.1, 0.8, 0.2, gate);
sig = os.osc(freq) * gain * env;

// Smoothed output level, published as a bargraph the host can poll for metering.
level = sig : abs : an.amp_follower(0.2);
metered = attach(sig, level : hbargraph("level", 0, 1));

process = metered <: _, _;
