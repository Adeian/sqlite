########################################################################
# 2024 September 25
#
# The author disclaims copyright to this source code.  In place of
# a legal notice, here is a blessing:
#
#  * May you do good and not evil.
#  * May you find forgiveness for yourself and forgive others.
#  * May you share freely, never taking more than you give.
#
########################################################################
# Routines for Steve Bennett's autosetup which are common to trees
# managed in and around the umbrella of the SQLite project.
#
# This file was initially derived from one used in the libfossil
# project, authored by the same person who ported it here, and this is
# noted here only as an indication that there are no licensing issues
# despite this code having a handful of near-twins running around a
# handful of third-party source trees.
#
########################################################################
#
# Design notes:
#
# - Symbols with a suffix of _ are intended for internal use within
#   this file, and are not part of the API which auto.def files should
#   rely on.
#
# - By and large, autosetup prefers to update global state with the
#   results of feature checks, e.g. whether the compiler supports flag
#   --X.  In this developer's opinion that (A) causes more confusion
#   than it solves[^1] and (B) adds an unnecessary layer of "voodoo"
#   between the autosetup user and its internals. This module, in
#   contrast, instead injects the results of its own tests into
#   well-defined variables and leaves the integration of those values
#   to the caller's discretion.
#
# [1]: As an example: testing for the -rpath flag, using
# cc-check-flags, can break later checks which use
# [cc-check-function-in-lib ...] because the resulting -rpath flag
# implicitly becomes part of those tests. In the case of an rpath
# test, downstream tests may not like the $prefix/lib path added by
# the rpath test. To avoid such problems, we avoid (intentionally)
# updating global state via feature tests.
########################################################################

########################################################################
# $proj_ is an internal-use-only array for storing whatever generic
# internal stuff we need stored.
array set proj_ {}
set proj_(isatty) [isatty? stdout]

proc proj-warn {msg} {
  puts stderr "WARNING: $msg"
}
proc proj-fatal {msg} {
  show-notices
  puts stderr "ERROR: $msg"
  exit 1
}

########################################################################
# Kind of like a C assert if uplevel (eval) of $script is false,
# triggers a fatal error.
proc proj-assert {script} {
  if {![uplevel 1 $script]} {
    proj-fatal "Affirmation failed: $script"
  }
}

########################################################################
# If this function believes that the current console might support
# ANSI escape sequences then this returns $str wrapped in a sequence
# to bold that text, else it returns $str as-is.
proc proj-bold {str} {
  if {$::autosetup(iswin) || !$::proj_(isatty)} {
    return $str
  }
  return "\033\[1m${str}\033\[0m"
}

########################################################################
# Takes a multi-line message and emits it with consistent indentation
# using [user-notice] (which means its rendering will (A) go to stderr
# and (B) be delayed until the next time autosetup goes to output a
# message).
#
# If its first argument is -error then it renders the message
# immediately and then exits.
proc proj-indented-notice {args} {
  set fErr ""
  if {"-error" eq [lindex $args 0]} {
    set args [lassign $args fErr]
  }
  set lines [split [join $args] \n]
  foreach line $lines {
    user-notice "      [string trimleft $line]"
  }
  if {"" ne $fErr} {
    show-notices
    exit 1
  }
}

########################################################################
# Returns 1 if cross-compiling, else 0.
proc proj-is-cross-compiling {} {
  return [expr {[get-define host] ne [get-define build]}]
}

########################################################################
# proj-lshift_ shifts $count elements from the list named $listVar
# and returns them as a new list. On empty input, returns "".
#
# Modified slightly from: https://wiki.tcl-lang.org/page/lshift
proc proj-lshift_ {listVar {count 1}} {
  upvar 1 $listVar l
  if {![info exists l]} {
    # make the error message show the real variable name
    error "can't read \"$listVar\": no such variable"
  }
  if {![llength $l]} {
    # error Empty
    return ""
  }
  set r [lrange $l 0 [incr count -1]]
  set l [lreplace $l [set l 0] $count]
  return $r
}

