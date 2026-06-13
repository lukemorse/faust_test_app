import("stdfaust.lib");

// Shimmer Wash - extended atmospheric noise textures
// GUI Parameters
tempo = hslider("h:ShimmerWash/Tempo (BPM)", 80, 10, 480, 1);
frequency = hslider("h:ShimmerWash/Frequency", 4000, 500, 12000, 1);
decay = hslider("h:ShimmerWash/Decay", 1.2, 0.1, 6.0, 0.1);
texture = hslider("h:ShimmerWash/Texture", 0.7, 0, 1, 0.01);
wash = hslider("h:ShimmerWash/Wash", 0.6, 0, 1, 0.01);
drift = hslider("h:ShimmerWash/Drift", 0.5, 0, 1, 0.01);

// Clock
trigFreq = tempo / 60;
phasor = os.phasor(1, trigFreq);
trigger = phasor < phasor';

// Random
rnd1 = ba.sAndH(trigger, no.noise);
rnd2 = ba.sAndH(trigger, no.noise);
rnd3 = ba.sAndH(trigger, no.noise);

// Envelopes - much longer
ampEnv = en.ar(0.01, decay, trigger);
washEnv = en.ar(0.05, decay * 1.5, trigger);
driftEnv = en.ar(0.1, decay * 2.0, trigger);

// Multiple noise sources for rich texture
noise1 = no.noise;
noise2 = no.noise;
noise3 = no.noise;
noise4 = no.noise;

// Varying frequency bands with drift
baseFreq = frequency * (1 + rnd1 * drift * 0.3);
freq1 = baseFreq * (1 + os.osc(0.3 + rnd2 * 0.5) * drift * 0.2);
freq2 = baseFreq * 1.618 * (1 + os.osc(0.47 + rnd3 * 0.4) * drift * 0.15);
freq3 = baseFreq * 0.618;

// Multiple filtered layers
layer1 = fi.bandpass(2, freq1 * 0.8, freq1 * 1.3, noise1) * 0.3;
layer2 = fi.bandpass(2, freq2 * 0.7, freq2 * 1.5, noise2) * 0.25;
layer3 = fi.highpass(2, freq3, noise3) * 0.25;
layer4 = fi.bandpass(2, baseFreq * 0.5, baseFreq * 2.5, noise4) * 0.2;

// Mix layers with texture
noiseMix = (layer1 + layer2 + layer3 + layer4) * texture;

// Add tonal shimmer components
shimmer1 = os.osc(freq1 * (1 + washEnv * 0.1)) * washEnv * wash * 0.2;
shimmer2 = os.osc(freq2 * (1 + washEnv * 0.08)) * washEnv * wash * 0.15;
shimmer3 = os.osc(freq1 * 2.5) * driftEnv * wash * 0.1;

// Wash effect (slow modulation)
washMod = os.osc(0.2 + rnd1 * 0.3) * wash;
washed = fi.bandpass(2, baseFreq * (1 + washMod * 0.3), baseFreq * (2 + washMod * 0.5), noiseMix + shimmer1 + shimmer2 + shimmer3);

// Combine dry and washed
mixed = noiseMix * (1 - wash * 0.5) + washed * wash + shimmer1 + shimmer2 + shimmer3;

// Gentle compression
compressed = ef.cubicnl(0.3, 0, mixed);

// Output
sound = compressed * ampEnv * 0.35;

process = sound <: _, _;
