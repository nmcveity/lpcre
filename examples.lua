local lpcre = require 'lpcre'

local re_version = lpcre.compile([[(\d+)\.(\d+)]])
local match = re_version:match(_VERSION)

print(string.format("_VERSION has a version number it it: %s", match:group(0)))
print(string.format("  major: %s", match:group(1)))
print(string.format("  minor: %s", match:group(2)))

