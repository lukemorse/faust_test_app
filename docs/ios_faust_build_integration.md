# iOS Faust build integration (Runner target)

This project is now configured to compile and link the Faust DSP wrapper directly inside the iOS Runner target:

- **Source inclusion:** `ios/Faust/faust_c_wrapper.cpp` is part of the Runner target sources with the bridging header (`Runner/Runner-Bridging-Header.h`) importing `faust_c_wrapper.h` so Swift can call the C ABI.
- **C++ toolchain:** The Runner target build settings set `CLANG_CXX_LANGUAGE_STANDARD` to `gnu++17` and `CLANG_CXX_LIBRARY` to `libc++` for all configurations to satisfy the Faust code and wrapped STL usage.
- **Header search paths:** `$(PROJECT_DIR)/Faust/**` is on the Runner target header search paths so the generated Faust headers and bundled OSC library headers resolve without manual Xcode edits.
- **Library search paths:** `$(PROJECT_DIR)/Faust` and `$(PROJECT_DIR)/../ios_example` are on the Runner target library search paths, keeping the bundled `ios-libsndfile.a` discoverable.
- **Linked static libraries:** `ios_example/ios-libsndfile.a` is linked in the Runner target’s Frameworks phase for Faust code that depends on libsndfile.

These settings cover the C++ compilation and linking needs for the Faust DSP; subsequent steps can focus on audio graph wiring and Flutter channel/FFI bindings.
