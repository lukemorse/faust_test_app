import("stdfaust.lib");

//===========================================
// MASTER CONTROLS
//===========================================
master_tempo = hslider("v:Master/[0]Tempo (BPM)", 120, 10, 480, 1);

//===========================================
// EUCLIDEAN RHYTHM GENERATOR
//===========================================
euclidean(steps, pulses, rotate, clock) = gate
with {
    // clamp and sanitize inputs
    s = max(1, int(steps));               // total steps
    p = max(0, min(int(pulses), s));      // limit pulses to available steps
    r = (int(rotate) % s + s) % s;        // safe rotation in range

    // advance the step counter only when the incoming clock ticks
    counter = (+(clock) : %(s)) ~ _;      // wraps after s steps

    // current and previous positions with rotation applied
    pos = (counter + r) % s;
    prevPos = (pos - 1 + s) % s;

    // Bjorklund-style test: fire when the integer division bucket changes
    bucket = int((pos * p) / s);
    prevBucket = int((prevPos * p) / s);
    shouldFire = bucket != prevBucket;

    // output a single-sample gate on clock ticks where a step should fire
    gate = clock * shouldFire;
};

//===========================================
// CRYSTAL BELLS - Very tonal, shimmering
//===========================================
crystalbells_synth = environment {
    steps = hslider("h:1_CrystalBells/[0]Steps", 16, 1, 32, 1);
    pulses = hslider("h:1_CrystalBells/[1]Pulses", 4, 0, 32, 1);
    rotate = hslider("h:1_CrystalBells/[2]Rotate", 0, 0, 32, 1);
    pitch = hslider("h:1_CrystalBells/[3]Pitch", 800, 200, 3000, 1);
    decay = hslider("h:1_CrystalBells/[4]Decay", 2.0, 0.2, 8.0, 0.1);
    shimmer = hslider("h:1_CrystalBells/[5]Shimmer", 0.7, 0, 1, 0.01);
    sparkle = hslider("h:1_CrystalBells/[6]Sparkle", 0.15, 0, 1, 0.01);
    randomize = hslider("h:1_CrystalBells/[7]Randomization", 0.3, 0, 1, 0.01);

    trigFreq = master_tempo / 60;
    phasor = os.phasor(1, trigFreq);
    clock = phasor < phasor';
    eucGate = euclidean(steps, pulses, rotate, clock);
    trigger = eucGate;
    
    rnd1 = ba.sAndH(trigger, no.noise);
    rnd2 = ba.sAndH(trigger, no.noise);
    rnd3 = ba.sAndH(trigger, no.noise);
    
    ampEnv = en.ar(0.001, decay, trigger);
    shimmerEnv = en.ar(0.01, decay * 1.5, trigger);
    
    basePitch = pitch * (1 + rnd1 * randomize * 0.2);
    harm1 = os.osc(basePitch) * 1.0;
    harm2 = os.osc(basePitch * 2.01) * 0.6;
    harm3 = os.osc(basePitch * 3.02) * 0.4;
    harm4 = os.osc(basePitch * 4.5) * 0.25;
    harm5 = os.osc(basePitch * 5.99) * 0.15;
    
    inharm1 = os.osc(basePitch * 2.76 + rnd2 * shimmer * 50) * 0.3;
    inharm2 = os.osc(basePitch * 6.28 + rnd3 * shimmer * 80) * 0.2;
    
    bells = (harm1 + harm2 + harm3 + harm4 + harm5) * 0.3;
    metal = (inharm1 + inharm2) * shimmer * shimmerEnv;
    
    sparkleNoise = no.noise * en.ar(0.0001, 0.02, trigger) * sparkle;
    sparkleFiltered = fi.highpass(2, 4000, sparkleNoise);
    
    raw = bells + metal + sparkleFiltered;
    sound = raw * ampEnv * 0.3;
}.sound;

