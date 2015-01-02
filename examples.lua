local lpcre = require 'lpcre'

print(string.format("PCRE version is: %s", lpcre.version()))
print('PCRE build configuration:')

for k,v in pairs(lpcre.config()) do
  print(string.format('   %s: %s', tostring(k), tostring(v)))
end

local re_version = lpcre.compile([[(\d+)\.(\d+)]])
local match = re_version:match(_VERSION)

print(string.format("_VERSION has a version number it it: %s", match:group(0)))
print(string.format("  major: %s", match:group(1)))
print(string.format("  minor: %s", match:group(2)))

local jit = require 'jit'

local re_jitversion = lpcre.compile([[(\d+)\.(\d+)\.(\d+)]])
local jitmatch = re_jitversion:match(jit.version)

print(string.format("The LuaJIT version is: major:%s minor:%s patch:%s", jitmatch:group(1), jitmatch:group(2), jitmatch:group(3)))

local hexparser_short = lpcre.compile([[^\#(?P<r>[0-9a-fA-F])(?P<g>[0-9a-fA-F])(?P<b>[0-9a-fA-F])$]])
local hexparser_long = lpcre.compile([[^\#(?P<r>[0-9a-fA-F]{2})(?P<g>[0-9a-fA-F]{2})(?P<b>[0-9a-fA-F]{2})$]])
local hexparser_rgb = lpcre.compile([[^rgb\((?P<r>\d+)\,(?P<g>\d+)\,(?P<b>\d+)\)$]])

hexparser_short:study_jit()
hexparser_long:study_jit()
hexparser_rgb:study_jit()

local function parseColor(def)
  local m = hexparser_short:match(def)
  if m then
    return {
      r = tonumber(m:group('r')..m:group('r'), 16), 
      g = tonumber(m:group('g')..m:group('g'), 16), 
      b = tonumber(m:group('b')..m:group('b'), 16),
    }
  end
  m = hexparser_long:match(def)
  if m then
    return {
      r = tonumber(m:group('r'), 16), 
      g = tonumber(m:group('g'), 16), 
      b = tonumber(m:group('b'), 16),
    }
  end
  m = hexparser_rgb:match(def)
  if m then
    return {
      r = tonumber(m:group('r')),
      g = tonumber(m:group('g')),
      b = tonumber(m:group('b')),
    }
  end
end

function printColor(x)
  local extracted = parseColor(x)
  if extracted then
    print(string.format('The input \'%s\' is a color with r:%d g:%d b:%d',
      x,
      extracted.r,
      extracted.g,
      extracted.b))
  else
    print(string.format('The input \'%s\' does not look like a color', x))
  end
end

printColor('#eee')
printColor('eee')
printColor('#ffffff')
printColor('aaaaaaa')
printColor('#jjj')
printColor('#fffff')
printColor('rgb(255,255,127)')
printColor('rg(255,255,127)')

for value, start_index, end_index in hexparser_rgb:match('rgb(63,127,191)'):itergroups() do
  print(string.format("Found \'%s\' between %d and %d (inclusive)", value, start_index, end_index))
end
