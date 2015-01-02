local lpcre = {}
local ffi = require 'ffi'
local bit = require 'bit'

ffi.cdef [[

/*************************************************
*       Perl-Compatible Regular Expressions      *
*************************************************/

/* 
           Copyright (c) 1997-2012 University of Cambridge

-----------------------------------------------------------------------------
Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.

    * Redistributions in binary form must reproduce the above copyright
      notice, this list of conditions and the following disclaimer in the
      documentation and/or other materials provided with the distribution.

    * Neither the name of the University of Cambridge nor the names of its
      contributors may be used to endorse or promote products derived from
      this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.
-----------------------------------------------------------------------------
*/

/* The current PCRE version information. */

static const int PCRE_CASELESS       = 0x00000001;  /* Compile */
static const int PCRE_MULTILINE      = 0x00000002;  /* Compile */
static const int PCRE_DOTALL         = 0x00000004;  /* Compile */
static const int PCRE_EXTENDED       = 0x00000008;  /* Compile */
static const int PCRE_ANCHORED       = 0x00000010;  /* Compile, exec, DFA exec */
static const int PCRE_DOLLAR_ENDONLY = 0x00000020;  /* Compile, used in exec, DFA exec */
static const int PCRE_EXTRA          = 0x00000040;  /* Compile */
static const int PCRE_NOTBOL         = 0x00000080;  /* Exec, DFA exec */
static const int PCRE_NOTEOL         = 0x00000100;  /* Exec, DFA exec */
static const int PCRE_UNGREEDY       = 0x00000200;  /* Compile */
static const int PCRE_NOTEMPTY       = 0x00000400;  /* Exec, DFA exec */
/* The next two are also used in exec and DFA exec */
static const int PCRE_UTF8            = 0x00000800;  /* Compile (same as PCRE_UTF16) */
static const int PCRE_UTF16           = 0x00000800;  /* Compile (same as PCRE_UTF8) */
static const int PCRE_NO_AUTO_CAPTURE = 0x00001000;  /* Compile */
/* The next two are also used in exec and DFA exec */
static const int PCRE_NO_UTF8_CHECK      = 0x00002000;  /* Compile (same as PCRE_NO_UTF16_CHECK) */
static const int PCRE_NO_UTF16_CHECK     = 0x00002000;  /* Compile (same as PCRE_NO_UTF8_CHECK) */
static const int PCRE_AUTO_CALLOUT       = 0x00004000;  /* Compile */
static const int PCRE_PARTIAL_SOFT       = 0x00008000;  /* Exec, DFA exec */
static const int PCRE_PARTIAL            = 0x00008000;  /* Backwards compatible synonym */
static const int PCRE_DFA_SHORTEST       = 0x00010000;  /* DFA exec */
static const int PCRE_DFA_RESTART        = 0x00020000;  /* DFA exec */
static const int PCRE_FIRSTLINE          = 0x00040000;  /* Compile, used in exec, DFA exec */
static const int PCRE_DUPNAMES           = 0x00080000;  /* Compile */
static const int PCRE_NEWLINE_CR         = 0x00100000;  /* Compile, exec, DFA exec */
static const int PCRE_NEWLINE_LF         = 0x00200000;  /* Compile, exec, DFA exec */
static const int PCRE_NEWLINE_CRLF       = 0x00300000;  /* Compile, exec, DFA exec */
static const int PCRE_NEWLINE_ANY        = 0x00400000;  /* Compile, exec, DFA exec */
static const int PCRE_NEWLINE_ANYCRLF    = 0x00500000;  /* Compile, exec, DFA exec */
static const int PCRE_BSR_ANYCRLF        = 0x00800000;  /* Compile, exec, DFA exec */
static const int PCRE_BSR_UNICODE        = 0x01000000;  /* Compile, exec, DFA exec */
static const int PCRE_JAVASCRIPT_COMPAT  = 0x02000000;  /* Compile, used in exec */
static const int PCRE_NO_START_OPTIMIZE  = 0x04000000;  /* Compile, exec, DFA exec */
static const int PCRE_NO_START_OPTIMISE  = 0x04000000;  /* Synonym */
static const int PCRE_PARTIAL_HARD       = 0x08000000;  /* Exec, DFA exec */
static const int PCRE_NOTEMPTY_ATSTART   = 0x10000000;  /* Exec, DFA exec */
static const int PCRE_UCP                = 0x20000000;  /* Compile, used in exec, DFA exec */

/* Exec-time and get/set-time error codes */

static const int PCRE_ERROR_NOMATCH          = -1;
static const int PCRE_ERROR_NULL             = -2;
static const int PCRE_ERROR_BADOPTION        = -3;
static const int PCRE_ERROR_BADMAGIC         = -4;
static const int PCRE_ERROR_UNKNOWN_OPCODE   = -5;
static const int PCRE_ERROR_UNKNOWN_NODE     = -5;  /* For backward compatibility */
static const int PCRE_ERROR_NOMEMORY         = -6;
static const int PCRE_ERROR_NOSUBSTRING      = -7;
static const int PCRE_ERROR_MATCHLIMIT       = -8;
static const int PCRE_ERROR_CALLOUT          = -9;  /* Never used by PCRE itself */
static const int PCRE_ERROR_BADUTF8         = -10;  /* Same for 8/16 */
static const int PCRE_ERROR_BADUTF16        = -10;  /* Same for 8/16 */
static const int PCRE_ERROR_BADUTF8_OFFSET  = -11;  /* Same for 8/16 */
static const int PCRE_ERROR_BADUTF16_OFFSET = -11;  /* Same for 8/16 */
static const int PCRE_ERROR_PARTIAL         = -12;
static const int PCRE_ERROR_BADPARTIAL      = -13;
static const int PCRE_ERROR_INTERNAL        = -14;
static const int PCRE_ERROR_BADCOUNT        = -15;
static const int PCRE_ERROR_DFA_UITEM       = -16;
static const int PCRE_ERROR_DFA_UCOND       = -17;
static const int PCRE_ERROR_DFA_UMLIMIT     = -18;
static const int PCRE_ERROR_DFA_WSSIZE      = -19;
static const int PCRE_ERROR_DFA_RECURSE     = -20;
static const int PCRE_ERROR_RECURSIONLIMIT  = -21;
static const int PCRE_ERROR_NULLWSLIMIT     = -22;  /* No longer actually used */
static const int PCRE_ERROR_BADNEWLINE      = -23;
static const int PCRE_ERROR_BADOFFSET       = -24;
static const int PCRE_ERROR_SHORTUTF8       = -25;
static const int PCRE_ERROR_SHORTUTF16      = -25;  /* Same for 8/16 */
static const int PCRE_ERROR_RECURSELOOP     = -26;
static const int PCRE_ERROR_JIT_STACKLIMIT  = -27;
static const int PCRE_ERROR_BADMODE         = -28;
static const int PCRE_ERROR_BADENDIANNESS   = -29;
static const int PCRE_ERROR_DFA_BADRESTART  = -30;

/* Specific error codes for UTF-8 validity checks */

static const int PCRE_UTF8_ERR0               = 0;
static const int PCRE_UTF8_ERR1               = 1;
static const int PCRE_UTF8_ERR2               = 2;
static const int PCRE_UTF8_ERR3               = 3;
static const int PCRE_UTF8_ERR4               = 4;
static const int PCRE_UTF8_ERR5               = 5;
static const int PCRE_UTF8_ERR6               = 6;
static const int PCRE_UTF8_ERR7               = 7;
static const int PCRE_UTF8_ERR8               = 8;
static const int PCRE_UTF8_ERR9               = 9;
static const int PCRE_UTF8_ERR10             = 10;
static const int PCRE_UTF8_ERR11             = 11;
static const int PCRE_UTF8_ERR12             = 12;
static const int PCRE_UTF8_ERR13             = 13;
static const int PCRE_UTF8_ERR14             = 14;
static const int PCRE_UTF8_ERR15             = 15;
static const int PCRE_UTF8_ERR16             = 16;
static const int PCRE_UTF8_ERR17             = 17;
static const int PCRE_UTF8_ERR18             = 18;
static const int PCRE_UTF8_ERR19             = 19;
static const int PCRE_UTF8_ERR20             = 20;
static const int PCRE_UTF8_ERR21             = 21;

/* Specific error codes for UTF-16 validity checks */

static const int PCRE_UTF16_ERR0              = 0;
static const int PCRE_UTF16_ERR1              = 1;
static const int PCRE_UTF16_ERR2              = 2;
static const int PCRE_UTF16_ERR3              = 3;
static const int PCRE_UTF16_ERR4              = 4;

/* Request types for pcre_fullinfo() */

static const int PCRE_INFO_OPTIONS            = 0;
static const int PCRE_INFO_SIZE               = 1;
static const int PCRE_INFO_CAPTURECOUNT       = 2;
static const int PCRE_INFO_BACKREFMAX         = 3;
static const int PCRE_INFO_FIRSTBYTE          = 4;
static const int PCRE_INFO_FIRSTCHAR          = 4;  /* For backwards compatibility */
static const int PCRE_INFO_FIRSTTABLE         = 5;
static const int PCRE_INFO_LASTLITERAL        = 6;
static const int PCRE_INFO_NAMEENTRYSIZE      = 7;
static const int PCRE_INFO_NAMECOUNT          = 8;
static const int PCRE_INFO_NAMETABLE          = 9;
static const int PCRE_INFO_STUDYSIZE         = 10;
static const int PCRE_INFO_DEFAULT_TABLES    = 11;
static const int PCRE_INFO_OKPARTIAL         = 12;
static const int PCRE_INFO_JCHANGED          = 13;
static const int PCRE_INFO_HASCRORLF         = 14;
static const int PCRE_INFO_MINLENGTH         = 15;
static const int PCRE_INFO_JIT               = 16;
static const int PCRE_INFO_JITSIZE           = 17;
static const int PCRE_INFO_MAXLOOKBEHIND     = 18;

/* Request types for pcre_config(). Do not re-arrange, in order to remain
compatible. */

static const int PCRE_CONFIG_UTF8                    = 0;
static const int PCRE_CONFIG_NEWLINE                 = 1;
static const int PCRE_CONFIG_LINK_SIZE               = 2;
static const int PCRE_CONFIG_POSIX_MALLOC_THRESHOLD  = 3;
static const int PCRE_CONFIG_MATCH_LIMIT             = 4;
static const int PCRE_CONFIG_STACKRECURSE            = 5;
static const int PCRE_CONFIG_UNICODE_PROPERTIES      = 6;
static const int PCRE_CONFIG_MATCH_LIMIT_RECURSION   = 7;
static const int PCRE_CONFIG_BSR                     = 8;
static const int PCRE_CONFIG_JIT                     = 9;
static const int PCRE_CONFIG_UTF16                  = 10;
static const int PCRE_CONFIG_JITTARGET              = 11;

/* Request types for pcre_study(). Do not re-arrange, in order to remain
compatible. */

static const int PCRE_STUDY_JIT_COMPILE                = 0x0001;
static const int PCRE_STUDY_JIT_PARTIAL_SOFT_COMPILE   = 0x0002;
static const int PCRE_STUDY_JIT_PARTIAL_HARD_COMPILE   = 0x0004;

/* Bit flags for the pcre[16]_extra structure. Do not re-arrange or redefine
these bits, just add new ones on the end, in order to remain compatible. */

static const int PCRE_EXTRA_STUDY_DATA             = 0x0001;
static const int PCRE_EXTRA_MATCH_LIMIT            = 0x0002;
static const int PCRE_EXTRA_CALLOUT_DATA           = 0x0004;
static const int PCRE_EXTRA_TABLES                 = 0x0008;
static const int PCRE_EXTRA_MATCH_LIMIT_RECURSION  = 0x0010;
static const int PCRE_EXTRA_MARK                   = 0x0020;
static const int PCRE_EXTRA_EXECUTABLE_JIT         = 0x0040;

/* Types */

struct real_pcre;                 /* declaration; the definition is private  */
typedef struct real_pcre pcre;

struct real_pcre16;               /* declaration; the definition is private  */
typedef struct real_pcre16 pcre16;

struct real_pcre_jit_stack;       /* declaration; the definition is private  */
typedef struct real_pcre_jit_stack pcre_jit_stack;

struct real_pcre16_jit_stack;     /* declaration; the definition is private  */
typedef struct real_pcre16_jit_stack pcre16_jit_stack;

/* If PCRE is compiled with 16 bit character support, PCRE_UCHAR16 must contain
a 16 bit wide signed data type. Otherwise it can be a dummy data type since
pcre16 functions are not implemented. There is a check for this in pcre_internal.h. */

typedef unsigned short PCRE_UCHAR16;
typedef const PCRE_UCHAR16 * PCRE_SPTR16;

/* When PCRE is compiled as a C++ library, the subject pointer type can be
replaced with a custom type. For conventional use, the public interface is a
const char *. */

typedef const char * PCRE_SPTR;

/* The structure for passing additional data to pcre_exec(). This is defined in
such as way as to be extensible. Always add new fields at the end, in order to
remain compatible. */

typedef struct pcre_extra {
  unsigned long int flags;        /* Bits for which fields are set */
  void *study_data;               /* Opaque data from pcre_study() */
  unsigned long int match_limit;  /* Maximum number of calls to match() */
  void *callout_data;             /* Data passed back in callouts */
  const unsigned char *tables;    /* Pointer to character tables */
  unsigned long int match_limit_recursion; /* Max recursive calls to match() */
  unsigned char **mark;           /* For passing back a mark pointer */
  void *executable_jit;           /* Contains a pointer to a compiled jit code */
} pcre_extra;

/* Same structure as above, but with 16 bit char pointers. */

typedef struct pcre16_extra {
  unsigned long int flags;        /* Bits for which fields are set */
  void *study_data;               /* Opaque data from pcre_study() */
  unsigned long int match_limit;  /* Maximum number of calls to match() */
  void *callout_data;             /* Data passed back in callouts */
  const unsigned char *tables;    /* Pointer to character tables */
  unsigned long int match_limit_recursion; /* Max recursive calls to match() */
  PCRE_UCHAR16 **mark;            /* For passing back a mark pointer */
  void *executable_jit;           /* Contains a pointer to a compiled jit code */
} pcre16_extra;

/* The structure for passing out data via the pcre_callout_function. We use a
structure so that new fields can be added on the end in future versions,
without changing the API of the function, thereby allowing old clients to work
without modification. */

typedef struct pcre_callout_block {
  int          version;           /* Identifies version of block */
  /* ------------------------ Version 0 ------------------------------- */
  int          callout_number;    /* Number compiled into pattern */
  int         *offset_vector;     /* The offset vector */
  PCRE_SPTR    subject;           /* The subject being matched */
  int          subject_length;    /* The length of the subject */
  int          start_match;       /* Offset to start of this match attempt */
  int          current_position;  /* Where we currently are in the subject */
  int          capture_top;       /* Max current capture */
  int          capture_last;      /* Most recently closed capture */
  void        *callout_data;      /* Data passed in with the call */
  /* ------------------- Added for Version 1 -------------------------- */
  int          pattern_position;  /* Offset to next item in the pattern */
  int          next_item_length;  /* Length of next item in the pattern */
  /* ------------------- Added for Version 2 -------------------------- */
  const unsigned char *mark;      /* Pointer to current mark or NULL    */
  /* ------------------------------------------------------------------ */
} pcre_callout_block;

/* Same structure as above, but with 16 bit char pointers. */

typedef struct pcre16_callout_block {
  int          version;           /* Identifies version of block */
  /* ------------------------ Version 0 ------------------------------- */
  int          callout_number;    /* Number compiled into pattern */
  int         *offset_vector;     /* The offset vector */
  PCRE_SPTR16  subject;           /* The subject being matched */
  int          subject_length;    /* The length of the subject */
  int          start_match;       /* Offset to start of this match attempt */
  int          current_position;  /* Where we currently are in the subject */
  int          capture_top;       /* Max current capture */
  int          capture_last;      /* Most recently closed capture */
  void        *callout_data;      /* Data passed in with the call */
  /* ------------------- Added for Version 1 -------------------------- */
  int          pattern_position;  /* Offset to next item in the pattern */
  int          next_item_length;  /* Length of next item in the pattern */
  /* ------------------- Added for Version 2 -------------------------- */
  const PCRE_UCHAR16 *mark;       /* Pointer to current mark or NULL    */
  /* ------------------------------------------------------------------ */
} pcre16_callout_block;

/* Indirection for store get and free functions. These can be set to
alternative malloc/free functions if required. Special ones are used in the
non-recursive case for "frames". There is also an optional callout function
that is triggered by the (?) regex item. For Virtual Pascal, these definitions
have to take another form. */

void *(*pcre_malloc)(size_t);
void  (*pcre_free)(void *);
void *(*pcre_stack_malloc)(size_t);
void  (*pcre_stack_free)(void *);
int   (*pcre_callout)(pcre_callout_block *);

void *(*pcre16_malloc)(size_t);
void  (*pcre16_free)(void *);
void *(*pcre16_stack_malloc)(size_t);
void  (*pcre16_stack_free)(void *);
int   (*pcre16_callout)(pcre16_callout_block *);

/* User defined callback which provides a stack just before the match starts. */

typedef pcre_jit_stack *(*pcre_jit_callback)(void *);
typedef pcre16_jit_stack *(*pcre16_jit_callback)(void *);

/* Exported PCRE functions */

pcre *pcre_compile(const char *, int, const char **, int *,
                  const unsigned char *);
pcre16 *pcre16_compile(PCRE_SPTR16, int, const char **, int *,
                  const unsigned char *);
pcre *pcre_compile2(const char *, int, int *, const char **,
                  int *, const unsigned char *);
pcre16 *pcre16_compile2(PCRE_SPTR16, int, int *, const char **,
                  int *, const unsigned char *);
int  pcre_config(int, void *);
int  pcre16_config(int, void *);
int  pcre_copy_named_substring(const pcre *, const char *,
                  int *, int, const char *, char *, int);
int  pcre16_copy_named_substring(const pcre16 *, PCRE_SPTR16,
                  int *, int, PCRE_SPTR16, PCRE_UCHAR16 *, int);
int  pcre_copy_substring(const char *, int *, int, int,
                  char *, int);
int  pcre16_copy_substring(PCRE_SPTR16, int *, int, int,
                  PCRE_UCHAR16 *, int);
int  pcre_dfa_exec(const pcre *, const pcre_extra *,
                  const char *, int, int, int, int *, int , int *, int);
int  pcre16_dfa_exec(const pcre16 *, const pcre16_extra *,
                  PCRE_SPTR16, int, int, int, int *, int , int *, int);
int  pcre_exec(const pcre *, const pcre_extra *, PCRE_SPTR,
                   int, int, int, int *, int);
int  pcre16_exec(const pcre16 *, const pcre16_extra *,
                   PCRE_SPTR16, int, int, int, int *, int);
void pcre_free_substring(const char *);
void pcre16_free_substring(PCRE_SPTR16);
void pcre_free_substring_list(const char **);
void pcre16_free_substring_list(PCRE_SPTR16 *);
int  pcre_fullinfo(const pcre *, const pcre_extra *, int,
                  void *);
int  pcre16_fullinfo(const pcre16 *, const pcre16_extra *, int,
                  void *);
int  pcre_get_named_substring(const pcre *, const char *,
                  int *, int, const char *, const char **);
int  pcre16_get_named_substring(const pcre16 *, PCRE_SPTR16,
                  int *, int, PCRE_SPTR16, PCRE_SPTR16 *);
int  pcre_get_stringnumber(const pcre *, const char *);
int  pcre16_get_stringnumber(const pcre16 *, PCRE_SPTR16);
int  pcre_get_stringtable_entries(const pcre *, const char *,
                  char **, char **);
int  pcre16_get_stringtable_entries(const pcre16 *, PCRE_SPTR16,
                  PCRE_UCHAR16 **, PCRE_UCHAR16 **);
int  pcre_get_substring(const char *, int *, int, int,
                  const char **);
int  pcre16_get_substring(PCRE_SPTR16, int *, int, int,
                  PCRE_SPTR16 *);
int  pcre_get_substring_list(const char *, int *, int,
                  const char ***);
int  pcre16_get_substring_list(PCRE_SPTR16, int *, int,
                  PCRE_SPTR16 **);
const unsigned char *pcre_maketables(void);
const unsigned char *pcre16_maketables(void);
int  pcre_refcount(pcre *, int);
int  pcre16_refcount(pcre16 *, int);
pcre_extra *pcre_study(const pcre *, int, const char **);
pcre16_extra *pcre16_study(const pcre16 *, int, const char **);
void pcre_free_study(pcre_extra *);
void pcre16_free_study(pcre16_extra *);
const char *pcre_version(void);
const char *pcre16_version(void);

/* Utility functions for byte order swaps. */
int  pcre_pattern_to_host_byte_order(pcre *, pcre_extra *,
                  const unsigned char *);
int  pcre16_pattern_to_host_byte_order(pcre16 *, pcre16_extra *,
                  const unsigned char *);
int  pcre16_utf16_to_host_byte_order(PCRE_UCHAR16 *,
                  PCRE_SPTR16, int, int *, int);

/* JIT compiler related functions. */

pcre_jit_stack *pcre_jit_stack_alloc(int, int);
pcre16_jit_stack *pcre16_jit_stack_alloc(int, int);
void pcre_jit_stack_free(pcre_jit_stack *);
void pcre16_jit_stack_free(pcre16_jit_stack *);
void pcre_assign_jit_stack(pcre_extra *,
                  pcre_jit_callback, void *);
void pcre16_assign_jit_stack(pcre16_extra *,
                  pcre16_jit_callback, void *);
]]

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