//===========================================
// WOBBLE ZAP - Tonal with wobbling modulation
//===========================================
wobblezap_synth = environment {
    steps = hslider("h:2_WobbleZap/[0]Steps", 16, 1, 32, 1);
    pulses = hslider("h:2_WobbleZap/[1]Pulses", 5, 0, 32, 1);
    rotate = hslider("h:2_WobbleZap/[2]Rotate", 0, 0, 32, 1);
    pitch = hslider("h:2_WobbleZap/[3]Pitch", 150, 50, 800, 1);
    decay = hslider("h:2_WobbleZap/[4]Decay", 0.6, 0.1, 4.0, 0.01);
    wobble = hslider("h:2_WobbleZap/[5]Wobble", 0.7, 0, 1, 0.01);
    zappiness = hslider("h:2_WobbleZap/[6]Zappiness", 0.4, 0, 1, 0.01);
    chaos = hslider("h:2_WobbleZap/[7]Chaos", 0.3, 0, 1, 0.01);

    trigFreq = master_tempo / 60;
    phasor = os.phasor(1, trigFreq);
    clock = phasor < phasor';
    eucGate = euclidean(steps, pulses, rotate, clock);
    trigger = eucGate;
    
    rnd1 = ba.sAndH(trigger, no.noise);
    rnd2 = ba.sAndH(trigger, no.noise);
    
    ampEnv = en.ar(0.002, decay, trigger);
    wobbleEnv = en.ar(0.05, decay * 0.7, trigger);
    
    basePitch = pitch * (1 + rnd1 * chaos * 0.5);
    wobbleLFO = os.osc(8 + rnd2 * 12 * chaos) * wobble;
    
    osc1 = os.osc(basePitch * (1 + wobbleLFO * wobbleEnv)) * 0.4;
    osc2 = os.osc(basePitch * 1.99 * (1 + wobbleLFO * 0.5 * wobbleEnv)) * 0.3;
    osc3 = os.sawtooth(basePitch * 0.5 * (1 + wobbleLFO * 1.2 * wobbleEnv)) * 0.2;
    
    zapNoise = no.noise * en.ar(0.001, 0.03, trigger);
    zapFiltered = fi.bandpass(2, basePitch * 2, basePitch * 8, zapNoise) * zappiness;
    
    raw = osc1 + osc2 + osc3 + zapFiltered;
    sound = raw * ampEnv * 0.4;
}.sound;

//===========================================
// BUBBLE POP - Half tonal, half noisy
//===========================================
bubblepop_synth = environment {
    steps = hslider("h:3_BubblePop/[0]Steps", 16, 1, 32, 1);
    pulses = hslider("h:3_BubblePop/[1]Pulses", 7, 0, 32, 1);
    rotate = hslider("h:3_BubblePop/[2]Rotate", 0, 0, 32, 1);
    pitch = hslider("h:3_BubblePop/[3]Pitch", 600, 200, 2000, 1);
    decay = hslider("h:3_BubblePop/[4]Decay", 0.3, 0.05, 2.0, 0.01);
    poppiness = hslider("h:3_BubblePop/[5]Poppiness", 0.6, 0, 1, 0.01);
    fizz = hslider("h:3_BubblePop/[6]Fizz", 0.5, 0, 1, 0.01);
    wetness = hslider("h:3_BubblePop/[7]Wetness", 0.4, 0, 1, 0.01);

    trigFreq = master_tempo / 60;
    phasor = os.phasor(1, trigFreq);
    clock = phasor < phasor';
    eucGate = euclidean(steps, pulses, rotate, clock);
    trigger = eucGate;
    
    rnd1 = ba.sAndH(trigger, no.noise);
    
    ampEnv = en.ar(0.001, decay, trigger);
    popEnv = en.ar(0.001, decay * 0.2, trigger);
    fizzEnv = en.ar(0.01, decay * 0.6, trigger);
    
    basePitch = pitch * (1 + rnd1 * 0.3);
    bubblePitch = basePitch * (1 + popEnv * 3 * poppiness);
    
    bubble1 = os.osc(bubblePitch) * 0.5;
    bubble2 = os.osc(bubblePitch * 1.618) * 0.3;
    bubble3 = os.triangle(bubblePitch * 0.5) * 0.2;
    
    popNoise = no.noise * en.ar(0.0001, 0.01, trigger);
    popFiltered = fi.bandpass(2, bubblePitch * 0.5, bubblePitch * 3, popNoise) * poppiness;
    
    fizzNoise = no.noise * fizzEnv * fizz;
    fizzFiltered = fi.bandpass(2, 2000, 6000, fizzNoise);
    
    tonal = bubble1 + bubble2 + bubble3;
    wet = fi.lowpass(3, 1200 + wetness * 3000, tonal + popFiltered);
    dry = tonal + popFiltered;
    mixed = wet * wetness + dry * (1 - wetness) + fizzFiltered;
    
    sound = mixed * ampEnv * 0.4;
}.sound;

