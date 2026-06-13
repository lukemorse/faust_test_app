import("stdfaust.lib");

// Bubble Pop - half tonal, half noisy pops
// GUI Parameters
tempo = hslider("h:BubblePop/Tempo (BPM)", 120, 10, 240, 1);
pitch = hslider("h:BubblePop/Pitch", 600, 200, 2000, 1);
decay = hslider("h:BubblePop/Decay", 0.3, 0.05, 2.0, 0.01);
poppiness = hslider("h:BubblePop/Poppiness", 0.6, 0, 1, 0.01);
fizz = hslider("h:BubblePop/Fizz", 0.5, 0, 1, 0.01);
wetness = hslider("h:BubblePop/Wetness", 0.4, 0, 1, 0.01);

// Clock
trigFreq = tempo / 60;
phasor = os.phasor(1, trigFreq);
trigger = phasor < phasor';

// Random
rnd1 = ba.sAndH(trigger, no.noise);
rnd2 = ba.sAndH(trigger, no.noise);

// Envelopes
ampEnv = en.ar(0.001, decay, trigger);
popEnv = en.ar(0.001, decay * 0.2, trigger);
fizzEnv = en.ar(0.01, decay * 0.6, trigger);

// Bubble tone (descending pitch)
basePitch = pitch * (1 + rnd1 * 0.3);
bubblePitch = basePitch * (1 + popEnv * 3 * poppiness);

// Tonal component with FM-like quality
bubble1 = os.osc(bubblePitch) * 0.5;
bubble2 = os.osc(bubblePitch * 1.618) * 0.3;
bubble3 = os.triangle(bubblePitch * 0.5) * 0.2;

// Pop (short noise burst)
popNoise = no.noise * en.ar(0.0001, 0.01, trigger);
popFiltered = fi.bandpass(2, bubblePitch * 0.5, bubblePitch * 3, popNoise) * poppiness;

// Fizz (filtered noise for texture)
fizzNoise = no.noise * fizzEnv * fizz;
fizzFiltered = fi.bandpass(2, 2000, 6000, fizzNoise);

// Wet (lowpass for underwater effect)
tonal = bubble1 + bubble2 + bubble3;
wet = fi.lowpass(3, 1200 + wetness * 3000, tonal + popFiltered);
dry = tonal + popFiltered;
mixed = wet * wetness + dry * (1 - wetness) + fizzFiltered;

// Output
sound = mixed * ampEnv * 0.4;

process = sound <: _, _;
