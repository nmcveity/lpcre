--[[

This is free and unencumbered software released into the public domain.

Anyone is free to copy, modify, publish, use, compile, sell, or
distribute this software, either in source code form or as a compiled
binary, for any purpose, commercial or non-commercial, and by any
means.

In jurisdictions that recognize copyright laws, the author or authors
of this software dedicate any and all copyright interest in the
software to the public domain. We make this dedication for the benefit
of the public at large and to the detriment of our heirs and
successors. We intend this dedication to be an overt act of
relinquishment in perpetuity of all present and future rights to this
software under copyright law.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
IN NO EVENT SHALL THE AUTHORS BE LIABLE FOR ANY CLAIM, DAMAGES OR
OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE,
ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.

For more information, please refer to <http://unlicense.org>

]]

local lpcre = {}
local ffi = require 'ffi'
local bit = require 'bit'
local pcre_h = require 'lpcre.pcre_h'

ffi.cdef(pcre_h.contents)

local pcre = ffi.load 'pcre'

-------------------------------------------------------------------------------
-- Match object

local Match = {}
local Match_mt = { __index = Match }

function Match:initInstance(subject, re, ovector, ovectorsize)
  pcre.pcre_refcount(re, 1)
  self._subject = subject
  self._re = re
  self._groups = {}
  self._ovector = ovector
  self._ovectorsize = ovectorsize
end

function Match_mt:__gc()
  pcre.pcre_refcount(self._re, -1)
end

local function _iterate(data)
  local index = data.group
  data.group = data.group+1 
  if index < data.match._ovectorsize then
    return data.match:groupinfo(index)
  end
end

function Match:itergroups()
  return _iterate, {match=self, group=1}
end

function Match:groups()
  return self._groups
end

function Match:_validGroupIndex(n)
  return n >= 0 and n <= self._ovectorsize
end

function Match:_populateGroupIndex(n)
  local buffer = ffi.new('const char*[1]')
  local result = pcre.pcre_get_substring(self._subject, self._ovector, self._ovectorsize, tonumber(n), buffer)
  if result < 0 then
    error("error extracting string")
  end
  self._groups[n] = {
    value = ffi.string(buffer[0]),
    start_index = self._ovector[n*2],
    end_index = self._ovector[n*2+1]
  }
end

function Match:_populateGroupName(n)
  local buffer = ffi.new('const char*[1]')
  local result = pcre.pcre_get_named_substring(self._re, self._subject, self._ovector, self._ovectorsize, tostring(n), buffer)
  if result == pcre.PCRE_ERROR_NOSUBSTRING then
    return
  end
  if result < 0 then
    error("error extracting string")
  end
  self._groups[n] = {
    value = ffi.string(buffer[0]),
  }
  local groupIndex = pcre.pcre_get_stringnumber(self._re, tostring(n))
  if groupIndex > 0 then
    self._groups[n].start_index = self._ovector[groupIndex*2] 
    self._groups[n].end_index = self._ovector[groupIndex*2+1]
  end 
end

function Match:group(n)
  if type(n) == "number" then
    if not self:_validGroupIndex(n) then
      return
    end
    if not self._groups[n] then
      self:_populateGroupIndex(n)
    end
  elseif type(n) == "string" then
    self:_populateGroupName(n)
  end
  local g = self._groups[n]
  if g then
    return g.value
  end
end

function Match:groupinfo(n)
  if type(n) == "number" then
    if not self:_validGroupIndex(n) then
      return
    end
    if not self._groups[n] then
      self:_populateGroupIndex(n)
    end
  elseif type(n) == "string" then
    self:_populateGroupName(n)
  end
  local g = self._groups[n]
  if g then
    return g.value, g.start_index, g.end_index
  end
end

setmetatable(Match, {
  __call = function (proto, ...)
    local obj = {}
    setmetatable(obj, Match_mt)
    obj:initInstance(...)
    return obj
  end
})

-------------------------------------------------------------------------------
-- CompiledPattern object

local CompiledPattern = {}
local CompiledPattern_mt = { __index = CompiledPattern }

function CompiledPattern_mt:__gc()
  pcre.pcre_free(self._re)
  pcre.pcre_free_study(self._study)
  self._re = nil
end

function CompiledPattern:initInstance(re)
  self._re = re
  self.max_matches = 100
end

function CompiledPattern:study(...)
  if not self._study then
    local errptr = ffi.new('const char*[1]')
    self._study = pcre.pcre_study(self._re, bit.bor(0, ...), errptr)
    if errptr[0] ~= nil then
      error(ffi.string(errptr[0]))
    end
  end
end

