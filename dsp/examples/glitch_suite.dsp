import("stdfaust.lib");

// Global tempo-based trigger shared by all synths
clockTempo = hslider("h:Global/Tempo (BPM)", 110, 40, 200, 1);
clockPh = os.phasor(1, clockTempo / 60);
clockTrig = clockPh < clockPh';

// Utility helpers
percEnv(decay) = en.ar(0.001, decay, clockTrig);
bitcrush(x, bits) = floor(x * pow(2, bits)) / pow(2, bits);
randHold(speed) = ba.sAndH(os.phasor(1, speed) < os.phasor(1, speed)', no.noise);
probTrig(rate, thresh) = ba.sAndH(os.phasor(1, rate) < os.phasor(1, rate)', no.noise) > thresh;
panGainL(p) = 0.5 * (1 - p);
panGainR(p) = 0.5 * (1 + p);

// GlitchPerc1 - sine with rapid random motion
gp1Freq = hslider("h:GlitchPerc1/Freq", 200, 80, 800, 1);
gp1Decay = hslider("h:GlitchPerc1/Decay", 0.1, 0.02, 0.6, 0.001);
gp1Amp = hslider("h:GlitchPerc1/Amp", 0.3, 0, 1, 0.01);
gp1Pan = hslider("h:GlitchPerc1/Pan", 0, -1, 1, 0.01);
gp1Env = percEnv(gp1Decay);
gp1FreqMod = 0.5 + randHold(20) * 0.5;
gp1AmpMod = 0.5 + randHold(100) * 0.5;
gp1Sig = os.osc(gp1Freq * gp1FreqMod) * gp1Env * gp1AmpMod * gp1Amp;
gp1L = gp1Sig * panGainL(gp1Pan);
gp1R = gp1Sig * panGainR(gp1Pan);

// BitNoisePerc2 - crushed noise burst
bn2Bits = hslider("h:BitNoisePerc2/Bits", 4, 2, 10, 1);
bn2Decay = hslider("h:BitNoisePerc2/Decay", 0.07, 0.02, 0.4, 0.001);
bn2Amp = hslider("h:BitNoisePerc2/Amp", 0.4, 0, 1, 0.01);
bn2Pan = hslider("h:BitNoisePerc2/Pan", 0, -1, 1, 0.01);
bn2Env = percEnv(bn2Decay);
bn2Raw = no.noise * bn2Env;
bn2Crushed = bitcrush(bn2Raw * 0.15, bn2Bits);
bn2Sig = bn2Crushed * bn2Amp;
bn2L = bn2Sig * panGainL(bn2Pan);
bn2R = bn2Sig * panGainR(bn2Pan);

// MetallicZap3 - resonant ping with airy edges
mz3Freq = hslider("h:MetallicZap3/Freq", 1000, 300, 4000, 1);
mz3Decay = hslider("h:MetallicZap3/Decay", 0.2, 0.03, 1.0, 0.001);
mz3Amp = hslider("h:MetallicZap3/Amp", 0.3, 0, 1, 0.01);
mz3Pan = hslider("h:MetallicZap3/Pan", 0, -1, 1, 0.01);
mz3Env = percEnv(mz3Decay);
mz3Ping = fi.resonbp(clockTrig * mz3Env * 6, mz3Freq, 0.02);
mz3Noise = fi.bandpass(2, mz3Freq * (0.8 + randHold(10) * 0.4), 0.05, no.noise * 0.1) * 0.2;
mz3Sig = (mz3Ping + mz3Noise) * mz3Amp;
mz3L = mz3Sig * panGainL(mz3Pan);
mz3R = mz3Sig * panGainR(mz3Pan);

// StutterGrain4 - noisy combed grains with moving filters
sg4Freq = hslider("h:StutterGrain4/Freq", 800, 200, 2400, 1);
sg4Decay = hslider("h:StutterGrain4/Decay", 0.35, 0.05, 1.0, 0.001);
sg4Amp = hslider("h:StutterGrain4/Amp", 0.3, 0, 1, 0.01);
sg4Pan = hslider("h:StutterGrain4/Pan", 0, -1, 1, 0.01);
sg4Env = percEnv(sg4Decay);
sg4Color = fi.lowpass(2, 3000, no.noise) * sg4Env;
sg4Flutter = 0.7 + randHold(20) * 0.6;
sg4Comb = de.delay(0.2, 0.04 + randHold(5) * 0.12, sg4Color * sg4Flutter) + sg4Color * 0.5;
sg4Filt = fi.bandpass(2, sg4Freq * (0.8 + randHold(2) * 0.4), 0.12, sg4Comb);
sg4Burst = no.noise * (ba.sAndH(clockTrig, no.noise) > 0.6) * 0.15;
sg4Sig = (sg4Filt + sg4Burst) * sg4Amp;
sg4L = sg4Sig * panGainL(sg4Pan);
sg4R = sg4Sig * panGainR(sg4Pan);

// ZapCrush5 - pulse ping through decimator with dust
zc5Freq = hslider("h:ZapCrush5/Freq", 800, 150, 3000, 1);
zc5Decay = hslider("h:ZapCrush5/Decay", 0.2, 0.03, 0.7, 0.001);
zc5Crush = hslider("h:ZapCrush5/Bits", 6, 3, 10, 1);
zc5Amp = hslider("h:ZapCrush5/Amp", 0.3, 0, 1, 0.01);
zc5Pan = hslider("h:ZapCrush5/Pan", 0, -1, 1, 0.01);
zc5Env = percEnv(zc5Decay) * 0.5;
zc5Pulse = os.square(zc5Freq * (0.8 + randHold(30) * 0.5)) * zc5Env;
zc5Noise = fi.bandpass(2, zc5Freq * (0.8 + randHold(10) * 0.4), 0.05, no.noise * 0.1) * 0.2;
zc5Dust = (ba.sAndH(clockTrig, no.noise) > 0.7) * 0.1;
zc5Crushed = bitcrush(zc5Pulse + zc5Noise + zc5Dust, zc5Crush);
zc5Sig = zc5Crushed * zc5Amp;
zc5L = zc5Sig * panGainL(zc5Pan);
zc5R = zc5Sig * panGainR(zc5Pan);

// MetalBurst6 - bright hats with random rolls
mb6Decay = hslider("h:MetalBurst6/Decay", 0.045, 0.01, 0.15, 0.001);
mb6Amp = hslider("h:MetalBurst6/Amp", 0.18, 0, 1, 0.01);
mb6Pan = hslider("h:MetalBurst6/Pan", 0, -1, 1, 0.01);
mb6Env = en.ar(0.0005, mb6Decay, clockTrig);
mb6Noise = fi.highpass(2, 7000, no.noise) * mb6Env * 1.5;
mb6Flam = (ba.sAndH(clockTrig, no.noise) > 0.4) * no.noise * mb6Env * 0.5;
mb6Sig = (mb6Noise + mb6Flam) * mb6Amp;
mb6L = mb6Sig * panGainL(mb6Pan);
mb6R = mb6Sig * panGainR(mb6Pan);

// HatRoll22 - short rolling hats gated by density
hr22Decay = hslider("h:HatRoll22/Decay", 0.03, 0.01, 0.12, 0.001);
hr22Density = hslider("h:HatRoll22/Density", 16, 2, 64, 1);
hr22Amp = hslider("h:HatRoll22/Amp", 0.14, 0, 1, 0.01);
hr22Pan = hslider("h:HatRoll22/Pan", 0, -1, 1, 0.01);
hr22Env = en.ar(0.001, hr22Decay * 0.5, clockTrig);
hr22Trig = probTrig(hr22Density, 0.4) * hr22Env;
hr22HitEnv = en.adsr(0.0005, hr22Decay, 0, 0, hr22Trig);
hr22Noise = fi.highpass(2, 9000, no.noise) * hr22HitEnv * 1.5;
hr22Sig = hr22Noise * hr22Amp;
hr22L = hr22Sig * panGainL(hr22Pan);
hr22R = hr22Sig * panGainR(hr22Pan);

// BitMetal7 - noisy ring with high-pass motion
bm7Freq = hslider("h:BitMetal7/Freq", 900, 200, 3000, 1);
bm7Decay = hslider("h:BitMetal7/Decay", 0.13, 0.03, 0.5, 0.001);
bm7Bits = hslider("h:BitMetal7/Bits", 3, 2, 8, 1);
bm7Amp = hslider("h:BitMetal7/Amp", 0.3, 0, 1, 0.01);
bm7Pan = hslider("h:BitMetal7/Pan", 0, -1, 1, 0.01);
bm7Env = percEnv(bm7Decay);
bm7Noise = bitcrush(no.noise * bm7Env, bm7Bits);
bm7HP = fi.highpass(2, bm7Freq * (0.7 + randHold(8) * 0.6), bm7Noise);
bm7Ring = fi.resonbp(clockTrig * 0.3, bm7Freq, 0.01) * bm7Env * 0.3;
bm7Sig = (bm7HP + bm7Ring) * bm7Amp;
bm7L = bm7Sig * panGainL(bm7Pan);
bm7R = bm7Sig * panGainR(bm7Pan);

// SineKick21 - deep kick with pitch bend and click
sk21Freq = hslider("h:SineKick21/Freq", 50, 30, 120, 1);
sk21Decay = hslider("h:SineKick21/Decay", 0.18, 0.05, 0.6, 0.001);
sk21Amp = hslider("h:SineKick21/Amp", 0.5, 0, 1, 0.01);
sk21Pan = hslider("h:SineKick21/Pan", 0, -1, 1, 0.01);
sk21Env = en.ar(0.001, sk21Decay, clockTrig);
sk21PitchEnv = (2.2 : si.smooth(0.05)) * (1 - sk21Env) + 0.5;
sk21Body = os.osc(sk21Freq * sk21PitchEnv) * sk21Env * sk21Amp * 2;
sk21Sub = os.osc(sk21Freq * 0.5) * sk21Env * sk21Amp * 0.5;
sk21Click = fi.highpass(2, 7000, no.noise) * sk21Env * 0.2;
sk21Sig = (sk21Body + sk21Sub + sk21Click) * 0.6;
sk21L = sk21Sig * panGainL(sk21Pan);
sk21R = sk21Sig * panGainR(sk21Pan);

// Mix and output
mixL = gp1L + bn2L + mz3L + sg4L + zc5L + mb6L + hr22L + bm7L + sk21L;
mixR = gp1R + bn2R + mz3R + sg4R + zc5R + mb6R + hr22R + bm7R + sk21R;
process = mixL, mixR;
