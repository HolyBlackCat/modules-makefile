# Converts MSVC-style `/sourceDependencies` to `gcc -M -MP` style.
# Run as `jq -r --arg src blah.cpp --arg obj blah.o`.

"\($obj): \($src) \\", (.Data.Includes | [.[] | gsub("\\\\";"/")] | ((.[] | "  \(.) \\"), "", (.[] | "\(.):")))
