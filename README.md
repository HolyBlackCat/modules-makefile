## A makefile to build C++20 modules

This is a makefile that builds C++20 modules on Clang, GCC, and MSVC. [This blog post](https://holyblackcat.github.io/blog/2026/03/09/compiling-modules.html) that explains the modules compilation procedure for different compilers.

Run `make` to build the executable `build/program` from the contents of `src/`.

This makefile was tested on Linux, but should hopefully work on Windows too.


### Choosing the compiler

Use `make CXX=...` to choose the compiler, where `...` is one of: `clang++`, `g++`, `cl` (possibly suffixed with a version).

Don't forget to delete the `build/` directory when changing the compiler.

### Choosing the modules compilation strategy

Only allowed for Clang. Read [this](https://holyblackcat.github.io/blog/2026/03/09/compiling-modules.html#two-phase-compilation) for an explanation.

Pass `MODULE_STRATEGY=...`, where `...` is one of:

* `1` is the usual single-phase compilation.
* `1_fullbmi` is the usual single-phase compilation, but with full BMIs instead of reduced BMIs.
* `2seq_fullbmi` is the sequential two-phase, where the first phase creates a full BMI, and the second phase creates an object file from it.
* `2seq` is similar, but the second phase additionally creates a reduced BMI, which is what gets imported.
* `2par` runs the two phases in parallel, instead of sequentially. The second phase creates the object file directly from the source instead of from the BMI. This requires Clang 23 or newer (not released yet at the time of writing).

* `2par_emulated` is like `2par`, but emulated for older Clangs. The first phase produces both a full BMI and a reduced BMI, and then we discard the full BMI. This makes it slow, but at least the procedure can be tested.


### `import std;`

Enabled by default, pass `ENABLE_STD_MODULE=0` to disable.

### Module map

Enabled for GCC. Not supported by Clang.

Disabled by default for MSVC, can be enabled using `ENABLE_MODULE_MAP=1` for it.

We don't support disabling it for GCC.

### Non-cascading changes

[Explanation.](https://holyblackcat.github.io/blog/2026/03/09/compiling-modules.html#non-cascading-changes) Enabled by default, pass `NON_CASCADING_CHANGES=0` to disable.

Note that GCG (15.x, the latest at the time of writing) doesn't have reproducible BMI builds, so this is pointless on GCC.

### Different standard libraries on Clang

Supported on Clang, pass the necessary flags to `CXXFLAGS=...`. This should work with libstdc++, libc++, and MSVC STL.