function CompiledPattern:study_jit()
  self:study(pcre.PCRE_STUDY_JIT_COMPILE)
end

function CompiledPattern:match(subject, ...)
  return self:match_from(subject, 0, ...)
end

function CompiledPattern:match_from(subject, start_index, ...)
  local ovector = ffi.new('int[?]', self.max_matches*3)
  local execresult = pcre.pcre_exec(self._re, nil, subject, #subject, start_index, bit.bor(0, ...), ovector, self.max_matches*3)
  if execresult == pcre.PCRE_ERROR_NOMATCH then
    return
  end
  if execresult < 0 then
    error("Error executing regex: "..tostring(execresult))
  end
  return Match(subject, self._re, ovector, execresult)
end

function CompiledPattern:iterate_all(subject, ...)
  return coroutine.wrap(function ()
    local value, start_index, end_index = nil, 0, -1
    while end_index+1 < #subject do
      local m = self:match_from(subject, end_index+1)
      if not m then
        return
      end
      coroutine.yield(m)
      value, start_index, end_index = m:groupinfo(0)
    end
  end)
end

setmetatable(CompiledPattern, {
  __call = function (proto, ...)
    local obj = {}
    setmetatable(obj, CompiledPattern_mt)
    obj:initInstance(...)
    return obj
  end
})

-------------------------------------------------------------------------------
-- Module

function lpcre.compile(pattern, ...)
  local options = bit.bor(0, ...)
  local errorptr = ffi.new('const char*[1]', nil)
  local errorcodeptr = ffi.new('int[1]', 0)
  local erroroffset = ffi.new('int[1]', 0)
  local re = pcre.pcre_compile2(pattern, options, errorcodeptr, errorptr, erroroffset, nil)
  if not re then
    return nil, errorcodeptr[0], errorptr[0], erroroffset[0]
  end
  return CompiledPattern(re)
end

function lpcre.match(pattern, subject, ...)
  return lpcre.compile(pattern, ...):match(subject)
end

function lpcre.iterate_all(pattern, subject, ...)
  return lpcre.compile(pattern, ...):iterate_all(subject)
end

function lpcre.version()
  return ffi.string(pcre.pcre_version())
end

local function _getIntegerBoolean(what)
  local output = ffi.new('int[1]')
  local result = pcre.pcre_config(what, output)
  if result == 0 then
    return output[0] ~= 0
  end
end

local function _getInteger(what)
  local output = ffi.new('int[1]')
  local result = pcre.pcre_config(what, output)
  if result == 0 then
    return tonumber(output[0])
  end
end

local function _getLong(what)
  local output = ffi.new('long[1]')
  local result = pcre.pcre_config(what, output)
  if result == 0 then
    return tonumber(output[0])
  end
end

local function _getString(what)
  local output = ffi.new('const char*[1]')
  local result = pcre.pcre_config(what, output)
  if result == 0 then
    if output[0] ~= nil then
      return ffi.string(output[0])
    end
  end
end

local function _decodeNewLine(v)
  if v == 10 then
    return "LF"
  elseif v == 13 then
    return "CR"
  elseif v == 3338 then
    return "CRLF"
  elseif v == -2 then
    return "ANYCRLF"
  elseif v == -1 then
    return "ANY"
  end
end

local _config = nil

function lpcre.config()
  if not _config then
    _config = {
      ['utf8']
        = _getIntegerBoolean(pcre.PCRE_CONFIG_UTF8),
      ['unicode character properties']
        = _getIntegerBoolean(pcre. PCRE_CONFIG_UNICODE_PROPERTIES),
      ['jit']
        = _getIntegerBoolean(pcre.PCRE_CONFIG_JIT),
      ['jit target']
        = _getString(pcre.PCRE_CONFIG_JITTARGET),
      ['new line']
        = _decodeNewLine(_getInteger(pcre.PCRE_CONFIG_NEWLINE)),
      ['bsr']
        = _getInteger(pcre.PCRE_CONFIG_BSR),
      ['link size']
        = _getInteger(pcre.PCRE_CONFIG_LINK_SIZE),
      ['posix malloc threshold']
        = _getInteger(pcre.PCRE_CONFIG_POSIX_MALLOC_THRESHOLD),
      ['match limit']
        = _getLong(pcre.PCRE_CONFIG_MATCH_LIMIT),
      ['match limit recursion']
        = _getLong(pcre.PCRE_CONFIG_MATCH_LIMIT_RECURSION),
      ['stack recurse']
        = _getInteger(pcre.PCRE_CONFIG_STACKRECURSE),

    }
  end
  return _config
end

return lpcre