//===========================================
// SHIMMER WASH - Extended atmospheric noise
//===========================================
shimmerwash_synth = environment {
    steps = hslider("h:4_ShimmerWash/[0]Steps", 8, 1, 32, 1);
    pulses = hslider("h:4_ShimmerWash/[1]Pulses", 3, 0, 32, 1);
    rotate = hslider("h:4_ShimmerWash/[2]Rotate", 0, 0, 32, 1);
    frequency = hslider("h:4_ShimmerWash/[3]Frequency", 4000, 500, 12000, 1);
    decay = hslider("h:4_ShimmerWash/[4]Decay", 1.2, 0.1, 6.0, 0.1);
    texture = hslider("h:4_ShimmerWash/[5]Texture", 0.7, 0, 1, 0.01);
    wash = hslider("h:4_ShimmerWash/[6]Wash", 0.6, 0, 1, 0.01);
    drift = hslider("h:4_ShimmerWash/[7]Drift", 0.5, 0, 1, 0.01);

    trigFreq = master_tempo / 60;
    phasor = os.phasor(1, trigFreq);
    clock = phasor < phasor';
    eucGate = euclidean(steps, pulses, rotate, clock);
    trigger = eucGate;
    
    rnd1 = ba.sAndH(trigger, no.noise);
    rnd2 = ba.sAndH(trigger, no.noise);
    rnd3 = ba.sAndH(trigger, no.noise);
    
    ampEnv = en.ar(0.01, decay, trigger);
    washEnv = en.ar(0.05, decay * 1.5, trigger);
    driftEnv = en.ar(0.1, decay * 2.0, trigger);
    
    noise1 = no.noise;
    noise2 = no.noise;
    noise3 = no.noise;
    noise4 = no.noise;
    
    baseFreq = frequency * (1 + rnd1 * drift * 0.3);
    freq1 = baseFreq * (1 + os.osc(0.3 + rnd2 * 0.5) * drift * 0.2);
    freq2 = baseFreq * 1.618 * (1 + os.osc(0.47 + rnd3 * 0.4) * drift * 0.15);
    freq3 = baseFreq * 0.618;
    
    layer1 = fi.bandpass(2, freq1 * 0.8, freq1 * 1.3, noise1) * 0.3;
    layer2 = fi.bandpass(2, freq2 * 0.7, freq2 * 1.5, noise2) * 0.25;
    layer3 = fi.highpass(2, freq3, noise3) * 0.25;
    layer4 = fi.bandpass(2, baseFreq * 0.5, baseFreq * 2.5, noise4) * 0.2;
    
    noiseMix = (layer1 + layer2 + layer3 + layer4) * texture;
    
    shimmer1 = os.osc(freq1 * (1 + washEnv * 0.1)) * washEnv * wash * 0.2;
    shimmer2 = os.osc(freq2 * (1 + washEnv * 0.08)) * washEnv * wash * 0.15;
    shimmer3 = os.osc(freq1 * 2.5) * driftEnv * wash * 0.1;
    
    washMod = os.osc(0.2 + rnd1 * 0.3) * wash;
    washed = fi.bandpass(2, baseFreq * (1 + washMod * 0.3), baseFreq * (2 + washMod * 0.5), noiseMix + shimmer1 + shimmer2 + shimmer3);
    
    mixed = noiseMix * (1 - wash * 0.5) + washed * wash + shimmer1 + shimmer2 + shimmer3;
    compressed = ef.cubicnl(0.3, 0, mixed);
    
    sound = compressed * ampEnv * 0.35;
}.sound;

//===========================================
// MASTER MIXER
//===========================================
master_gain = hslider("v:Master/[1]Gain", 0.7, 0, 1, 0.01);

mixed = crystalbells_synth + wobblezap_synth + bubblepop_synth + shimmerwash_synth;

process = mixed * master_gain <: _, _;
