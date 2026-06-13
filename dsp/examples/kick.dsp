import("stdfaust.lib");

// Wobble Zap - tonal with wobbling pitch modulation
// GUI Parameters
tempo = hslider("h:WobbleZap/Tempo (BPM)", 75, 10, 240, 1);
pitch = hslider("h:WobbleZap/Pitch", 150, 50, 800, 1);
decay = hslider("h:WobbleZap/Decay", 0.6, 0.1, 4.0, 0.01);
wobble = hslider("h:WobbleZap/Wobble", 0.7, 0, 1, 0.01);
zappiness = hslider("h:WobbleZap/Zappiness", 0.4, 0, 1, 0.01);
chaos = hslider("h:WobbleZap/Chaos", 0.3, 0, 1, 0.01);

// Clock
trigFreq = tempo / 60;
phasor = os.phasor(1, trigFreq);
trigger = phasor < phasor';

// Random
rnd1 = ba.sAndH(trigger, no.noise);
rnd2 = ba.sAndH(trigger, no.noise);

// Envelopes
ampEnv = en.ar(0.002, decay, trigger);
wobbleEnv = en.ar(0.05, decay * 0.7, trigger);

// Base pitch with random offset
basePitch = pitch * (1 + rnd1 * chaos * 0.5);

// Wobbling LFO
wobbleLFO = os.osc(8 + rnd2 * 12 * chaos) * wobble;

// Multiple detuned oscillators with wobble
osc1 = os.osc(basePitch * (1 + wobbleLFO * wobbleEnv)) * 0.4;
osc2 = os.osc(basePitch * 1.99 * (1 + wobbleLFO * 0.5 * wobbleEnv)) * 0.3;
osc3 = os.sawtooth(basePitch * 0.5 * (1 + wobbleLFO * 1.2 * wobbleEnv)) * 0.2;

// Zap component (noise burst with pitch)
zapNoise = no.noise * en.ar(0.001, 0.03, trigger);
zapFiltered = fi.bandpass(2, basePitch * 2, basePitch * 8, zapNoise) * zappiness;

// Combine
raw = osc1 + osc2 + osc3 + zapFiltered;

// Output
sound = raw * ampEnv * 0.4;

process = sound <: _, _;
