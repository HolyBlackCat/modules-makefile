# Parses a GCC-style standard module manifest.
# Run as `jq -r --arg dir ...`, where `...` is the directory where the input JSON is located, with a trailing slash.
# Handles both GCC-style and MSVC-style manifests.

"__m_is_interface_std := y",
"__m_is_interface_std.compat := y",
if .library? == "microsoft/STL" then
    "\($dir)std.ixx" as $stdsrc |
    "\($dir)std.compat.ixx" as $stdcsrc |
    "SOURCES += $(abspath \($stdsrc) \($stdcsrc))",
    "__m_is_stdlib_$(abspath \($stdsrc)) := y",
    "__m_is_stdlib_$(abspath \($stdcsrc)) := y"
else
    (.modules[] | select(."logical-name" == "std") | ."source-path" | "\($dir)\(.)") as $stdsrc |
    (.modules[] | select(."logical-name" == "std.compat") | ."source-path" | "\($dir)\(.)") as $stdcsrc |
    "SOURCES += $(abspath \($stdsrc) \($stdcsrc))",
    "__m_is_stdlib_$(abspath \($stdsrc)) := y",
    "__m_is_stdlib_$(abspath \($stdcsrc)) := y"
end