########################################################################
# Expects to receive string input, which it splits on newlines, strips
# out any lines which begin with an number of whitespace followed by a
# '#', and returns a value containing the [append]ed results of each
# remaining line with a \n between each.
proc proj-strip-hash-comments_ {val} {
  set x {}
  foreach line [split $val \n] {
    if {![string match "#*" [string trimleft $line]]} {
      append x $line \n
    }
  }
  return $x
}

########################################################################
# A proxy for cc-check-function-in-lib which "undoes" any changes that
# routine makes to the LIBS define. Returns the result of
# cc-check-function-in-lib.
proc proj-check-function-in-lib {function libs {otherlibs {}}} {
  set found 0
  define-push {LIBS} {
    set found [cc-check-function-in-lib $function $libs $otherlibs]
  }
  return $found
}

########################################################################
# Searches for $header in a combination of dirs and subdirs, specified
# by the -dirs {LIST} and -subdirs {LIST} flags (each of which have
# sane defaults). Returns either the first matching dir or an empty
# string.  The return value does not contain the filename part.
proc proj-search-for-header-dir {header args} {
  set subdirs {include}
  set dirs {/usr /usr/local /mingw}
# Debatable:
#  if {![proj-is-cross-compiling]} {
#    lappend dirs [get-define prefix]
#  }
  while {[llength $args]} {
    switch -exact -- [lindex $args 0] {
      -dirs     { set args [lassign $args - dirs] }
      -subdirs  { set args [lassign $args - subdirs] }
      default   {
        proj-fatal "Unhandled argument: $args"
      }
    }
  }
  foreach dir $dirs {
    foreach sub $subdirs {
      if {[file exists $dir/$sub/$header]} {
        return "$dir/$sub"
      }
    }
  }
  return ""
}

########################################################################
# Usage: proj-find-executable-path ?-v? binaryName
#
# Works similarly to autosetup's [find-executable-path $binName] but:
#
# - If the first arg is -v, it's verbose about searching, else it's quiet.
#
# Returns the full path to the result or an empty string.
proc proj-find-executable-path {args} {
  set binName $args
  set verbose 0
  if {[lindex $args 0] eq "-v"} {
    set verbose 1
    set args [lassign $args - binName]
    msg-checking "Looking for $binName ... "
  }
  set check [find-executable-path $binName]
  if {$verbose} {
    if {"" eq $check} {
      msg-result "not found"
    } else {
      msg-result $check
    }
  }
  return $check
}

########################################################################
# Uses [proj-find-executable-path $binName] to (verbosely) search for
# a binary, sets a define (see below) to the result, and returns the
# result (an empty string if not found).
#
# The define'd name is: if defName is empty then "BIN_X" is used,
# where X is the upper-case form of $binName with any '-' characters
# replaced with '_'.
proc proj-bin-define {binName {defName {}}} {
  set check [proj-find-executable-path -v $binName]
  if {"" eq $defName} {
    set defName "BIN_[string toupper [string map {- _} $binName]]"
  }
  define $defName $check
  return $check
}

########################################################################
# Usage: proj-first-bin-of bin...
#
# Looks for the first binary found of the names passed to this
# function.  If a match is found, the full path to that binary is
# returned, else "" is returned.
#
# Despite using cc-path-progs to do the search, this function clears
# any define'd name that function stores for the result (because the
# caller has no sensible way of knowing which result it was unless
# they pass only a single argument).
proc proj-first-bin-of {args} {
  set rc ""
  foreach b $args {
    set u [string toupper $b]
    # Note that cc-path-progs defines $u to false if it finds no match.
    if {[cc-path-progs $b]} {
      set rc [get-define $u]
    }
    undefine $u
    if {"" ne $rc} break
  }
  return $rc
}

########################################################################
# Returns 1 if the user specifically provided the given configure
# flag, else 0. This can be used to distinguish between options which
# have a default value and those which were explicitly provided by the
# user, even if the latter is done in a way which uses the default
# value.
#
# For example, with a configure flag defined like:
#
#   { foo-bar:=baz => {its help text} }
#
# This function will, when passed foo-bar, return 1 only if the user
# passes --foo-bar to configure, even if that invocation would resolve
# to the default value of baz. If the user does not explicitly pass in
# --foo-bar (with or without a value) then this returns 0.
proc proj-opt-was-provided {key} {
  dict exists $::autosetup(optset) $key
}

