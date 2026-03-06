# Used to create local variables in a safer way. E.g. `$(call var,x := 42)`.
override var = $(eval override $(subst #,$$(strip #),$(subst $,$$$$,$1)))

# Encloses $1 in single quotes, with proper escaping for the shell.
# If you makefile uses single quotes everywhere, a decent way to transition is to manually search and replace `'(\$(?:.|\(.*?\)))'` with `$(call quote,$1)`.
override quote = '$(subst ','"'"',$1)'

# A recursive wildcard function.
# $1 is the list of directories, $2 is the list of wildcards.
override rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))


SOURCE_DIRS := src
SOURCES := $(call rwildcard,src,*.cpp *.cppm)

OUTPUT_DIR := build
OBJ_DIR := $(OUTPUT_DIR)/obj

MODULE_MAP := $(OBJ_DIR)/module_map.txt


CXX ?= clang++

# Identify the compiler.
CXX_ID :=
ifeq ($(CXX_ID),)
ifneq ($(findstring clang++,$(notdir $(CXX))),)
CXX_ID := clang
else ifneq ($(findstring g++,$(notdir $(CXX))),)
CXX_ID := gcc
else ifneq ($(filter cl cl.exe,$(notdir $(CXX))),)
CXX_ID := msvc
endif
endif

# Select customizable compiler flags.
CXXFLAGS :=
ifeq ($(CXXFLAGS),)
ifeq ($(CXX_ID),msvc)
CXXFLAGS := /std:c++latest
else
CXXFLAGS := -std=c++26 -Wall -Wextra -pedantic-errors
endif
endif

# Select the important compiler flags.
FULL_CXXFLAGS :=
ifeq ($(FULL_CXXFLAGS),)
ifeq ($(CXX_ID),clang)
FULL_CXXFLAGS := $(CXXFLAGS)
else ifeq ($(CXX_ID),gcc)
FULL_CXXFLAGS := -fmodules $(CXXFLAGS)
else ifeq ($(CXX_ID),msvc)
FULL_CXXFLAGS := /nologo /EHsc /TP $(CXXFLAGS)
endif
endif

# The flags used for scanning header deps. GCC and Clang only.
# Replace `-M` with `-MM` to skip system headers.
HEADER_DEPS_FLAGS := -M

# Select the scanning strategy.
SCAN_MODULES =
ifeq ($(SCAN_MODULES),)
ifeq ($(CXX_ID),clang)
CLANG_SCAN_DEPS ?= clang-scan-deps
# $1 is the reported target filename for header deps
# $2 is the reported target filename for module deps
# $3 is the output filename for header deps
# $4 is the output filename for module deps
# $5 is the input file.
# $6 is the flags.
# The input file and flags should follow this string.
SCAN_MODULES = clang-scan-deps -format=p1689 -o $4 -- $(CXX) $5 $6 $(HEADER_DEPS_FLAGS) -MP -MF $3 -MQ $1 -o $2
else ifeq ($(CXX_ID),gcc)
SCAN_MODULES = $(CXX) $5 $6 $(HEADER_DEPS_FLAGS) -MP -fdeps-format=p1689r5 -fdeps-file=$4 -fdeps-target=$2 -MQ $1 -MF $3
else ifeq ($(CXX_ID),msvc)
SCAN_MODULES = ($(CXX) $5 $6 /scanDependencies $4 /sourceDependencies $3.json /Fo$2 && jq -r --arg src $5 --arg obj $1 -f scripts/msvc_deps.jq $3.json >$3)
endif
endif

MODULE_MAP_FLAG :=
ifeq ($(CXX_ID),gcc)
# Indicate that we need a module map.
MODULE_MAP_FLAG := -fmodule-mapper=
else
endif

override source_to_mdep = $(foreach f,$1,$(OBJ_DIR)/$f.mdep)
override source_to_dep = $(foreach f,$1,$(OBJ_DIR)/$f.d)
# This returns empty if this is not an importable module.
override source_to_bmi = $(foreach f,$1,$(if $(__m_provides_$f),$(OBJ_DIR)/$f.pcm))
override source_to_obj = $(foreach f,$1,$(OBJ_DIR)/$f.o)
override module_to_source = $(foreach m,$1,$(__m_source_$m))

# Include the scan results that we're about to generate.
include $(call source_to_mdep,$(SOURCES))

# Handle the source files.
$(foreach f,$(SOURCES),\
	$(call var,__mdep := $(call source_to_mdep,$f))\
	$(call, ### Scan.)\
	$(eval $(__mdep): $f | $(dir $(__mdep)) ; $(call SCAN_MODULES,$(__mdep),unused,$(call source_to_dep,$f),-,$f,$(FULL_CXXFLAGS)) | jq -r --arg src $f -f scripts/module_deps.jq >$(__mdep))\
	$(call, ### Introduce the dependencies of BMIs and object files on imported BMIs. It's easier to do both at the same time, without considering the module compilation strategy.)\
	$(eval $(call source_to_obj,$f) $(call source_to_bmi,$f): $(call source_to_bmi,$(call module_to_source,$(__m_imports_$f))))\
)



# Create directories on demand.
%/:
	mkdir -p $@
