# Faust static library integration

`faust_c_wrapper.cpp` is added directly to the Runner target, so Xcode will compile the Faust wrapper and generated DSP from source. Ensure `ios-faust.h` stays in sync with your generated Faust output and update `faust_c_wrapper.h` if the C ABI changes.

`ios_example/ios-libsndfile.a` remains linked from the repo for any Faust code that requires libsndfile.
