#import "FaustAudioEngine.h"

#import <memory>

#import "DSP/DspFaust.h"

@interface FaustAudioEngine () {
  std::unique_ptr<DspFaust> _dsp;
}
@end

@implementation FaustAudioEngine

- (instancetype)initWithSampleRate:(int)sampleRate bufferSize:(int)bufferSize {
  self = [super init];
  if (self) {
    _dsp = std::make_unique<DspFaust>(sampleRate, bufferSize, /*auto_connect=*/true);
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