########################################################################
# Force-set autosetup option $flag to $val. The value can be fetched
# later with [opt-val], [opt-bool], and friends.
#
# Returns $val.
proc proj-opt-set {flag {val 1}} {
  global autosetup
  if {$flag ni $::autosetup(options)} {
    # We have to add this to autosetup(options) or else future calls
    # to [opt-bool $flag] will fail validation of $flag.
    lappend ::autosetup(options) $flag
  }
  dict set ::autosetup(optset) $flag $val
  return $val
}

########################################################################
# Returns 1 if $val appears to be a truthy value, else returns
# 0. Truthy values are any of {1 on enabled yes}
proc proj-val-truthy {val} {
  expr {$val in {1 on enabled yes}}
}

########################################################################
# Returns 1 if [opt-val $flag] appears to be a truthy value or
# [opt-bool $flag] is true. See proj-val-truthy.
proc proj-opt-truthy {flag} {
  if {[proj-val-truthy [opt-val $flag]]} { return 1 }
  set rc 0
  catch {
    # opt-bool will throw if $flag is not a known boolean flag
    set rc [opt-bool $flag]
  }
  return $rc
}

########################################################################
# If [proj-opt-truthy $flag] is true, eval $then, else eval $else.
proc proj-if-opt-truthy {boolFlag thenScript {elseScript {}}} {
  if {[proj-opt-truthy $boolFlag]} {
    uplevel 1 $thenScript
  } else {
    uplevel 1 $elseScript
  }
}

########################################################################
# If [proj-opt-truthy $flag] then [define $def $iftrue] else [define
# $def $iffalse]. If $msg is not empty, output [msg-checking $msg] and
# a [msg-results ...] which corresponds to the result. Returns 1 if
# the opt-truthy check passes, else 0.
proc proj-define-if-opt-truthy {flag def {msg ""} {iftrue 1} {iffalse 0}} {
  if {"" ne $msg} {
    msg-checking "$msg "
  }
  set rcMsg ""
  set rc 0
  if {[proj-opt-truthy $flag]} {
    define $def $iftrue
    set rc 1
  } else {
    define $def $iffalse
  }
  switch -- [proj-val-truthy [get-define $def]] {
    0 { set rcMsg no }
    1 { set rcMsg yes }
  }
  if {"" ne $msg} {
    msg-result $rcMsg
  }
  return $rc
}

########################################################################
# Args: [-v] optName defName {descr {}}
#
# Checks [proj-opt-truthy $optName] and calls [define $defName X]
# where X is 0 for false and 1 for true. descr is an optional
# [msg-checking] argument which defaults to $defName. Returns X.
#
# If args[0] is -v then the boolean semantics are inverted: if
# the option is set, it gets define'd to 0, else 1. Returns the
# define'd value.
proc proj-opt-define-bool {args} {
  set invert 0
  if {[lindex $args 0] eq "-v"} {
    set invert 1
    set args [lrange $args 1 end]
  }
  set optName [proj-lshift_ args]
  set defName [proj-lshift_ args]
  set descr [proj-lshift_ args]
  if {"" eq $descr} {
    set descr $defName
  }
  set rc 0
  msg-checking "$descr ... "
  if {[proj-opt-truthy $optName]} {
    if {0 eq $invert} {
      set rc 1
    } else {
      set rc 0
    }
  } elseif {0 ne $invert} {
    set rc 1
  }
  msg-result $rc
  define $defName $rc
  return $rc
}

