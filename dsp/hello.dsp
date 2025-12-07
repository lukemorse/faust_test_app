import("stdfaust.lib");

freq = hslider("Frequency", 440, 200, 1000, 1);
gain = hslider("Volume", 0.1, 0, 1, 0.01);

import("stdfaust.lib");

// Crystal Bells - very tonal, shimmering harmonics
// GUI Parameters
tempo = hslider("h:CrystalBells/Tempo (BPM)", 45, 10, 240, 1);
pitch = hslider("h:CrystalBells/Pitch", 800, 200, 3000, 1);
decay = hslider("h:CrystalBells/Decay", 2.0, 0.2, 8.0, 0.1);
shimmer = hslider("h:CrystalBells/Shimmer", 0.7, 0, 1, 0.01);
sparkle = hslider("h:CrystalBells/Sparkle", 0.15, 0, 1, 0.01);
randomize = hslider("h:CrystalBells/Randomization", 0.3, 0, 1, 0.01);

// Clock
trigFreq = tempo / 60;
phasor = os.phasor(1, trigFreq);
trigger = phasor < phasor';

// Random generators
rnd1 = ba.sAndH(trigger, no.noise);
rnd2 = ba.sAndH(trigger, no.noise);
rnd3 = ba.sAndH(trigger, no.noise);

// Envelopes
ampEnv = en.ar(0.001, decay, trigger);
shimmerEnv = en.ar(0.01, decay * 1.5, trigger);

// Bell-like harmonic series with slight detuning
basePitch = pitch * (1 + rnd1 * randomize * 0.2);
harm1 = os.osc(basePitch) * 1.0;
harm2 = os.osc(basePitch * 2.01) * 0.6;
harm3 = os.osc(basePitch * 3.02) * 0.4;
harm4 = os.osc(basePitch * 4.5) * 0.25;
harm5 = os.osc(basePitch * 5.99) * 0.15;

// Add inharmonic components for metallic character
inharm1 = os.osc(basePitch * 2.76 + rnd2 * shimmer * 50) * 0.3;
inharm2 = os.osc(basePitch * 6.28 + rnd3 * shimmer * 80) * 0.2;

// Mix harmonics
bells = (harm1 + harm2 + harm3 + harm4 + harm5) * 0.3;
metal = (inharm1 + inharm2) * shimmer * shimmerEnv;

// Sparkle (high frequency noise bursts)
sparkleNoise = no.noise * en.ar(0.0001, 0.02, trigger) * sparkle;
sparkleFiltered = fi.highpass(2, 4000, sparkleNoise);

// Combine
raw = bells + metal + sparkleFiltered;

// Output
sound = raw * ampEnv * 0.3;

process = sound <: _, _;