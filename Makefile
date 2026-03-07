# Used to create local variables in a safer way. E.g. `$(call var,x := 42)`.
override var = $(eval override $(subst #,$$(strip #),$(subst $,$$$$,$1)))

# Encloses $1 in single quotes, with proper escaping for the shell.
# If you makefile uses single quotes everywhere, a decent way to transition is to manually search and replace `'(\$(?:.|\(.*?\)))'` with `$(call quote,$1)`.
override quote = '$(subst ','"'"',$1)'

# A recursive wildcard function.
# $1 is the list of directories, $2 is the list of wildcards.
override rwildcard = $(foreach d,$(wildcard $(1:=/*)),$(call rwildcard,$d,$2) $(filter $(subst *,%,$2),$d))

# A line break.
override define lf :=
$(call)
$(call)
endef


SOURCE_DIRS := src
SOURCES := $(call rwildcard,src,*.cpp *.cppm)

OUTPUT_DIR := build
OBJ_DIR := $(OUTPUT_DIR)/obj

MODULE_MAP := $(OBJ_DIR)/module_map.txt

OUTPUT_FILE := $(OUTPUT_DIR)/program$(EXT_EXE)


# Detect the target OS.
ifeq ($(OS),Windows_NT)
TARGET_OS := windows
else
TARGET_OS := linux
endif

# The executable extension.
ifeq ($(TARGET_OS),windows)
EXT_EXE := .exe
else
EXT_EXE :=
endif


# Pick a compiler.
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
FULL_CXXFLAGS := /nologo /EHsc $(CXXFLAGS)
else
$(error Unknown CXX_ID: `$(CXX_ID)`)
endif
endif

# The flags to create object files. The object filename immediately follows this.
ifeq ($(CXX_ID),msvc)
OBJ_FLAGS := /c /TP /Fo
EXT_OBJ := .obj
else
OBJ_FLAGS := -c -o
EXT_OBJ := .o
endif

# The flags to link executables. The linker output filename immediately follows this.
ifeq ($(CXX_ID),msvc)
EXE_FLAGS := /link /out:
else
EXE_FLAGS := -o
endif

# The flag to select the BMI output location. The BMI path must immediately follow this, if not empty.
BMI_OUTPUT_FLAG :=
ifeq ($(CXX_ID),clang)
BMI_OUTPUT_FLAG := -fmodule-output=
else ifeq ($(CXX_ID),gcc)
# Nothing.
else ifeq ($(CXX_ID),msvc)
BMI_OUTPUT_FLAG := /ifcOutput
else
$(error Unknown CXX_ID: `$(CXX_ID)`)
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
SCAN_MODULES = ($(CXX) $5 $6 /TP /scanDependencies $4 /sourceDependencies $3.json /Fo$2 && jq -r --arg src $5 --arg obj $1 -f scripts/msvc_deps.jq $3.json >$3)
else
$(error Unknown CXX_ID: `$(CXX_ID)`)
endif
endif

# Enable module map? Can only be toggled on MSVC, defaults to off there.
ENABLE_MODULE_MAP := $(if $(filter gcc,$(CXX_ID)),1,0)
MODULE_MAP_FLAG :=
MODULE_MAP_PATTERN =
override ENABLE_MODULE_MAP := $(filter-out 0,$(ENABLE_MODULE_MAP))
ifeq ($(CXX_ID),clang)
$(if $(ENABLE_MODULE_MAP),$(error Clang doesn't support module maps.))
else ifeq ($(CXX_ID),gcc)
$(if $(ENABLE_MODULE_MAP),,$(error We don't support running GCC without a module map.))
# The module map filename immediately follows this.
MODULE_MAP_FLAG := -fmodule-mapper=
# $1 is the module name, $2 is the BMI path.
MODULE_MAP_PATTERN = $1 $2$(lf)
else ifeq ($(CXX_ID),msvc)
MODULE_MAP_FLAG := /ifcMap
# MSVC can take double quotes too, if you escape the contents.
MODULE_MAP_PATTERN = [[module]]$(lf)name = '$1'$(lf)ifc = '$2'$(lf)$(lf)
else
$(error Unknown CXX_ID: `$(CXX_ID)`)
endif

# More flags.
MODULE_IMPORT_FLAG :=
MODULE_EXPORT_INTERFACE_FLAG :=
MODULE_EXPORT_INTERAL_PARTITION_FLAG :=
MODULE_EXPORT_NOTHING_FLAG :=
ifeq ($(CXX_ID),clang)
# NAME=PATH immediately follows this.
MODULE_IMPORT_FLAG := -fmodule-file=
MODULE_EXPORT_INTERFACE_FLAG := -xc++-module
MODULE_EXPORT_INTERAL_PARTITION_FLAG := -xc++-module
MODULE_EXPORT_NOTHING_FLAG := -xc++
else ifeq ($(CXX_ID),gcc)
# Nothing.
else ifeq ($(CXX_ID),msvc)
MODULE_IMPORT_FLAG := /reference
MODULE_EXPORT_INTERFACE_FLAG := /interface
MODULE_EXPORT_INTERAL_PARTITION_FLAG := /internalPartition
else
$(error Unknown CXX_ID: `$(CXX_ID)`)
endif

override source_to_mdep = $(foreach f,$1,$(OBJ_DIR)/$f.mdep)
override source_to_dep = $(foreach f,$1,$(OBJ_DIR)/$f.d)
# This returns empty if this is not an importable module.
override source_to_module = $(foreach f,$1,$(__m_provides_$f))
# This returns empty if this is not an importable module.
override source_to_bmi = $(foreach f,$1,$(if $(__m_provides_$f),$(OBJ_DIR)/$f.pcm))
override source_to_obj = $(foreach f,$1,$(OBJ_DIR)/$f$(EXT_OBJ))
override module_to_source = $(foreach m,$1,$(__m_source_$m))
# Internal module name to public module name.
override module_to_mname = $(subst -,:,$1)
# Lists all recursive module dependencies of a source file.
override source_to_imported_modules_recursive = $(foreach f,$1,$(if $(filter undefined,$(origin __m__rec_imports_$f)),$(call var,__m__rec_imports_$f := $(sort $(foreach d,$(__m_imports_$f),$d $(call source_to_imported_modules_recursive,$(call module_to_source,$d))))))$(__m__rec_imports_$f))

# A list of all module dependency files.
override all_mdeps := $(call source_to_mdep,$(SOURCES))
# A list of all object files.
all_objs := $(call source_to_obj,$(SOURCES))

# Include the scan results that we're about to generate.
include $(all_mdeps)

# Handle the source files.
$(foreach f,$(SOURCES),\
	$(call var,__mdep := $(call source_to_mdep,$f))\
	$(call var,__obj := $(call source_to_obj,$f))\
	$(call, ### This is empty if this is not an importable module.)\
	$(call var,__module := $(call source_to_module,$f))\
	$(call, ### This is empty if this is not an importable module.)\
	$(call var,__bmi := $(call source_to_bmi,$f))\
	$(call, ### Scan.)\
	$(eval $(__mdep): $f | $(dir $(__mdep)) ; $(call SCAN_MODULES,$(__mdep),unused,$(call source_to_dep,$f),-,$f,$(FULL_CXXFLAGS)) | jq -r --arg src $f -f scripts/module_deps.jq >$(__mdep))\
	$(call, ### Introduce the dependencies of BMIs and object files on imported BMIs. It's easier to do both at the same time, without considering the module compilation strategy.)\
	$(eval $(__obj) $(__bmi): $(call source_to_bmi,$(call module_to_source,$(__m_imports_$f))))\
	$(call, ### Single-stage rules.)\
	$(eval $(__obj) $(__bmi) &: $f | $(dir $(__obj)) $(if $(ENABLE_MODULE_MAP),$(MODULE_MAP),$(all_mdeps)) ; $(strip \
		$(CXX) \
		$(FULL_CXXFLAGS) \
		$(OBJ_FLAGS)$(__obj) \
		$(if $(__module),\
			$(if $(BMI_OUTPUT_FLAG),$(BMI_OUTPUT_FLAG)$(__bmi))\
			$(if $(__m_is_interface_$(__module)),$(MODULE_EXPORT_INTERFACE_FLAG),$(MODULE_EXPORT_INTERAL_PARTITION_FLAG)) \
		) \
		$f \
		$(if $(ENABLE_MODULE_MAP),\
			$(MODULE_MAP_FLAG)$(MODULE_MAP)\
		,\
			$(foreach d,$(call source_to_imported_modules_recursive,$f),\
				$(if $(call module_to_source,$d),,$$(error Source file `$f` depends on an unknown module `$(call module_to_mname,$d)`))\
				$(MODULE_IMPORT_FLAG)$(call module_to_mname,$d)=$(call source_to_bmi,$(call module_to_source,$d))\
			)\
		)\
	))\
)

# Link.
.DEFAULT_GOAL := $(OUTPUT_FILE)
$(OUTPUT_FILE): $(all_objs)
	$(CXX) $(FULL_CXXFLAGS) $(filter %$(EXT_OBJ),$^) $(EXE_FLAGS)$@

# Create the module map if this compiler needs one.
ifneq ($(ENABLE_MODULE_MAP),)
$(MODULE_MAP): $(all_mdeps)
	$(file >$@,$(subst @@eol@@ ,,$(foreach m,$(MODULES),$(call MODULE_MAP_PATTERN,$(call module_to_mname,$m),$(call source_to_bmi,$(call module_to_source,$m)))@@eol@@) ))
endif

# Create directories on demand.
%/:
	mkdir -p $@