########################################################################
# Check for module-loading APIs (libdl/libltdl)...
#
# Looks for libltdl or dlopen(), the latter either in -ldl or built in
# to libc (as it is on some platforms). Returns 1 if found, else
# 0. Either way, it `define`'s:
#
#  - HAVE_LIBLTDL to 1 or 0 if libltdl is found/not found
#  - HAVE_LIBDL to 1 or 0 if dlopen() is found/not found
#  - LDFLAGS_MODULE_LOADER one of ("-lltdl", "-ldl", or ""), noting
#    that -ldl may legally be empty on some platforms even if
#    HAVE_LIBDL is true (indicating that dlopen() is available without
#    extra link flags). LDFLAGS_MODULE_LOADER also gets "-rdynamic" appended
#    to it because otherwise trying to open DLLs will result in undefined
#    symbol errors.
#
# Note that if it finds LIBLTDL it does not look for LIBDL, so will
# report only that is has LIBLTDL.
proc proj-check-module-loader {} {
  msg-checking "Looking for module-loader APIs... "
  if {99 ne [get-define LDFLAGS_MODULE_LOADER 99]} {
    if {1 eq [get-define HAVE_LIBLTDL 0]} {
      msg-result "(cached) libltdl"
      return 1
    } elseif {1 eq [get-define HAVE_LIBDL 0]} {
      msg-result "(cached) libdl"
      return 1
    }
    # else: wha???
  }
  set HAVE_LIBLTDL 0
  set HAVE_LIBDL 0
  set LDFLAGS_MODULE_LOADER ""
  set rc 0
  puts "" ;# cosmetic kludge for cc-check-XXX
  if {[cc-check-includes ltdl.h] && [cc-check-function-in-lib lt_dlopen ltdl]} {
    set HAVE_LIBLTDL 1
    set LDFLAGS_MODULE_LOADER "-lltdl -rdynamic"
    msg-result " - Got libltdl."
    set rc 1
  } elseif {[cc-with {-includes dlfcn.h} {
    cctest -link 1 -declare "extern char* dlerror(void);" -code "dlerror();"}]} {
    msg-result " - This system can use dlopen() without -ldl."
    set HAVE_LIBDL 1
    set LDFLAGS_MODULE_LOADER ""
    set rc 1
  } elseif {[cc-check-includes dlfcn.h]} {
    set HAVE_LIBDL 1
    set rc 1
    if {[cc-check-function-in-lib dlopen dl]} {
      msg-result " - dlopen() needs libdl."
      set LDFLAGS_MODULE_LOADER "-ldl -rdynamic"
    } else {
      msg-result " - dlopen() not found in libdl. Assuming dlopen() is built-in."
      set LDFLAGS_MODULE_LOADER "-rdynamic"
    }
  }
  define HAVE_LIBLTDL $HAVE_LIBLTDL
  define HAVE_LIBDL $HAVE_LIBDL
  define LDFLAGS_MODULE_LOADER $LDFLAGS_MODULE_LOADER
  return $rc
}

########################################################################
# Sets all flags which would be set by proj-check-module-loader to
# empty/falsy values, as if those checks had failed to find a module
# loader. Intended to be called in place of that function when
# a module loader is explicitly not desired.
proc proj-no-check-module-loader {} {
  define HAVE_LIBDL 0
  define HAVE_LIBLTDL 0
  define LDFLAGS_MODULE_LOADER ""
}

########################################################################
# Opens the given file, reads all of its content, and returns it.
proc proj-file-content {fname} {
  set fp [open $fname r]
  set rc [read $fp]
  close $fp
  return $rc
}

########################################################################
# Returns the contents of the given file as an array of lines, with
# the EOL stripped from each input line.
proc proj-file-content-list {fname} {
  set fp [open $fname r]
  set rc {}
  while { [gets $fp line] >= 0 } {
    lappend rc $line
  }
  return $rc
}

########################################################################
# Checks the compiler for compile_commands.json support. If passed an
# argument it is assumed to be the name of an autosetup boolean config
# which controls whether to run/skip this check.
#
# Returns 1 if supported, else 0. Defines MAKE_COMPILATION_DB to "yes"
# if supported, "no" if not.
#
# This test has a long history of false positive results because of
# compilers reacting differently to the -MJ flag.
proc proj-check-compile-commands {{configOpt {}}} {
  msg-checking "compile_commands.json support... "
  if {"" ne $configOpt && ![proj-opt-truthy $configOpt]} {
    msg-result "explicitly disabled"
    define MAKE_COMPILATION_DB no
    return 0
  } else {
    if {[cctest -lang c -cflags {/dev/null -MJ} -source {}]} {
      # This test reportedly incorrectly succeeds on one of
      # Martin G.'s older systems. drh also reports a false
      # positive on an unspecified older Mac system.
      msg-result "compiler supports compile_commands.json"
      define MAKE_COMPILATION_DB yes
      return 1
    } else {
      msg-result "compiler does not support compile_commands.json"
      define MAKE_COMPILATION_DB no
      return 0
    }
  }
}

