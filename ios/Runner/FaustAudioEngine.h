#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Thin Objective-C++ wrapper that owns the generated `DspFaust` instance and exposes
/// lifecycle and parameter controls to Swift.
@interface FaustAudioEngine : NSObject

/// Designated initializer. Provides the sample rate and buffer size used to construct `DspFaust`.
- (instancetype)initWithSampleRate:(int)sampleRate bufferSize:(int)bufferSize NS_DESIGNATED_INITIALIZER;
- (instancetype)init NS_UNAVAILABLE;
+ (instancetype)new NS_UNAVAILABLE;

/// Boots the Faust DSP and starts the iOS audio driver render loop.
- (BOOL)start;
/// Stops audio rendering but preserves the DSP instance for later reuse.
- (void)stop;
/// Releases the DSP instance and associated audio driver state.
- (void)teardown;
/// Indicates whether the Faust audio driver is currently running.
- (BOOL)isRunning;

/// Sets a parameter value by its Faust address (e.g. "/gain").
- (void)setParameter:(NSString *)address value:(float)value;
/// Retrieves a parameter value by address.
- (float)getParameter:(NSString *)address;
/// Lists the available parameter addresses published by the Faust DSP UI.
- (NSArray<NSString *> *)parameterAddresses;

@end

NS_ASSUME_NONNULL_END
