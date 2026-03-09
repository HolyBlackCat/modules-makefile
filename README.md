## A makefile to build C++20 modules

This is a makefile that builds C++20 modules on Clang, GCC, and MSVC.

Run `make` to build the executable `build/program` from the contents of `src/`.

This makefile was tested on Linux, but should hopefully work on Windows too.


### Choosing the compiler

Use `make CXX=...` to choose the compiler, where `...` is one of: `clang++`, `g++`, `cl` (possibly suffixed with a version).

### `import std;`

Enabled by default, pass `ENABLE_STD_MODULE=0` to disable.

### Module map

Enabled for GCC. Not supported by Clang.

Disabled by default for MSVC, can be enabled using `ENABLE_MODULE_MAP=1` for it.

We don't support disabling it for GCC.

### Non-cascading changes

Enabled by default, pass `NON_CASCADING_CHANGES=0` to disable.

Note that GCG (15.x, the latest at the time of writing) doesn't have reproducible BMI builds, so this is pointless on GCC.

### Different standard libraries on Clang

Supported on Clang, pass the necessary flags to `CXXFLAGS=...`. This should work with libstdc++, libc++, and MSVC STL.