########################################################################
# Runs the 'touch' command on one or more files, ignoring any errors.
proc proj-touch {filename} {
  catch { exec touch {*}$filename }
}

########################################################################
# Usage:
#
#   proj-make-from-dot-in ?-touch? filename(s)...
#
# Uses [make-template] to create makefile(-like) file(s) $filename
# from $filename.in but explicitly makes the output read-only, to
# avoid inadvertent editing (who, me?).
#
# If the first argument is -touch then the generated file is touched
# to update its timestamp. This can be used as a workaround for
# cases where (A) autosetup does not update the file because it was
# not really modified and (B) the file *really* needs to be updated to
# please the build process.
#
# Failures when running chmod or touch are silently ignored.
proc proj-make-from-dot-in {args} {
  set filename $args
  set touch 0
  if {[lindex $args 0] eq "-touch"} {
    set touch 1
    set filename [lrange $args 1 end]
  }
  foreach f $filename {
    set f [string trim $f]
    catch { exec chmod u+w $f }
    make-template $f.in $f
    if {$touch} {
      proj-touch $f
    }
    catch { exec chmod -w $f }
  }
}

########################################################################
# Checks for the boolean configure option named by $flagname. If set,
# it checks if $CC seems to refer to gcc. If it does (or appears to)
# then it defines CC_PROFILE_FLAG to "-pg" and returns 1, else it
# defines CC_PROFILE_FLAG to "" and returns 0.
#
# Note that the resulting flag must be added to both CFLAGS and
# LDFLAGS in order for binaries to be able to generate "gmon.out".  In
# order to avoid potential problems with escaping, space-containing
# tokens, and interfering with autosetup's use of these vars, this
# routine does not directly modify CFLAGS or LDFLAGS.
proc proj-check-profile-flag {{flagname profile}} {
  #puts "flagname=$flagname ?[proj-opt-truthy $flagname]?"
  if {[proj-opt-truthy $flagname]} {
    set CC [get-define CC]
    regsub {.*ccache *} $CC "" CC
    # ^^^ if CC="ccache gcc" then [exec] treats "ccache gcc" as a
    # single binary name and fails. So strip any leading ccache part
    # for this purpose.
    if { ![catch { exec $CC --version } msg]} {
      if {[string first gcc $CC] != -1} {
        define CC_PROFILE_FLAG "-pg"
        return 1
      }
    }
  }
  define CC_PROFILE_FLAG ""
  return 0
}

########################################################################
# Returns 1 if this appears to be a Windows environment (MinGw,
# Cygwin, MSys), else returns 0. The optional argument is the name of
# an autosetup define which contains platform name info, defaulting to
# "host" (meaning, somewhat counterintuitively, the target system, not
# the current host). The other legal value is "build" (the build
# machine, i.e. the local host). If $key == "build" then some
# additional checks may be performed which are not applicable when
# $key == "host".
proc proj-looks-like-windows {{key host}} {
  global autosetup
  switch -glob -- [get-define $key] {
    *-*-ming* - *-*-cygwin - *-*-msys {
      return 1
    }
  }
  if {$key eq "build"} {
    # These apply only to the local OS, not a cross-compilation target,
    # as the above check potentially can.
    if {$::autosetup(iswin)} { return 1 }
    if {[find-an-executable cygpath] ne "" || $::tcl_platform(os)=="Windows NT"} {
      return 1
    }
  }
  return 0
}

########################################################################
# Looks at either the 'host' (==compilation target platform) or
# 'build' (==the being-built-on platform) define value and returns if
# if that value seems to indicate that it represents a Mac platform,
# else returns 0.
#
# TODO: have someone verify whether this is correct for the
# non-Linux/BSD platforms.
proc proj-looks-like-mac {{key host}} {
  switch -glob -- [get-define $key] {
    *apple* {
      return 1
    }
    default {
      return 0
    }
  }
}

