# Faust static library integration

The Flutter iOS target expects a prebuilt universal static library that wraps the generated Faust DSP.
Place the output of the dedicated Xcode static-library target at:

- `ios/Faust/libfaustwrapper.a`

The target should include `faust_c_wrapper.cpp`/`ios-faust.h` and link against the bundled `ios-libsndfile.a` found in `ios_example`. The Xcode project is configured with header and library search paths pointing to this folder and will link both `libfaustwrapper.a` and `ios-libsndfile.a` when they are present.

If you rebuild the DSP, regenerate `ios-faust.h` alongside the new library and keep `faust_c_wrapper.h` in sync with any C ABI changes.
