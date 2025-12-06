
// Legacy CoreAudio driver (uses deprecated AudioSession APIs). Disabled by
// default for modern SDK compatibility. Define FAUST_ENABLE_IOSAUDIO to 1
// before including this header if you need the CoreAudio hosting helpers.
#ifndef FAUST_ENABLE_IOSAUDIO
#define FAUST_ENABLE_IOSAUDIO 0
#endif

#if FAUST_ENABLE_IOSAUDIO

#endif // FAUST_ENABLE_IOSAUDIO