########################################################################
# Checks autosetup's "host" and "build" defines to see if the build
# host and target are Windows-esque (Cygwin, MinGW, MSys). If the
# build environment is then BUILD_EXEEXT is [define]'d to ".exe", else
# "". If the target, a.k.a. "host", is then TARGET_EXEEXT is
# [define]'d to ".exe", else "".
proc proj-exe-extension {} {
  set rH ""
  set rB ""
  if {[proj-looks-like-windows host]} {
    set rH ".exe"
  }
  if {[proj-looks-like-windows build]} {
    set rB ".exe"
  }
  define BUILD_EXEEXT $rB
  define TARGET_EXEEXT $rH
}

########################################################################
# Works like proj-exe-extension except that it defines BUILD_DLLEXT
# and TARGET_DLLEXT to one of (.so, ,dll, .dylib).
#
# Trivia: for .dylib files, the linker needs the -dynamiclib flag
# instead of -shared.
#
# TODO: have someone verify whether this is correct for the
# non-Linux/BSD platforms.
proc proj-dll-extension {} {
  proc inner {key} {
    switch -glob -- [get-define $key] {
      *apple* {
        return ".dylib"
      }
      *-*-ming* - *-*-cygwin - *-*-msys {
        return ".dll"
      }
      default {
        return ".so"
      }
    }
  }
  define BUILD_DLLEXT [inner build]
  define TARGET_DLLEXT [inner host]
}

########################################################################
# Static-library counterpart of proj-dll-extension. Defines
# BUILD_LIBEXT and TARGET_LIBEXT to the conventional static library
# extension for the being-built-on resp. the target platform.
proc proj-lib-extension {} {
  proc inner {key} {
    switch -glob -- [get-define $key] {
      *-*-ming* - *-*-cygwin - *-*-msys {
        return ".lib"
      }
      default {
        return ".a"
      }
    }
  }
  define BUILD_LIBEXT [inner build]
  define TARGET_LIBEXT [inner host]
}

########################################################################
# Calls all of the proj-*-extension functions.
proc proj-file-extensions {} {
  proj-exe-extension
  proj-dll-extension
  proj-lib-extension
}

########################################################################
# Expects a list of file names. If any one of them does not exist in
# the filesystem, it fails fatally with an informative message.
# Returns the last file name it checks. If the first argument is -v
# then it emits msg-checking/msg-result messages for each file.
proc proj-affirm-files-exist {args} {
  set rc ""
  set verbose 0
  if {[lindex $args 0] eq "-v"} {
    set verbose 1
    set args [lrange $args 1 end]
  }
  foreach f $args {
    if {$verbose} { msg-checking "Looking for $f ... " }
    if {![file exists $f]} {
      user-error "not found: $f"
    }
    if {$verbose} { msg-result "" }
    set rc $f
  }
  return rc
}

########################################################################
# Emscripten is used for doing in-tree builds of web-based WASM stuff,
# as opposed to WASI-based WASM or WASM binaries we import from other
# places. This is only set up for Unix-style OSes and is untested
# anywhere but Linux.
#
# Defines the following:
#
# - EMSDK_HOME = top dir of the emsdk or "". It looks for
#   --with-emsdk=DIR or the $EMSDK environment variable.
# - EMSDK_ENV = path to EMSDK_HOME/emsdk_env.sh or ""
# - BIN_EMCC = $EMSDK_HOME/upstream/emscripten/emcc or ""
# - HAVE_EMSDK = 0 or 1 (this function's return value)
#
# Returns 1 if EMSDK_ENV is found, else 0.  If EMSDK_HOME is not empty
# but BIN_EMCC is then emcc was not found in the EMSDK_HOME, in which
# case we have to rely on the fact that sourcing $EMSDK_ENV from a
# shell will add emcc to the $PATH.
proc proj-check-emsdk {} {
  set emsdkHome [opt-val with-emsdk]
  define EMSDK_HOME ""
  define EMSDK_ENV ""
  define BIN_EMCC ""
  msg-checking "Emscripten SDK? "
  if {$emsdkHome eq ""} {
    # Fall back to checking the environment. $EMSDK gets set by
    # sourcing emsdk_env.sh.
    set emsdkHome [get-env EMSDK ""]
  }
  set rc 0
  if {$emsdkHome ne ""} {
    define EMSDK_HOME $emsdkHome
    set emsdkEnv "$emsdkHome/emsdk_env.sh"
    if {[file exists $emsdkEnv]} {
      msg-result "$emsdkHome"
      define EMSDK_ENV $emsdkEnv
      set rc 1
      set emcc "$emsdkHome/upstream/emscripten/emcc"
      if {[file exists $emcc]} {
        define BIN_EMCC $emcc
      }
    } else {
      msg-result "emsdk_env.sh not found in $emsdkHome"
    }
  } else {
    msg-result "not found"
  }
  define HAVE_EMSDK $rc
  return $rc
}

