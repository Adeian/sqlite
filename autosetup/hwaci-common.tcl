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
# Routines with a suffix of - are intended for internal use,
# within this file, and are not part of the API which auto.def files
# should rely on.
#
# This file was initially derived from one used in the libfossil
# project, authored by the same person who ported it here, noted here
# only as an indication that there are no licensing issue despite this
# code having at least two near-twins running around in other trees.
########################################################################

array set hwaci-cache- {} ; # used for caching various results.

proc hwaci-warn {msg} {
  puts "WARNING: $msg"
}
proc hwaci-notice {msg} {
  puts "NOTICE: $msg"
}
proc hwaci-error {msg} {
  user-error "ERROR: $msg"
}

########################################################################
# hwaci-lshift- shifts $count elements from the list named $listVar and
# returns them.
#
# Modified slightly from: https://wiki.tcl-lang.org/page/lshift
#
# On an empty list, returns "".
proc hwaci-lshift- {listVar {count 1}} {
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
# A proxy for cc-check-function-in-lib which "undoes" any changes that
# routine makes to the LIBS define. Returns the result of
# cc-check-function-in-lib.
proc hwaci-check-function-in-lib {function libs {otherlibs {}}} {
  set found 0
  define-push {LIBS} {
    set found [cc-check-function-in-lib $function $libs $otherlibs]
  }
  return $found
}

########################################################################
# Looks for binary named $binName and `define`s $defName to that full
# path, or an empty string if not found. Returns the value it defines.
# This caches the result for a given $binName/$defName combination, so
# calls after the first for a given combination will always return the
# same result.
#
# If defName is empty then "BIN_X" is used, where X is the upper-case
# form of $binName with any '-' characters replaced with '_'.
proc hwaci-bin-define {binName {defName {}}} {
  global hwaci-cache-
  set cacheName "$binName:$defName"
  set check {}
  if {[info exists hwaci-cache-($cacheName)]} {
    set check $hwaci-cache-($cacheName)
  }
  msg-checking "Looking for $binName ... "
  if {"" ne $check} {
    set lbl $check
    if {" _ 0 _ " eq $check} {
      set lbl "not found"
      set check ""
    }
    msg-result "(cached) $lbl"
    return $check
  }
  set check [find-executable-path $binName]
  if {"" eq $check} {
    msg-result "not found"
    set hwaci-cache-($cacheName) " _ 0 _ "
  } else {
    msg-result $check
    set hwaci-cache-($cacheName) $check
  }
  if {"" eq $defName} {
    set defName "BIN_[string toupper [string map {- _} $binName]]"
  }
  define $defName $check
  return $check
}

########################################################################
# Each argument is passed to cc-path-progs. If that function returns
# true, the full path to that binary is returned. If no matches are
# found, "" is returned.
proc hwaci-first-bin-of {args} {
  foreach b $args {
    if {[cc-path-progs $b]} {
      return [get-define [string toupper $b]]
    }
  }
  return ""
}

########################################################################
# Looks for `bash` binary and dies if not found. On success, defines
# BIN_BASH to the full path to bash and returns that value. We
# _require_ bash because it's the SHELL value used in our makefiles.
proc hwaci-require-bash {} {
  set bash [hwaci-bin-define bash]
  if {"" eq $bash} {
    user-error "Our Makefiles require the bash shell."
  }
  return $bash
}

########################################################################
# Force-set autosetup option $flag to $val. The value can be fetched
# later with [opt-val], [opt-bool], and friends.
proc hwaci-opt-set {flag {val 1}} {
  global autosetup
  if {$flag ni $::autosetup(options)} {
    # We have to add this to autosetup(options) or else future calls
    # to [opt-bool $flag] will fail validation of $flag.
    lappend ::autosetup(options) $flag
  }
  dict set ::autosetup(optset) $flag $val
}

########################################################################
# Returns 1 if $val appears to be a truthy value, else returns
# 0. Truthy values are any of {1 on enabled yes}
proc hwaci-val-truthy {val} {
  expr {$val in {1 on enabled yes}}
}

########################################################################
# Returns 1 if [opt-val $flag] appears to be a truthy value or
# [opt-bool $flag] is true. See hwaci-val-truthy.
proc hwaci-opt-truthy {flag} {
  if {[hwaci-val-truthy [opt-val $flag]]} { return 1 }
  set rc 0
  catch {
    # opt-bool will throw if $flag is not a known boolean flag
    set rc [opt-bool $flag]
  }
  return $rc
}

########################################################################
# If [hwaci-opt-truthy $flag] is true, eval $then, else eval $else.
proc hwaci-if-opt-truthy {boolFlag thenScript {elseScript {}}} {
  if {[hwaci-opt-truthy $boolFlag]} {
    uplevel 1 $thenScript
  } else {
    uplevel 1 $elseScript
  }
}

########################################################################
# If [hwaci-opt-truthy $flag] then [define $def $iftrue] else [define
# $def $iffalse]. If $msg is not empty, output [msg-checking $msg] and
# a [msg-results ...] which corresponds to the result. Returns 1 if
# the opt-truthy check passes, else 0.
proc hwaci-define-if-opt-truthy {flag def {msg ""} {iftrue 1} {iffalse 0}} {
  if {"" ne $msg} {
    msg-checking "$msg "
  }
  set rcMsg ""
  set rc 0
  if {[hwaci-opt-truthy $flag]} {
    define $def $iftrue
    set rc 1
  } else {
    define $def $iffalse
  }
  switch -- [hwaci-val-truthy [get-define $def]] {
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
# Checks [hwaci-opt-truthy $optName] and calls [define $defName X]
# where X is 0 for false and 1 for true. descr is an optional
# [msg-checking] argument which defaults to $defName. Returns X.
#
# If args[0] is -v then the boolean semantics are inverted: if
# the option is set, it gets define'd to 0, else 1. Returns the
# define'd value.
proc hwaci-opt-define-bool {args} {
  set invert 0
  if {[lindex $args 0] eq "-v"} {
    set invert 1
    set args [lrange $args 1 end]
  }
  set optName [hwaci-lshift- args]
  set defName [hwaci-lshift- args]
  set descr [hwaci-lshift- args]
  if {"" eq $descr} {
    set descr $defName
  }
  set rc 0
  msg-checking "$descr ... "
  if {[hwaci-opt-truthy $optName]} {
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
proc hwaci-check-module-loader {} {
  msg-checking "Looking for module-loader APIs... "
  if {99 ne [get-define LDFLAGS_MODULE_LOADER]} {
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
    puts " - Got libltdl."
    set rc 1
  } elseif {[cc-with {-includes dlfcn.h} {
    cctest -link 1 -declare "extern char* dlerror(void);" -code "dlerror();"}]} {
    puts " - This system can use dlopen() without -ldl."
    set HAVE_LIBDL 1
    set LDFLAGS_MODULE_LOADER ""
    set rc 1
  } elseif {[cc-check-includes dlfcn.h]} {
    set HAVE_LIBDL 1
    set rc 1
    if {[cc-check-function-in-lib dlopen dl]} {
      puts " - dlopen() needs libdl."
      set LDFLAGS_MODULE_LOADER "-ldl -rdynamic"
    } else {
      puts " - dlopen() not found in libdl. Assuming dlopen() is built-in."
      set LDFLAGS_MODULE_LOADER "-rdynamic"
    }
  }
  define HAVE_LIBLTDL $HAVE_LIBLTDL
  define HAVE_LIBDL $HAVE_LIBDL
  define LDFLAGS_MODULE_LOADER $LDFLAGS_MODULE_LOADER
  return $rc
}

########################################################################
# Sets all flags which would be set by hwaci-check-module-loader to
# empty/falsy values, as if those checks had failed to find a module
# loader. Intended to be called in place of that function when
# a module loader is explicitly not desired.
proc hwaci-no-check-module-loader {} {
  define HAVE_LIBDL 0
  define HAVE_LIBLTDL 0
  define LDFLAGS_MODULE_LOADER ""
}

########################################################################
# Opens the given file, reads all of its content, and returns it.
proc hwaci-file-content {fname} {
  set fp [open $fname r]
  set rc [read $fp]
  close $fp
  return $rc
}

########################################################################
# Returns the contents of the given file as an array of lines, with
# the EOL stripped from each input line.
proc hwaci-file-content-list {fname} {
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
proc hwaci-check-compile-commands {{configOpt {}}} {
  msg-checking "compile_commands.json support... "
  if {"" ne $configOpt && ![hwaci-opt-truthy $configOpt]} {
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
# Uses [make-template] to create makefile(-like) file $filename from
# $filename.in but explicitly makes the output read-only, to avoid
# inadvertent editing (who, me?).
#
# The second argument is an optional boolean specifying whether to
# `touch` the generated files. This can be used as a workaround for
# cases where (A) autosetup does not update the file because it was
# not really modified and (B) the file *really* needs to be updated to
# please the build process. Pass any non-0 value to enable touching.
#
# The argument may be a list of filenames.
#
# Failures when running chmod or touch are silently ignored.
proc hwaci-make-from-dot-in {filename {touch 0}} {
  foreach f $filename {
    catch { exec chmod u+w $f }
    make-template $f.in $f
    if {0 != $touch} {
      puts "Touching $f"
      catch { exec touch $f }
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
proc hwaci-check-profile-flag {{flagname profile}} {
  #puts "flagname=$flagname ?[hwaci-opt-truthy $flagname]?"
  if {[hwaci-opt-truthy $flagname]} {
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
proc hwaci-looks-like-windows {{key host}} {
  global autosetup
  switch -glob -- [get-define $key] {
    *-*-ming* - *-*-cygwin - *-*-msys {
      return 1
    }
  }
  if {$key eq "build"} {
    # These apply only to the local OS, not a cross-compilation target,
    # as the above check can potentially.
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
proc hwaci-looks-like-mac {{key host}} {
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
proc hwaci-exe-extension {} {
  set rH ""
  set rB ""
  if {[hwaci-looks-like-windows host]} {
    set rH ".exe"
  }
  if {[hwaci-looks-like-windows build]} {
    set rB ".exe"
  }
  define BUILD_EXEEXT $rH
  define TARGET_EXEEXT $rB
}

########################################################################
# Works like hwaci-exe-extension except that it defines BUILD_DLLEXT
# and TARGET_DLLEXT to one of (.so, ,dll, .dylib).
#
# TODO: have someone verify whether this is correct for the
# non-Linux/BSD platforms.
proc hwaci-dll-extension {} {
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
  define BUILD_DLLEXT [inner host]
  define TARGET_DLLEXT [inner build]
}

########################################################################
# Expects a list of file names. If any one of them does not exist in
# the filesystem, it fails fatally with an informative message.
# Returns the last file name it checks. If the first argument is -v
# then it emits msg-checking/msg-result messages for each file.
proc hwaci-affirm-files-exist {args} {
  set rc ""
  set verbose 1
  if {[lindex $args 0] eq "-v"} {
    set verbose 1
    set args [lrange $args 1 end]
  }
  foreach f $args {
    if {$verbose} { msg-checking "looking for file... " }
    if {![file exists $f]} {
      user-error "not found: $f"
    }
    if {$verbose} { msg-result "$f" }
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
#
# Returns 1 if EMSDK_ENV is found, else 0.  If EMSDK_HOME is not empty
# but BIN_EMCC is then emcc was not found in the EMSDK_HOME, in which
# case we have to rely on the fact that sourcing $EMSDK_ENV from a
# shell will add emcc to the $PATH.
proc hwaci-check-emsdk {} {
  set emsdkHome [opt-val with-emsdk]
  define EMSDK_HOME ""
  define EMSDK_ENV ""
  define BIN_EMCC ""
  #  define EMCC_OPT "-Oz"
  msg-checking "Emscripten SDK? "
  if {$emsdkHome eq "" && [info exists ::env(EMSDK)]} {
    # Fall back to checking the environment. $EMSDK gets set
    # by sourcing emsdk_env.sh.
    set emsdkHome $::env(EMSDK)
  }
  set rc 0
  if {$emsdkHome ne ""} {
    define EMSDK_HOME $emsdkHome
    set emsdkEnv "$emsdkHome/emsdk_env.sh"
    if {[file exists $emsdkEnv]} {
      msg-result "$emsdkHome"
      define EMSDK_ENV $emsdkEnv
#      if {[info exists ::env(EMCC_OPT)]} {
#        define EMCC_OPT $::env(EMCC_OPT)
#      }
      set rc 1
      set emcc "$emsdkHome/upstream/emscripten/emcc"
      if {[file exists $emcc]} {
        # puts "is emcc == $emcc ???"
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
proc hwaci-check-rpath {} {
  set rc 1
  cc-with {} {
    if {[cc-check-flags {-rpath /tmp}]} {
      define LDFLAGS_RPATH "-rpath [get-define prefix]/lib"
    } elseif {[cc-check-flags {-Wl,-rpath -Wl,/tmp}]} {
      define LDFLAGS_RPATH "-Wl,-rpath -Wl,[get-define prefix]/lib"
    } elseif {[cc-check-flags -Wl,-R/tmp]} {
      define LDFLAGS_RPATH "-Wl,-R[get-define prefix]/lib"
    } else {
      define LDFLAGS_RPATH ""
      set rc 0
    }
  }
  return $rc
}

########################################################################
# Under construction - check for libreadline functionality
proc hwaci-check-readline {} {
  define HAVE_READLINE 0
  define LDFLAGS_READLINE ""
  define CFLAGS_READLINE ""
  define READLINE_H ""
  if {![opt-bool readline]} {
    msg-result "libreadline disabled via --disable-readline."
    return 0
  }
  set h "readline/readline.h"
  if {[cc-check-includes $h]} {
    define READLINE_H $h
    if {[hwaci-check-function-in-lib readline readline]} {
      msg-result "Enabling libreadline."
      define HAVE_READLINE 1
      define LDFLAGS_READLINE [get-define lib_readline]
      undefine lib_readline
      return 1
    }
    # else TODO: look in various places and [define CFLAGS_READLINE
    # -I...]
  }
  # Numerous TODOs:
  # - Requires linking with ncurses or similar on some platforms.
  # - Headers are in a weird place on some BSD systems.
  # - Add --with-readline=DIR
  # - Add --with-readline-lib=lib file
  # - Add --with-readline-inc=dir -Idir
  msg-result "libreadline not found."
  return 0
}
