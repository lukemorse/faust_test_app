#import "FaustAudioEngine.h"

#import <cmath>
#import <memory>

#import "DSP/DspFaust.h"
#import <AVFoundation/AVFoundation.h>

@interface FaustAudioEngine () {
  std::unique_ptr<DspFaust> _dsp;
}
@end

@implementation FaustAudioEngine

- (instancetype)initWithSampleRate:(int)sampleRate bufferSize:(int)bufferSize {
  self = [super init];
  if (self) {
    // Honor the active audio session's resolved format to avoid mismatches between
    // the Core Audio render callback and the Faust driver.
    AVAudioSession *session = [AVAudioSession sharedInstance];
    const double resolvedSampleRate = session.sampleRate;
    const double resolvedBufferSize = session.IOBufferDuration * resolvedSampleRate;

    // Clamp to positive integers while preserving the requested values as a fallback.
    const int effectiveSampleRate = resolvedSampleRate > 0 ? (int)llround(resolvedSampleRate) : sampleRate;
    const int effectiveBufferSize = resolvedBufferSize > 0 ? (int)llround(resolvedBufferSize) : bufferSize;

    if (effectiveSampleRate != sampleRate || effectiveBufferSize != bufferSize) {
      NSLog(
          @"FaustAudioEngine: overriding requested format (%d Hz, %d) with active session (%d Hz, %d)",
          sampleRate,
          bufferSize,
          effectiveSampleRate,
          effectiveBufferSize);
    }

    _dsp = std::make_unique<DspFaust>(effectiveSampleRate, effectiveBufferSize, /*auto_connect=*/true);
  }
  return self;
}

- (BOOL)start {
  if (!_dsp) {
    return NO;
  }
  return _dsp->start();
}

- (void)stop {
  if (_dsp) {
    _dsp->stop();
  }
}

- (void)teardown {
  if (_dsp) {
    _dsp->stop();
    _dsp.reset();
  }
}

- (BOOL)isRunning {
  return _dsp ? _dsp->isRunning() : NO;
}

- (void)setParameter:(NSString *)address value:(float)value {
  if (!_dsp) {
    return;
  }
  _dsp->setParamValue([address UTF8String], value);
}

- (float)getParameter:(NSString *)address {
  if (!_dsp) {
    return 0.0f;
  }
  return _dsp->getParamValue([address UTF8String]);
}

- (NSArray<NSString *> *)parameterAddresses {
  if (!_dsp) {
    return @[];
  }

  const int count = _dsp->getParamsCount();
  NSMutableArray<NSString *> *addresses = [NSMutableArray arrayWithCapacity:count];

  for (int index = 0; index < count; ++index) {
    const char *address = _dsp->getParamAddress(index);
    if (address != nullptr) {
      [addresses addObject:[NSString stringWithUTF8String:address]];
    }
  }
  return [addresses copy];
}

@end