########################################################################
# Tries various approaches to handling the -rpath link-time
# flag. Defines LDFLAGS_RPATH to that/those flag(s) or an empty
# string. Returns 1 if it finds an option, else 0.
#
# Achtung: we have seen platforms which report that a given option
# checked here will work but then fails at build-time, and the current
# order of checks reflects that.
proc proj-check-rpath {} {
  set rc 1
  set lp "[get-define prefix]/lib"
  # If we _don't_ use cc-with {} here (to avoid updating the global
  # CFLAGS or LIBS or whatever it is that cc-check-flags updates) then
  # downstream tests may fail because the resulting rpath gets
  # implicitly injected into them.
  cc-with {} {
    if {[cc-check-flags "-rpath $lp"]} {
      define LDFLAGS_RPATH "-rpath $lp"
    } elseif {[cc-check-flags "-Wl,-rpath,$lp"]} {
      define LDFLAGS_RPATH "-Wl,-rpath,$lp"
    } elseif {[cc-check-flags "-Wl,-rpath -Wl,$lp"]} {
      define LDFLAGS_RPATH "-Wl,-rpath -Wl,$lp"
    } elseif {[cc-check-flags -Wl,-R$lp]} {
      define LDFLAGS_RPATH "-Wl,-R$lp"
    } else {
      define LDFLAGS_RPATH ""
      set rc 0
    }
  }
  return $rc
}

########################################################################
# Internal helper for proj-dump-defs-json. Expects to be passed a
# [define] name and the variadic $args which are passed to
# proj-dump-defs-json. If it finds a pattern match for the given
# $name in the various $args, it returns the type flag for that $name,
# e.g. "-str" or "-bare", else returns an empty string.
proc proj-defs-type_ {name spec} {
  foreach {type patterns} $spec {
    foreach pattern $patterns {
      if {[string match $pattern $name]} {
        return $type
      }
    }
  }
  return ""
}

########################################################################
# Internal helper for proj-defs-format_: returns a JSON-ish quoted
# form of the given (JSON) string-type values.
proc proj-quote-str_ {value} {
  return \"[string map [list \\ \\\\ \" \\\"] $value]\"
}

########################################################################
# An internal impl detail of proj-dump-defs-json. Requires a data
# type specifier, as used by make-config-header, and a value. Returns
# the formatted value or the value $::proj_(defs-skip) if the caller
# should skip emitting that value.
set proj_(defs-skip) "-proj-defs-format_ sentinel"
proc proj-defs-format_ {type value} {
  switch -exact -- $type {
    -bare {
      # Just output the value unchanged
    }
    -none {
      set value $::proj_(defs-skip)
    }
    -str {
      set value [proj-quote-str_ $value]
    }
    -auto {
      # Automatically determine the type
      if {![string is integer -strict $value]} {
        set value [proj-quote-str_ $value]
      }
    }
    -array {
      set ar {}
      foreach v $value {
        set v [proj-defs-format_ -auto $v]
        if {$::proj_(defs-skip) ne $v} {
          lappend ar $v
        }
      }
      set value "\[ [join $ar {, }] \]"
    }
    "" {
      set value $::proj_(defs-skip)
    }
    default {
      proj-fatal "Unknown type in proj-dump-defs-json: $type"
    }
  }
  return $value
}

