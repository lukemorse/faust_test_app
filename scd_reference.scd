// --- SynthDefs (unchanged) ---
SynthDef(\GlitchPerc1, { |out=0, freq=200, amp=0.3, decay=0.1, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = SinOsc.ar(freq * LFNoise1.kr(20).range(0.5, 2)) * env;
    sig = sig * LFNoise2.kr(100).range(0.5, 1.5);
    Out.ar(out, Pan2.ar(sig * amp, pan));   
}).add;

SynthDef(\BitNoisePerc2, { |out=0, amp=0.4, bits=4, decay=0.07, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = WhiteNoise.ar * env;
    amp = amp * 0.15;
    decay = decay * 0.1; 
    sig = Decimator.ar(sig, 4000, bits);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\MetallicZap3, { |out=0, freq=1000, amp=0.3, decay=0.2, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = Ringz.ar(Impulse.ar(200), freq, 0.02) * env;
    sig = sig + (BPF.ar(WhiteNoise.ar(0.1), freq * LFNoise1.kr(10).range(0.8, 1.2), 0.05) * 0.2);
    sig = sig + (Crackle.ar(0.8) * 0.1);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\StutterGrain4, { |out=0, amp=0.3, decay=0.35, rate=1, pan=0, freq=800|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var baseFreq = freq * LFNoise1.kr(1).range(0.8, 1.2); // add slow random freq mod
    var sig = PinkNoise.ar * env;
    amp = amp * 0.75; // reduce overall level
    // Add a stuttery/grainy effect using a comb filter
    sig = sig * LFNoise1.kr(20).range(0.7, 1.3);
    sig = CombL.ar(sig, 0.2, LFNoise1.kr(5).range(0.05, 0.18), 0.4);
    // Add a resonant filter with freq mod
    sig = BPF.ar(sig, baseFreq, LFNoise1.kr(2).range(0.08, 0.18)) * LFNoise1.kr(3).range(0.7, 1.2) + sig * 0.5;
    // Add some resonance with freq mod
    sig = sig + Ringz.ar(Impulse.ar(100 * LFNoise1.kr(0.5).range(0.7, 1.3)), baseFreq, 0.02) * 0.1;
    // Occasionally add a glitchy burst
    sig = sig + (Dust2.ar(2) * WhiteNoise.ar(0.2) * LFNoise1.kr(1).range(0.5, 1.5));
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\ZapCrush5, { |out=0, freq=800, amp=0.3, decay=0.2, crush=6, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = Pulse.ar(freq, LFNoise1.kr(30).range(0.05, 0.3)) * env;
    sig = sig + (BPF.ar(WhiteNoise.ar(0.1), freq * LFNoise1.kr(10).range(0.8, 1.2), 0.05) * 0.2);
    amp = amp * 0.3; // reduce overall level
    decay = decay * 0.5; // shorten decay
    sig = Decimator.ar(sig, 4000, crush);
    sig = sig + (Dust2.ar(20) * 0.1);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

// --- More metallic/noisy glitch percussion ---
SynthDef(\MetalBurst6, { |out=0, freq=8000, amp=0.18, decay=0.045, pan=0|
    var env = EnvGen.kr(Env.perc(0.0005, decay, amp, -8), doneAction:2);
    var sig = WhiteNoise.ar * env;
    var flam = Dust2.ar(100) * env; // random flams
    sig = HPF.ar(sig, 7000); // emphasize high freqs
    sig = sig * 1.5; // boost level
    // this is kind of like a high hat, so make it sometimes do a flam/roll
    sig = sig + (flam * WhiteNoise.ar(0.5) * LFNoise1.kr(5).range(0.5, 1.5));
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

// Closed hi-hat roll with variable density
SynthDef(\HatRoll22, { |out=0, freq=8000, amp=0.14, decay=0.03, pan=0, density=16, gate=1|
    var dur = decay / 2; // total roll duration (short, < 1s)
    var env = EnvGen.kr(Env.perc(0.001, dur), gate, doneAction:2);
    var trig = Dust2.ar(density) * env; // triggers only during env
    var hitEnv = Decay2.ar(trig, 0.0005, decay);
    var sig = WhiteNoise.ar * hitEnv;
    sig = HPF.ar(sig, 9000);
    sig = sig * 1.5;
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\BitMetal7, { |out=0, freq=900, bits=3, amp=0.3, decay=0.13, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = WhiteNoise.ar * env;
    sig = Decimator.ar(sig, 4000, bits);
    sig = HPF.ar(sig, freq * LFNoise1.kr(8).range(0.7, 1.3));
    sig = sig + (Ringz.ar(Impulse.ar(200), freq, 0.01) * 0.3);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\Shatter8, { |out=0, freq=1500, amp=0.3, decay=0.09, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var crackle = Crackle.ar(1.3) * 0.9;
    var dust = Dust2.ar(800) * 0.3;
    var noise = WhiteNoise.ar(0.2);
    var sig = crackle + dust + noise;
    sig = BPF.ar(sig, freq * LFNoise1.kr(12).range(0.7, 1.4), 0.2);
    sig = sig * env * 5.5; // boost overall level
    sig = Limiter.ar(sig, 0.99);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\ResoClang9, { |out=0, freq=700, amp=0.3, decay=0.22, pan=0, excRate=1|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    // Use Dust.ar for variable-rate excitation bursts
    var exc = WhiteNoise.ar * Dust.ar(excRate) * env;
    var clang = Resonz.ar(exc, freq * LFNoise1.kr(6).range(0.6,1.1), 0.15);
    clang = clang + (Ringz.ar(Impulse.ar(30), freq * 1.2, 0.08) * 0.5);
    clang = clang + (Ringz.ar(Impulse.ar(20), freq * 0.7, 0.12) * 0.3);
    clang = clang + (BPF.ar(PinkNoise.ar, freq * 2, 0.08) * 0.2);
    Out.ar(out, Pan2.ar(clang * amp, pan));
}).add;

SynthDef(\HiMetal10, { |out=0, freq=3500, amp=0.25, decay=0.07, pan=0|
    var env = EnvGen.kr(Env.perc(0.0005, decay, 1, -8), doneAction:2);
    var click = HPF.ar(Impulse.ar(0) + WhiteNoise.ar(0.2), 3000);
    var bell = Ringz.ar(click, freq * [1, 1.5, 2.2], [0.01, 0.015, 0.02]).sum * 0.7;
    var metallic = BPF.ar(WhiteNoise.ar(0.1), freq * 2, 0.08) * 0.2;
    var sig = (bell + metallic) * env;
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

// --- New glitchy/metallic/noisy percussion synths ---
SynthDef(\GlassPing11, { |out=0, freq=1200, amp=0.3, decay=0.5, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = SinOsc.ar(freq * [1, 1.01], 0, 0.4).sum * env;
    sig = sig + (BPF.ar(WhiteNoise.ar, freq * 2, 0.03) * 0.1);
    sig = sig + (SinOsc.ar(freq * 0.5, 0, 0.2) * env);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\CircuitBuzz12, { |out=0, freq=700, amp=0.3, decay=0.11, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = LFPulse.ar(freq * LFNoise1.kr(15).range(0.8, 1.2), 0, 0.3) * env;
    sig = sig + (Crackle.ar(1.2) * 0.15);
    sig = sig + (Decimator.ar(sig, 3000, 5) * 0.5);
    Out.ar(out, Pan2.ar(sig * amp * 0.5, pan));
}).add;

SynthDef(\RustyBell13, { |out=0, freq=700, amp=0.3, decay=0.35, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = SinOsc.ar(freq * [1, 1.5], 0, 0.3).sum * env;
    sig = sig + (BPF.ar(PinkNoise.ar, freq, 0.1) * 0.2);
    sig = sig + (Ringz.ar(Impulse.ar(2), freq * 0.7, 0.2) * 0.1);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\StaticSnap14, { |out=0, amp=0.3, decay=0.09, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = LFNoise2.ar(8000) * env * 0.7;
    sig = sig + (Dust2.ar(200) * 0.18);
    sig = HPF.ar(sig, 2000);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\AlienClang15, { |out=0, freq=1100, amp=0.3, decay=0.22, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay), doneAction:2);
    var sig = Ringz.ar(Impulse.ar(10), freq * LFNoise1.kr(2).range(0.7,1.3), 0.1) * env;
    sig = sig + (Crackle.ar(1.2) * 0.12);
    sig = sig + (BPF.ar(PinkNoise.ar, freq * 1.2, 0.09) * 0.1);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

// --- Pleasant tonal synths with longer decay ---
SynthDef(\Kalimba16, { |out=0, freq=440, amp=0.2, decay=1.2, pan=0|
    var env = EnvGen.kr(Env.perc(0.01, decay, 1, -4), doneAction:2);
    var sig = Pluck.ar(WhiteNoise.ar(amp), env, 1, 1, decay, 0.5);
    sig = sig + SinOsc.ar(freq * 2, 0, 0.1) * env;
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\SineBell17, { |out=0, freq=660, amp=0.18, decay=1.5, pan=0|
    var env = EnvGen.kr(Env.perc(0.01, decay, 1, -6), doneAction:2);
    var sig = SinOsc.ar(freq, 0, 0.7) * env;
    sig = sig + SinOsc.ar(freq * 2.01, 0, 0.2) * env;
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\SoftChime18, { |out=0, freq=880, amp=0.15, decay=2.0, pan=0|
    var env = EnvGen.kr(Env.perc(0.01, decay, 1, -8), doneAction:2);
    var sig = SinOsc.ar(freq, 0, 0.5) * env;
    sig = sig + (SinOsc.ar(freq * 3, 0, 0.1) * env);
    sig = sig + (WhiteNoise.ar(0.02) * env);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\GlassMarimba19, { |out=0, freq=550, amp=0.17, decay=1.3, pan=0|
    var env = EnvGen.kr(Env.perc(0.01, decay, 1, -5), doneAction:2);
    var sig = SinOsc.ar(freq, 0, 0.5) * env;
    sig = sig + (SinOsc.ar(freq * 2.5, 0, 0.2) * env);
    sig = sig + (SinOsc.ar(freq * 4, 0, 0.1) * env);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

SynthDef(\WarmVibes20, { |out=0, freq=370, amp=0.19, decay=1.7, pan=0|
    var env = EnvGen.kr(Env.perc(0.01, decay, 1, -7), doneAction:2);
    var sig = SinOsc.ar(freq, 0, 0.6) * env;
    sig = sig + (SinOsc.ar(freq * 1.5, 0, 0.2) * env);
    sig = sig + (SinOsc.ar(freq * 3, 0, 0.1) * env);
    Out.ar(out, Pan2.ar(sig * amp, pan));
}).add;

// --- Sine-based Bass Drum SynthDef ---
SynthDef(\SineKick21, { |out=0, freq=50, amp=0.5, decay=0.18, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay, 1, -4), doneAction:2);
    var pitchEnv = EnvGen.kr(Env([2.2, 1, 0.5], [0.018, decay * 0.8], 'exp'));
    var body = SinOsc.ar(freq * pitchEnv, 0, amp * 2) * env;
    var sub = SinOsc.ar(freq * 0.5, 0, amp * 0.5) * env;
    var click = HPF.ar(WhiteNoise.ar(0.02), 7000) * env * 0.2;
    var sig = (body + sub + click);
    sig = LPF.ar(sig, 1200);
    Out.ar(out, Pan2.ar(sig, pan));
}).add;

// --- New glitchy/metallic/noisy percussion synths (added) ---
SynthDef(\BitCrackle23, { |out=0, amp=0.3, bits=3, decay=0.18, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay, 1, -8), doneAction:2);
    var crackle = Crackle.ar(LFNoise1.kr(8).range(1.7, 2.0)) * env * LFNoise2.kr(30).range(0.7, 1.2);
    var sig = Decimator.ar(crackle, 9000, bits);
    sig = HPF.ar(sig, 5000 + LFNoise1.kr(2).range(0, 2000));
    sig = sig + (WhiteNoise.ar(0.09) * env * LFNoise1.kr(12).range(0.6, 1.3));
    sig = sig + (Crackle.ar(1.95) * 0.07 * LFNoise2.kr(20).range(0.5, 1.5));
    sig = Limiter.ar(sig, 0.99);
    Out.ar(out, Pan2.ar(sig * amp, pan + LFNoise1.kr(0.5).range(-0.2, 0.2)));
}).add;

SynthDef(\BuzzZap24, { |out=0, freq=950, amp=0.28, decay=0.15, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay, 1, -8), doneAction:2);
    var pulse = LFPulse.ar(freq * LFNoise1.kr(12).range(0.7, 1.5), 0, LFNoise1.kr(6).range(0.1, 0.4)) * env * LFNoise2.kr(40).range(0.6, 1.2);
    var crackle = Crackle.ar(LFNoise1.kr(10).range(1.5, 1.9)) * 0.13 * LFNoise2.kr(18).range(0.7, 1.3);
    var sig = pulse + crackle;
    sig = HPF.ar(sig, 6000 + LFNoise1.kr(1).range(0, 2000));
    sig = sig + (WhiteNoise.ar(0.07) * env * LFNoise1.kr(10).range(0.5, 1.2));
    sig = Limiter.ar(sig, 0.99);
    Out.ar(out, Pan2.ar(sig * amp, pan + LFNoise1.kr(0.4).range(-0.15, 0.15)));
}).add;

SynthDef(\StaticBurst25, { |out=0, amp=0.32, decay=0.13, pan=0|
    var env = EnvGen.kr(Env.perc(0.0007, decay, 1, -10), doneAction:2);
    var noise = LFNoise2.ar(18000) * env * LFNoise1.kr(15).range(0.7, 1.3);
    var dust = Dust2.ar(1200) * 0.18 * LFNoise1.kr(8).range(0.5, 1.5);
    var sig = noise + dust;
    sig = HPF.ar(sig, 7000 + LFNoise1.kr(2).range(0, 2000));
    sig = sig + (WhiteNoise.ar(0.11) * env * LFNoise1.kr(10).range(0.5, 1.2));
    sig = Limiter.ar(sig, 0.99);
    Out.ar(out, Pan2.ar(sig * amp, pan + LFNoise1.kr(0.3).range(-0.1, 0.1)));
}).add;

SynthDef(\MetallicFizz26, { |out=0, freq=1300, amp=0.29, decay=0.14, pan=0|
    var env = EnvGen.kr(Env.perc(0.001, decay, 1, -8), doneAction:2);
    var fizz = BPF.ar(WhiteNoise.ar(0.25), freq * LFNoise1.kr(14).range(1.0, 1.7), LFNoise1.kr(7).range(0.03, 0.09));
    var ring = Ringz.ar(Impulse.ar(200 * LFNoise1.kr(2).range(0.8, 1.2)), freq * 1.2, 0.01) * 0.13 * LFNoise1.kr(6).range(0.7, 1.3);
    var sig = fizz + ring;
    fizz = fizz * env * LFNoise2.kr(18).range(0.7, 1.3);
    sig = HPF.ar(sig, 7000 + LFNoise1.kr(2).range(0, 2000));
    sig = sig + (WhiteNoise.ar(0.08) * env * LFNoise1.kr(10).range(0.5, 1.2));
    sig = Limiter.ar(sig, 0.99);
    Out.ar(out, Pan2.ar(sig * amp, pan + LFNoise1.kr(0.3).range(-0.1, 0.1)));
}).add;

SynthDef(\GlitchSnap27, { |out=0, freq=1700, amp=0.27, decay=0.09, pan=0|
    var env = EnvGen.kr(Env.perc(0.0007, decay, 1, -10), doneAction:2);
    var snap = HPF.ar(WhiteNoise.ar(0.18), 9000 + LFNoise1.kr(2).range(0, 3000)) * env * LFNoise1.kr(20).range(0.7, 1.3);
    var glitch = LFNoise1.kr(60).range(0.7, 1.5);
    var dust = Dust2.ar(2200) * 0.09 * LFNoise1.kr(10).range(0.5, 1.5);
    var bubble = SinOsc.ar(LFNoise1.kr(8).range(80, 180) + LFNoise1.kr(2).range(0, 40)) * EnvGen.kr(Env.perc(0.001, decay * 0.7), doneAction:0) * 0.18;
    var tin = BPF.ar(snap, 11000 + LFNoise1.kr(3).range(-2000, 2000), 0.12, 1.2);
    var sig = (snap * glitch + dust + bubble + tin);
    sig = sig + (Crackle.ar(1.98) * 0.04 * LFNoise2.kr(18).range(0.5, 1.5));
    sig = HPF.ar(sig, 7000); // emphasize high end, remove lows
    sig = Limiter.ar(sig, 0.99);
    sig = sig * 2;
    Out.ar(out, Pan2.ar(sig * amp, pan + LFNoise1.kr(0.2).range(-0.1, 0.1)));
}).add;
