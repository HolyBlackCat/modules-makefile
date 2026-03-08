#!/bin/bash

set -eux

# Without BMI modification checks:

# Simple single-phase builds.
rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 -j
rm -rf build && CXX=g++ make SKIP_UNCHANGED_BMIS=0 -j && touch src/b.cppm && CXX=g++ make SKIP_UNCHANGED_BMIS=0 -j
rm -rf build && CXX=cl make SKIP_UNCHANGED_BMIS=0 -j && touch src/b.cppm && CXX=cl make SKIP_UNCHANGED_BMIS=0 -j

# MSVC with a module map.
rm -rf build && CXX=cl make SKIP_UNCHANGED_BMIS=0 ENABLE_MODULE_MAP=1 -j && touch src/b.cppm && CXX=cl make SKIP_UNCHANGED_BMIS=0 ENABLE_MODULE_MAP=1 -j

# Clang's two-phase builds.
rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=1_fullbmi -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=1_fullbmi -j
rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2seq_fullbmi -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2seq_fullbmi -j
rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2seq -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2seq -j
# Needs Clang 23 or newer:
# rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2par -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2par -j
rm -rf build && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2par_emulated -j && touch src/b.cppm && CXX=clang++ make SKIP_UNCHANGED_BMIS=0 MODULE_STRATEGY=2par_emulated -j


# With BMI modification checks:

# Simple single-phase builds.
rm -rf build && CXX=clang++ make -j && touch src/b.cppm && CXX=clang++ make -j
rm -rf build && CXX=g++ make -j && touch src/b.cppm && CXX=g++ make -j
rm -rf build && CXX=cl make -j && touch src/b.cppm && CXX=cl make -j

# MSVC with a module map.
rm -rf build && CXX=cl make ENABLE_MODULE_MAP=1 -j && touch src/b.cppm && CXX=cl make ENABLE_MODULE_MAP=1 -j

# Clang's two-phase builds.
rm -rf build && CXX=clang++ make MODULE_STRATEGY=1_fullbmi -j && touch src/b.cppm && CXX=clang++ make MODULE_STRATEGY=1_fullbmi -j
rm -rf build && CXX=clang++ make MODULE_STRATEGY=2seq_fullbmi -j && touch src/b.cppm && CXX=clang++ make MODULE_STRATEGY=2seq_fullbmi -j
rm -rf build && CXX=clang++ make MODULE_STRATEGY=2seq -j && touch src/b.cppm && CXX=clang++ make MODULE_STRATEGY=2seq -j
# Needs Clang 23 or newer:
# rm -rf build && CXX=clang++ make MODULE_STRATEGY=2par -j && touch src/b.cppm && CXX=clang++ make MODULE_STRATEGY=2par -j
rm -rf build && CXX=clang++ make MODULE_STRATEGY=2par_emulated -j && touch src/b.cppm && CXX=clang++ make MODULE_STRATEGY=2par_emulated -j