########################################################################
# This function works almost identically to autosetup's
# make-config-header but emits its output in JSON form. It is not a
# fully-functional JSON emitter, and will emit broken JSON for
# complicated outputs, but should be sufficient for purposes of
# emitting most configure vars (numbers and simple strings).
#
# In addition to the formatting flags supported by make-config-header,
# it also supports:
#
#  -array {patterns...}
#
# Any defines matching the given patterns will be treated as a list of
# values, each of which will be formatted as if it were in an -auto {...}
# set, and the define will be emitted to JSON in the form:
#
#  "ITS_NAME": [ "value1", ...valueN ]
#
# Achtung: if a given -array pattern contains values which themselves
# contains spaces...
#
#   define-append foo {"-DFOO=bar baz" -DBAR="baz barre"}
#
# will lead to:
#
#  ["-DFOO=bar baz", "-DBAR=\"baz", "barre\""]
#
# Neither is especially satisfactory (and the second is useless), and
# handling of such values is subject to change if any such values ever
# _really_ need to be processed by our source trees.
proc proj-dump-defs-json {file args} {
  file mkdir [file dirname $file]
  set lines {}
  lappend args -bare {SIZEOF_* HAVE_DECL_*} -auto HAVE_*
  foreach n [lsort [dict keys [all-defines]]] {
    set type [proj-defs-type_ $n $args]
    set value [proj-defs-format_ $type [get-define $n]]
    if {$::proj_(defs-skip) ne $value} {
      lappend lines "\"$n\": ${value}"
    }
  }
  set buf {}
  lappend buf [join $lines ",\n"]
  write-if-changed $file $buf {
    msg-result "Created $file"
  }
}

########################################################################
# Expects a list of pairs of configure flags with the given names to
# have been registered with autosetup, in this form:
#
#  { alias1 => canonical1
#    aliasN => canonicalN ... }
#
# The names must not have their leading -- part and must be in the
# form which autosetup will expect for passing to [opt-val NAME] and
# friends.
#
# Commend lines are permitted in the input.
#
# If [opt-val $hidden] has a value but [opt-val
# $canonical] does not, it copies the former over the latter. If
# $hidden has no value set, this is a no-op. If both have explicit
# values a fatal usage error is triggered.
#
# Motivation: autosetup enables "hidden aliases" in [options] lists,
# and elides the aliases from --help output but does no further
# handling of them. For example, when --alias is a hidden alias of
# --canonical and a user passes --alias=X, [opt-val canonical] returns
# no value. i.e. the script must check both [opt-val alias] and
# [opt-val canonical].  The intent here is that this function be
# passed such mappings immediately after [options] is called,
# to carry over any values from hidden aliases into their canonical
# names, so that in the above example [opt-value canonical] will
# return X if --alias=X is passed in.
proc proj-xfer-options-aliases {mapping} {
  foreach {hidden - canonical} [proj-strip-hash-comments_ $mapping] {
    if {[proj-opt-was-provided $hidden]} {
      if {[proj-opt-was-provided $canonical]} {
        proj-fatal "both --$canonical and its alias --$hidden were used. Use only one or the other."
      } else {
        proj-opt-set $canonical [opt-val $hidden]
      }
    }
  }
}

########################################################################
# Arguable/debatable...
#
# When _not_ cross-compiling and CC_FOR_BUILD is _not_ explcitely
# specified, force CC_FOR_BUILD to be the same as CC, so that:
#
# ./configure CC=clang
#
# will use CC_FOR_BUILD=clang, instead of cc, for building in-tree
# tools. This is based off of an email discussion and is thought to
# be likely to cause less confusion than seeing 'cc' invocations
# will when the user passes CC=clang.
#
# Sidebar: if we do this before the cc package is installed, it gets
# reverted by that package. Ergo, the cc package init will tell the
# user "Build C compiler...cc" shortly before we tell them:
proc proj-redefine-cc-for-build {} {
  if {![proj-is-cross-compiling]
     && "nope" eq [get-env CC_FOR_BUILD "nope"]
     && [get-define CC] ne [get-define CC_FOR_BUILD]} {
    user-notice "Re-defining CC_FOR_BUILD to CC=[get-define CC]. To avoid this, explicitly pass CC_FOR_BUILD=..."
    define CC_FOR_BUILD [get-define CC]
  }
}
