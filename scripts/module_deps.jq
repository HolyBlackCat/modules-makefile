# Converts P1689R5-style module deps to a makefile fragment.
# Run as `jq -r --arg src blah.cpp` (GCC doesn't report the source filename to the json, so we can't use that).

if .rules[0].provides then
    (.rules[0].provides[0]."logical-name" | gsub(":";"-")) as $mname | (
        "MODULES += \($mname)",
        "__m_is_interface_\($mname) := \(if .rules[0].provides[0]."is-interface" then "y" else "" end)",
        "__m_source_\($mname) := \($src)",
        "__m_provides_\($src) := \($mname)"
    )
else
    empty
end,

"__m_imports_\($src) := \([.rules[0].requires[]?."logical-name" | gsub(":";"-")] | join(" "))"
