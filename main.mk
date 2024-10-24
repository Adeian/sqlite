#!/do/not/make
# ^^^^ help out editors which guess this file's type.
###############################################################################
# This is the main makefile for sqlite. It expects to be included from
# a higher-level makefile which configures any dynamic state needed by
# this one (as documented below).
#
# Maintenance reminders:
#
#  - This file must remain devoid of GNU Make-isms.  i.e. it must be
#  POSIX Make compatible. "bmake" (BSD make) is available on most
#  Linux systems, so compatibility is relatively easy to test.
#
# The variables listed below must be defined before this script is
# invoked. This file will use defaults, very possibly invalid, for any
# which are not defined.
########################################################################
#
# $(TOP) =
#
# The toplevel directory of the source tree.  For canonical builds
# this is the directory that contains this "Makefile.in" and the
# "configure.in" script. For out-of-tree builds, this will differ
# from $(PWD).
#
TOP ?= $(PWD)
#
# $(VERSION.XYZ) =
#
# The MAJOR.MINOR.PATCH version number of this build.
#
VERSION.XYZ ?=
#
# $(B.cc) =
#
# C Compiler and options for use in building executables that will run
# on the platform that is doing the build.
#
B.cc ?= $(CC)
#
# $(T.cc) =
#
# C Compiler and options for use in building executables that will run
# on the target platform.  This is usually the same as B.cc, unless you
# are cross-compiling. Note that it should only contain flags which
# are used by _all_ build targets.  Flags needed only by specific
# targets are defined elsewhere and applied on a per-target basis.
#
T.cc ?= $(B.cc)
#
# $(AR) =
# Tool used to build a static library from object files.
#
AR      ?= ar
#
# $(B.exe) =
#
# File extension for executables on the build platform. ".exe" for
# Windows and "" everywhere else.
#
B.exe ?=
#
# $(B.dll) and $(B.lib) =
#
# The DLL resp. static library counterparts of $(B.exe).
#
B.dll ?= .so
B.lib ?= .lib
#
# $(T.exe) =
#
# File extension for executables on the target platform. ".exe" for
# Windows and "" everywhere else.
#
T.exe ?=
#
# $(T.dll) and $(T.lib) =
#
# The DLL resp. static library counterparts of $(T.exe).
#
T.dll ?= .so
T.lib ?= .lib
#
# $(TCLSH_CMD) =
#
# The canonical tclsh.
#
TCLSH_CMD ?= tclsh
#
# JimTCL is part of the autosetup suite and is suitable for all
# current in-tree code-generation TCL jobs, but it requires that we
# build it with non-default flags. Note that the build tree will, if
# no system-level tclsh is found, also have a ./jimsh0 binary. That
# one is a bare-bones build for the configure process, whereas we need
# to build it with another option enabled for use with the various
# code generators.
#
# JIMSH requires a leading path component, even if it's ./, so that it
# can be used as a shell command.
#
CFLAGS.jimsh ?= -DHAVE_REALPATH
JIMSH ?= ./jimsh$(T.exe)
#
# $(B.tclsh) =
#
# The TCL interpreter for in-tree code generation. May be either the
# in-tree JimTCL ($(JIMSH)) or the canonical TCL ($(TCLSH_CMD). If
# it's JimTCL, it must be compiled with -DHAVE_REALPATH or
# -DHAVE__FULLPATH.
#
B.tclsh ?= $(JIMSH)

#
# $(LDFLAGS.{feature}) and $(CFLAGS.{feature}) =
#
# Linker resp. C/CPP flags required by a specific feature, e.g.
# $(LDFLAGS.pthread) or $(CFLAGS.readline).
#
# Rather that stuffing all CFLAGS and LDFLAGS into a single set, we
# break them down on a per-feature basis and expect the build targets
# to use the one(s) it needs.
#
LDFLAGS.zlib ?= -lz
LDFLAGS.math ?= -lm
LDFLAGS.rpath ?= -Wl,-rpath -Wl,$(prefix)/lib
LDFLAGS.readline ?= -lreadline # these vary wildly across platforms
CFLAGS.readline ?=
LDFLAGS.pthread ?= -lpthread
LDFLAGS.dlopen ?= -ldl
LDFLAGS.shobj ?= -shared
#
# Various system-level directories, mostly needed for installation and
# for finding system-level dependencies.
#
prefix       ?= /usr/local
exec_prefix  ?= $(prefix)
libdir       ?= $(prefix)/lib
pkgconfigdir ?= $(libdir)/pkgconfig
bindir       ?= $(prefix)/bin
includedir   ?= $(prefix)/include
#
# $(INSTALL) =
#
# Tool for installing files and directories. It must be compatible
# with conventional Unix /usr/bin/install. Note that libtool's
# install-sh is _not_ compatible with this because it _moves_ targets
# during installation, which may break the build of targets which are
# built after others are installed.
#
INSTALL ?= install
#
# $(ENABLE_SHARED) =
#
# 1 if libsqlite3.$(T.dll) should be built.
#
ENABLE_SHARED ?= 1
#
# $(USE_AMALGAMATION)
#
# 1 if the amalgamation (sqlite3.c/h) should be built/used, otherwise
# the library is built from all of its original source files.
#
USE_AMALGAMATION ?= 1
#
# $(AMALGAMATION_GEN_FLAGS) =
#
# Optional flags for the amalgamation generator.
#
AMALGAMATION_GEN_FLAGS ?= --linemacros=0
#
# $(OPT_FEATURE_FLAGS) =
#
# Preprocessor flags for enabling and disabling specific libsqlite3
# features (-DSQLITE_OMIT*, -DSQLITE_ENABLE*). The same set of OMIT
# and ENABLE flags must be passed to the LEMON parser generator and
# the mkkeywordhash tool as well.
#
# Add OPTIONS=... on the make command line to append additional options
# to the OPT_FEATURE_FLAGS. Note that some flags only work if the
# build is specifically configured to account for them. Adding them
# later, when compiling the amalgamation, may or may not work.
#
# TO CLARIFY: OPTS=... has historically been expected in some
# contexts, and is distinctly different from OPTIONS and
# OPT_FEATURE_FLAGS, but its name is confusingly close to $(OPTIONS).
#
OPT_FEATURE_FLAGS ?=
#
# $(SHELL_OPT) =
#
# CFLAGS specific to the sqlite3 CLI shell app and its close cousins.
#
SHELL_OPT ?=
#
# The following TCL_vars come from tclConfig.sh
#
# Potential TODO: a shell script, similar tool/tclConfigShToTcl.sh,
# which emits these vars in a format which we can include from this
# makefile.
#
TCL_INCLUDE_SPEC ?=
TCL_LIB_SPEC ?=
TCL_STUB_LIB_SPEC ?=
TCL_EXEC_PREFIX ?=
TCL_VERSION ?=
TCLLIBDIR ?=
#
# $(TCLLIB_RPATH) is the -rpath flag for libtclsqlite3, not
# libsqlite3, and will usually differ from $(LDFLAGS.rpath).
#
TCLLIB_RPATH ?=
#
# $(HAVE_WASI_SDK) =
#
# 1 when building with the WASI SDK. This disables certain build
# targets. It is expected that the invoker assigns CC to the wasi-sdk
# CC.
#
HAVE_WASI_SDK ?= 0
#
# ... and many, many more. Sane defaults are selected where possible.
#
# With the above-described defined, the rest of this make script will
# build the project's deliverables and testing tools.
################################################################################
all:	sqlite3.h sqlite3.c

########################################################################
########################################################################
# Modifying anything after this point should not be necessary for most
# builds.
########################################################################
########################################################################

#
# $(CFLAGS) should ideally only contain flags which are relevant for
# all binaries built for the target platform.
#
T.cc += $(CFLAGS)

#
# The difference between $(OPT_FEATURE_FLAGS) and $(OPTS) is that the
# former is historically provided by the configure script, whereas the
# latter is intended to be provided as arguments to the make
# invocation.
#
T.cc += $(OPT_FEATURE_FLAGS)

#
# Add in any optional global compilation flags on the make command
# line ie.  make "OPTS=-DSQLITE_ENABLE_FOO=1 -DSQLITE_OMIT_FOO=1".
#
T.cc += $(OPTS)

#
# $(INSTALL) invocation for use with non-executable files.
#
INSTALL.noexec = $(INSTALL) -m 0644
# ^^^ do not use GNU-specific flags to $(INSTALL), e.g. --mode=...

#
# $(T.compile) = generic target platform compiler invocation,
# differing only from $(T.cc) in that it appends $(T.compile.extras),
# which are primarily intended for use with gcov-related flags.
#
T.compile = $(T.cc) $(T.compile.extras)

#
# $(CFLAGS.libsqlite3) must contain any CFLAGS which are relevant for
# compiling the library's own sources, including (sometimes) when
# compiling sqlite3.c directly in to another app.
#
CFLAGS.libsqlite3 ?=
#
# $(T.cc.sqlite) is $(T.cc) plus any flags which are desired for the
# library as a whole, but not necessarily needed for every binary. It
# will normally get initially populated with flags by the
# configure-generated makefile.
#
T.cc.sqlite ?= $(T.cc)

#
# $(CFLAGS.intree_includes) = -I... flags relevant specifically to
# this tree, including any subdirectories commonly needed for building
# various tools.
#
CFLAGS.intree_includes = \
    -I. -I$(TOP)/src -I$(TOP)/ext/rtree -I$(TOP)/ext/icu \
    -I$(TOP)/ext/fts3 -I$(TOP)/ext/async -I$(TOP)/ext/session \
    -I$(TOP)/ext/misc -I$(TOP)/ext/userauth
T.cc.sqlite += $(CFLAGS.intree_includes)

#
# $(T.cc.extension) = compiler invocation for loadable extensions.
#
T.cc.extension = $(T.compile) -I. -I$(TOP)/src -DSQLITE_CORE

#
# $(T.link) = compiler invocation for when the target will be an
# executable.
#
# $(T.link.extras) = optional config-specific flags for $(T.link),
# primarily intended for use with gcov-related flags.
#
T.link = $(T.cc.sqlite) $(T.link.extras)
#
# $(T.link.shared) = $(T.link) invocation specifically for shared libraries
#
T.link.shared = $(T.link) $(LDFLAGS.shobj)

#
# LDFLAGS.libsqlite3 should be used with any target which either
# results in building libsqlite3.so, compiles sqlite3.c directly, or
# links in either of $(LIBOBJSO) or $(LIBOBJS1).  Note that these
# flags are for the target build platform, not necessarily localhost.
# i.e. it should be used with $(T.cc.sqlite) or $(T.link) but not $(B.cc).
#
LDFLAGS.libsqlite3 = \
  $(LDFLAGS.rpath) $(LDFLAGS.pthread) \
  $(LDFLAGS.math) $(LDFLAGS.zlib) \
  $(LDFLAGS.dlopen)

#
# $(install-dir.XYZ) = dirs for installation.
#
# Design note: these should arguably all be defined with surrounding
# double-quotes so that targets which have spaces in their paths will
# work, but that leads to Make treating the quotes as part of the dir
# name, which in turn leads to it never finding a matching name in the
# filesystem and always invoking ($(INSTALL) -d ...) for them. The
# moral of this story is that spaces in installation paths will break
# the install process.
#
install-dir.bin = $(DESTDIR)$(bindir)
install-dir.lib = $(DESTDIR)$(libdir)
install-dir.include = $(DESTDIR)$(prefix)/include
install-dir.pkgconfig = $(DESTDIR)$(pkgconfigdir)
install-dir.man1 = $(DESTDIR)$(prefix)/share/man/man1
install-dir.all = $(install-dir.bin) $(install-dir.include) \
  $(install-dir.lib) $(install-dir.man1) \
  $(install-dir.pkgconfig)
$(install-dir.all):
	$(INSTALL) -d $@

#
# After jimsh is compiled, we run some sanity checks to ensure that
# it was built in a way compatible with this project's scripts:
#
# 1) Ensure that it was built with realpath() or _fullpath() support.
# Without that flag the [file normalize] command will always resolve
# to an empty string.
#
# 2) Ensure that it is built with -DJIM_COMPAT (which may be
# hard-coded into jimsh0.c). Without this, the [expr] command
# accepts only a single argument.
#
$(JIMSH): $(TOP)/autosetup/jimsh0.c
	$(B.cc) -o $@ $(CFLAGS.jimsh) $(TOP)/autosetup/jimsh0.c
	@if [ x = "x$$($(JIMSH) -e 'file normalize $(JIMSH)' 2>/dev/null)" ]; then \
		echo "$(JIMSH) was built without -DHAVE_REALPATH or -DHAVE__FULLPATH." 1>&2; \
		exit 1; \
	fi
	@if [ x3 != "x$$($(JIMSH) -e 'expr 1 + 2' 2>/dev/null)" ]; then \
		echo "$(JIMSH) was built without -DJIM_COMPAT." 1>&2; \
		exit 1; \
	fi
distclean-jimsh:
	rm -f $(JIMSH)
distclean: distclean-jimsh

#
# $(MAKE_SANITY_CHECK) = a set of checks for various make vars which
# must be provided to this file before including it. If any are
# missing, this target fails. It does (almost) no semantic validation,
# only checks to see that appropriate vars are not empty.
#
# Note that $(MAKEFILE_LIST) is a GNU-make-ism but its use is harmless
# in other flavors of Make.
#
MAKE_SANITY_CHECK = .main.mk.checks
$(MAKE_SANITY_CHECK): $(MAKEFILE_LIST)
	@if [ x = "x$(TOP)" ]; then echo "Missing TOP var" 1>&2; exit 1; fi
	@if [ ! -d "$(TOP)" ]; then echo "$(TOP) is not a directory" 1>&2; exit 1; fi
	@if [ ! -f "$(TOP)/auto.def" ]; then echo "$(TOP) does not appear to be the top-most source dir" 1>&2; exit 1; fi
	@if [ x = "x$(VERSION.XYZ)" ]; then echo "VERSION.XYZ must be set to the library's X.Y.Z-format version number" 1>&2; exit 1; fi
	@if [ x = "x$(B.cc)" ]; then echo "Missing B.cc var" 1>&2; exit 1; fi
	@if [ x = "x$(T.cc)" ]; then echo "Missing T.cc var" 1>&2; exit 1; fi
	@if [ x = "x$(B.tclsh)" ]; then echo "Missing B.tclsh var" 1>&2; exit 1; fi
	@if [ x = "x$(AR)" ]; then echo "Missing AR var" 1>&2; exit 1; fi
	touch $@
clean-sanity-check:
	rm -f $(MAKE_SANITY_CHECK)
clean: clean-sanity-check

#
# Object files for the SQLite library (non-amalgamation).
#
LIBOBJS0 = alter.o analyze.o attach.o auth.o \
         backup.o bitvec.o btmutex.o btree.o build.o \
         callback.o complete.o ctime.o \
         date.o dbpage.o dbstat.o delete.o \
         expr.o fault.o fkey.o \
         fts3.o fts3_aux.o fts3_expr.o fts3_hash.o fts3_icu.o \
         fts3_porter.o fts3_snippet.o fts3_tokenizer.o fts3_tokenizer1.o \
         fts3_tokenize_vtab.o \
         fts3_unicode.o fts3_unicode2.o fts3_write.o \
         fts5.o \
         func.o global.o hash.o \
         icu.o insert.o json.o legacy.o loadext.o \
         main.o malloc.o mem0.o mem1.o mem2.o mem3.o mem5.o \
         memdb.o memjournal.o \
         mutex.o mutex_noop.o mutex_unix.o mutex_w32.o \
         notify.o opcodes.o os.o os_kv.o os_unix.o os_win.o \
         pager.o parse.o pcache.o pcache1.o pragma.o prepare.o printf.o \
         random.o resolve.o rowset.o rtree.o \
         sqlite3session.o select.o sqlite3rbu.o status.o stmt.o \
         table.o threads.o tokenize.o treeview.o trigger.o \
         update.o upsert.o userauth.o utf.o util.o vacuum.o \
         vdbe.o vdbeapi.o vdbeaux.o vdbeblob.o vdbemem.o vdbesort.o \
         vdbetrace.o vdbevtab.o vtab.o \
         wal.o walker.o where.o wherecode.o whereexpr.o \
         window.o
LIBOBJS = $(LIBOBJS0)

# Object files for the amalgamation.
#
LIBOBJS1 = sqlite3.o

# Determine the real value of LIBOBJ based on the 'configure' script
#
LIBOBJ = $(LIBOBJS$(USE_AMALGAMATION))

$(LIBOBJ): $(MAKE_SANITY_CHECK)

# All of the source code files.
#
SRC = \
  $(TOP)/src/alter.c \
  $(TOP)/src/analyze.c \
  $(TOP)/src/attach.c \
  $(TOP)/src/auth.c \
  $(TOP)/src/backup.c \
  $(TOP)/src/bitvec.c \
  $(TOP)/src/btmutex.c \
  $(TOP)/src/btree.c \
  $(TOP)/src/btree.h \
  $(TOP)/src/btreeInt.h \
  $(TOP)/src/build.c \
  $(TOP)/src/callback.c \
  $(TOP)/src/complete.c \
  $(TOP)/src/ctime.c \
  $(TOP)/src/date.c \
  $(TOP)/src/dbpage.c \
  $(TOP)/src/dbstat.c \
  $(TOP)/src/delete.c \
  $(TOP)/src/expr.c \
  $(TOP)/src/fault.c \
  $(TOP)/src/fkey.c \
  $(TOP)/src/func.c \
  $(TOP)/src/global.c \
  $(TOP)/src/hash.c \
  $(TOP)/src/hash.h \
  $(TOP)/src/hwtime.h \
  $(TOP)/src/insert.c \
  $(TOP)/src/json.c \
  $(TOP)/src/legacy.c \
  $(TOP)/src/loadext.c \
  $(TOP)/src/main.c \
  $(TOP)/src/malloc.c \
  $(TOP)/src/mem0.c \
  $(TOP)/src/mem1.c \
  $(TOP)/src/mem2.c \
  $(TOP)/src/mem3.c \
  $(TOP)/src/mem5.c \
  $(TOP)/src/memdb.c \
  $(TOP)/src/memjournal.c \
  $(TOP)/src/msvc.h \
  $(TOP)/src/mutex.c \
  $(TOP)/src/mutex.h \
  $(TOP)/src/mutex_noop.c \
  $(TOP)/src/mutex_unix.c \
  $(TOP)/src/mutex_w32.c \
  $(TOP)/src/notify.c \
  $(TOP)/src/os.c \
  $(TOP)/src/os.h \
  $(TOP)/src/os_common.h \
  $(TOP)/src/os_setup.h \
  $(TOP)/src/os_kv.c \
  $(TOP)/src/os_unix.c \
  $(TOP)/src/os_win.c \
  $(TOP)/src/os_win.h \
  $(TOP)/src/pager.c \
  $(TOP)/src/pager.h \
  $(TOP)/src/parse.y \
  $(TOP)/src/pcache.c \
  $(TOP)/src/pcache.h \
  $(TOP)/src/pcache1.c \
  $(TOP)/src/pragma.c \
  $(TOP)/src/pragma.h \
  $(TOP)/src/prepare.c \
  $(TOP)/src/printf.c \
  $(TOP)/src/random.c \
  $(TOP)/src/resolve.c \
  $(TOP)/src/rowset.c \
  $(TOP)/src/select.c \
  $(TOP)/src/status.c \
  $(TOP)/src/shell.c.in \
  $(TOP)/src/sqlite.h.in \
  $(TOP)/src/sqlite3ext.h \
  $(TOP)/src/sqliteInt.h \
  $(TOP)/src/sqliteLimit.h \
  $(TOP)/src/table.c \
  $(TOP)/src/tclsqlite.c \
  $(TOP)/src/threads.c \
  $(TOP)/src/tokenize.c \
  $(TOP)/src/treeview.c \
  $(TOP)/src/trigger.c \
  $(TOP)/src/utf.c \
  $(TOP)/src/update.c \
  $(TOP)/src/upsert.c \
  $(TOP)/src/util.c \
  $(TOP)/src/vacuum.c \
  $(TOP)/src/vdbe.c \
  $(TOP)/src/vdbe.h \
  $(TOP)/src/vdbeapi.c \
  $(TOP)/src/vdbeaux.c \
  $(TOP)/src/vdbeblob.c \
  $(TOP)/src/vdbemem.c \
  $(TOP)/src/vdbesort.c \
  $(TOP)/src/vdbetrace.c \
  $(TOP)/src/vdbevtab.c \
  $(TOP)/src/vdbeInt.h \
  $(TOP)/src/vtab.c \
  $(TOP)/src/vxworks.h \
  $(TOP)/src/wal.c \
  $(TOP)/src/wal.h \
  $(TOP)/src/walker.c \
  $(TOP)/src/where.c \
  $(TOP)/src/wherecode.c \
  $(TOP)/src/whereexpr.c \
  $(TOP)/src/whereInt.h \
  $(TOP)/src/window.c

# Source code for extensions
#
SRC += \
  $(TOP)/ext/fts3/fts3.c \
  $(TOP)/ext/fts3/fts3.h \
  $(TOP)/ext/fts3/fts3Int.h \
  $(TOP)/ext/fts3/fts3_aux.c \
  $(TOP)/ext/fts3/fts3_expr.c \
  $(TOP)/ext/fts3/fts3_hash.c \
  $(TOP)/ext/fts3/fts3_hash.h \
  $(TOP)/ext/fts3/fts3_icu.c \
  $(TOP)/ext/fts3/fts3_porter.c \
  $(TOP)/ext/fts3/fts3_snippet.c \
  $(TOP)/ext/fts3/fts3_tokenizer.h \
  $(TOP)/ext/fts3/fts3_tokenizer.c \
  $(TOP)/ext/fts3/fts3_tokenizer1.c \
  $(TOP)/ext/fts3/fts3_tokenize_vtab.c \
  $(TOP)/ext/fts3/fts3_unicode.c \
  $(TOP)/ext/fts3/fts3_unicode2.c \
  $(TOP)/ext/fts3/fts3_write.c
SRC += \
  $(TOP)/ext/icu/sqliteicu.h \
  $(TOP)/ext/icu/icu.c
SRC += \
  $(TOP)/ext/rtree/rtree.h \
  $(TOP)/ext/rtree/rtree.c \
  $(TOP)/ext/rtree/geopoly.c
SRC += \
  $(TOP)/ext/session/sqlite3session.c \
  $(TOP)/ext/session/sqlite3session.h
SRC += \
  $(TOP)/ext/userauth/userauth.c \
  $(TOP)/ext/userauth/sqlite3userauth.h
SRC += \
  $(TOP)/ext/rbu/sqlite3rbu.h \
  $(TOP)/ext/rbu/sqlite3rbu.c
SRC += \
  $(TOP)/ext/misc/stmt.c

# Generated source code files
#
SRC += \
  keywordhash.h \
  opcodes.c \
  opcodes.h \
  parse.c \
  parse.h \
  sqlite_cfg.h \
  shell.c \
  sqlite3.h

# Source code to the test files.
#
TESTSRC = \
  $(TOP)/src/test1.c \
  $(TOP)/src/test2.c \
  $(TOP)/src/test3.c \
  $(TOP)/src/test4.c \
  $(TOP)/src/test5.c \
  $(TOP)/src/test6.c \
  $(TOP)/src/test8.c \
  $(TOP)/src/test9.c \
  $(TOP)/src/test_autoext.c \
  $(TOP)/src/test_async.c \
  $(TOP)/src/test_backup.c \
  $(TOP)/src/test_bestindex.c \
  $(TOP)/src/test_blob.c \
  $(TOP)/src/test_btree.c \
  $(TOP)/src/test_config.c \
  $(TOP)/src/test_delete.c \
  $(TOP)/src/test_demovfs.c \
  $(TOP)/src/test_devsym.c \
  $(TOP)/src/test_fs.c \
  $(TOP)/src/test_func.c \
  $(TOP)/src/test_hexio.c \
  $(TOP)/src/test_init.c \
  $(TOP)/src/test_intarray.c \
  $(TOP)/src/test_journal.c \
  $(TOP)/src/test_malloc.c \
  $(TOP)/src/test_md5.c \
  $(TOP)/src/test_multiplex.c \
  $(TOP)/src/test_mutex.c \
  $(TOP)/src/test_onefile.c \
  $(TOP)/src/test_osinst.c \
  $(TOP)/src/test_pcache.c \
  $(TOP)/src/test_quota.c \
  $(TOP)/src/test_rtree.c \
  $(TOP)/src/test_schema.c \
  $(TOP)/src/test_superlock.c \
  $(TOP)/src/test_syscall.c \
  $(TOP)/src/test_tclsh.c \
  $(TOP)/src/test_tclvar.c \
  $(TOP)/src/test_thread.c \
  $(TOP)/src/test_vdbecov.c \
  $(TOP)/src/test_vfs.c \
  $(TOP)/src/test_windirent.c \
  $(TOP)/src/test_window.c \
  $(TOP)/src/test_wsd.c       \
  $(TOP)/ext/fts3/fts3_term.c \
  $(TOP)/ext/fts3/fts3_test.c  \
  $(TOP)/ext/session/test_session.c \
  $(TOP)/ext/recover/sqlite3recover.c \
  $(TOP)/ext/recover/dbdata.c \
  $(TOP)/ext/recover/test_recover.c \
  $(TOP)/ext/intck/test_intck.c  \
  $(TOP)/ext/intck/sqlite3intck.c \
  $(TOP)/ext/rbu/test_rbu.c

# Statically linked extensions
#
TESTSRC += \
  $(TOP)/ext/expert/sqlite3expert.c \
  $(TOP)/ext/expert/test_expert.c \
  $(TOP)/ext/misc/amatch.c \
  $(TOP)/ext/misc/appendvfs.c \
  $(TOP)/ext/misc/basexx.c \
  $(TOP)/ext/misc/carray.c \
  $(TOP)/ext/misc/cksumvfs.c \
  $(TOP)/ext/misc/closure.c \
  $(TOP)/ext/misc/csv.c \
  $(TOP)/ext/misc/decimal.c \
  $(TOP)/ext/misc/eval.c \
  $(TOP)/ext/misc/explain.c \
  $(TOP)/ext/misc/fileio.c \
  $(TOP)/ext/misc/fuzzer.c \
  $(TOP)/ext/fts5/fts5_tcl.c \
  $(TOP)/ext/fts5/fts5_test_mi.c \
  $(TOP)/ext/fts5/fts5_test_tok.c \
  $(TOP)/ext/misc/ieee754.c \
  $(TOP)/ext/misc/mmapwarm.c \
  $(TOP)/ext/misc/nextchar.c \
  $(TOP)/ext/misc/normalize.c \
  $(TOP)/ext/misc/percentile.c \
  $(TOP)/ext/misc/prefixes.c \
  $(TOP)/ext/misc/qpvtab.c \
  $(TOP)/ext/misc/randomjson.c \
  $(TOP)/ext/misc/regexp.c \
  $(TOP)/ext/misc/remember.c \
  $(TOP)/ext/misc/series.c \
  $(TOP)/ext/misc/spellfix.c \
  $(TOP)/ext/misc/stmtrand.c \
  $(TOP)/ext/misc/totype.c \
  $(TOP)/ext/misc/unionvtab.c \
  $(TOP)/ext/misc/wholenumber.c \
  $(TOP)/ext/misc/zipfile.c \
  $(TOP)/ext/userauth/userauth.c \
  $(TOP)/ext/rtree/test_rtreedoc.c

# Source code to the library files needed by the test fixture
#
TESTSRC2 = \
  $(TOP)/src/attach.c \
  $(TOP)/src/backup.c \
  $(TOP)/src/bitvec.c \
  $(TOP)/src/btree.c \
  $(TOP)/src/build.c \
  $(TOP)/src/ctime.c \
  $(TOP)/src/date.c \
  $(TOP)/src/dbpage.c \
  $(TOP)/src/dbstat.c \
  $(TOP)/src/expr.c \
  $(TOP)/src/func.c \
  $(TOP)/src/global.c \
  $(TOP)/src/insert.c \
  $(TOP)/src/wal.c \
  $(TOP)/src/main.c \
  $(TOP)/src/mem5.c \
  $(TOP)/src/os.c \
  $(TOP)/src/os_kv.c \
  $(TOP)/src/os_unix.c \
  $(TOP)/src/os_win.c \
  $(TOP)/src/pager.c \
  $(TOP)/src/pragma.c \
  $(TOP)/src/prepare.c \
  $(TOP)/src/printf.c \
  $(TOP)/src/random.c \
  $(TOP)/src/pcache.c \
  $(TOP)/src/pcache1.c \
  $(TOP)/src/select.c \
  $(TOP)/src/tokenize.c \
  $(TOP)/src/treeview.c \
  $(TOP)/src/utf.c \
  $(TOP)/src/util.c \
  $(TOP)/src/vdbeapi.c \
  $(TOP)/src/vdbeaux.c \
  $(TOP)/src/vdbe.c \
  $(TOP)/src/vdbemem.c \
  $(TOP)/src/vdbetrace.c \
  $(TOP)/src/vdbevtab.c \
  $(TOP)/src/where.c \
  $(TOP)/src/wherecode.c \
  $(TOP)/src/whereexpr.c \
  $(TOP)/src/window.c \
  parse.c \
  $(TOP)/ext/fts3/fts3.c \
  $(TOP)/ext/fts3/fts3_aux.c \
  $(TOP)/ext/fts3/fts3_expr.c \
  $(TOP)/ext/fts3/fts3_term.c \
  $(TOP)/ext/fts3/fts3_tokenizer.c \
  $(TOP)/ext/fts3/fts3_write.c \
  $(TOP)/ext/async/sqlite3async.c \
  $(TOP)/ext/session/sqlite3session.c \
  $(TOP)/ext/misc/stmt.c \
  fts5.c

# Header files used by all library source files.
#
HDR = \
   $(TOP)/src/btree.h \
   $(TOP)/src/btreeInt.h \
   $(TOP)/src/hash.h \
   $(TOP)/src/hwtime.h \
   keywordhash.h \
   $(TOP)/src/msvc.h \
   $(TOP)/src/mutex.h \
   opcodes.h \
   $(TOP)/src/os.h \
   $(TOP)/src/os_common.h \
   $(TOP)/src/os_setup.h \
   $(TOP)/src/os_win.h \
   $(TOP)/src/pager.h \
   $(TOP)/src/pcache.h \
   parse.h  \
   $(TOP)/src/pragma.h \
   sqlite3.h  \
   $(TOP)/src/sqlite3ext.h \
   $(TOP)/src/sqliteInt.h  \
   $(TOP)/src/sqliteLimit.h \
   $(TOP)/src/vdbe.h \
   $(TOP)/src/vdbeInt.h \
   $(TOP)/src/vxworks.h \
   $(TOP)/src/whereInt.h \
   sqlite_cfg.h
# Reminder: sqlite_cfg.h is typically created by the configure script

# Header files used by extensions
#
EXTHDR += \
  $(TOP)/ext/fts3/fts3.h \
  $(TOP)/ext/fts3/fts3Int.h \
  $(TOP)/ext/fts3/fts3_hash.h \
  $(TOP)/ext/fts3/fts3_tokenizer.h
EXTHDR += \
  $(TOP)/ext/rtree/rtree.h \
  $(TOP)/ext/rtree/geopoly.c
EXTHDR += \
  $(TOP)/ext/icu/sqliteicu.h
EXTHDR += \
  $(TOP)/ext/rtree/sqlite3rtree.h
EXTHDR += \
  $(TOP)/ext/userauth/sqlite3userauth.h

#
# Executables needed for testing
#
TESTPROGS = \
  testfixture$(T.exe) \
  sqlite3$(T.exe) \
  sqlite3_analyzer$(T.exe) \
  sqldiff$(T.exe) \
  dbhash$(T.exe) \
  sqltclsh$(T.exe)

# Databases containing fuzzer test cases
#
FUZZDATA = \
  $(TOP)/test/fuzzdata1.db \
  $(TOP)/test/fuzzdata2.db \
  $(TOP)/test/fuzzdata3.db \
  $(TOP)/test/fuzzdata4.db \
  $(TOP)/test/fuzzdata5.db \
  $(TOP)/test/fuzzdata6.db \
  $(TOP)/test/fuzzdata7.db \
  $(TOP)/test/fuzzdata8.db

#
# Standard options to testfixture
#
TESTOPTS = --verbose=file --output=test-out.txt

#
# Extra compiler options for various shell tools
#
SHELL_OPT += -DSQLITE_DQS=0
SHELL_OPT += -DSQLITE_ENABLE_FTS4
#SHELL_OPT += -DSQLITE_ENABLE_FTS5
SHELL_OPT += -DSQLITE_ENABLE_RTREE
SHELL_OPT += -DSQLITE_ENABLE_EXPLAIN_COMMENTS
SHELL_OPT += -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION
SHELL_OPT += -DSQLITE_ENABLE_STMTVTAB
SHELL_OPT += -DSQLITE_ENABLE_DBPAGE_VTAB
SHELL_OPT += -DSQLITE_ENABLE_DBSTAT_VTAB
SHELL_OPT += -DSQLITE_ENABLE_BYTECODE_VTAB
SHELL_OPT += -DSQLITE_ENABLE_OFFSET_SQL_FUNC
SHELL_OPT += -DSQLITE_STRICT_SUBTYPE=1
FUZZERSHELL_OPT =
FUZZCHECK_OPT += -I$(TOP)/test
FUZZCHECK_OPT += -I$(TOP)/ext/recover
FUZZCHECK_OPT += \
  -DSQLITE_OSS_FUZZ \
  -DSQLITE_ENABLE_BYTECODE_VTAB \
  -DSQLITE_ENABLE_DBPAGE_VTAB \
  -DSQLITE_ENABLE_DBSTAT_VTAB \
  -DSQLITE_ENABLE_BYTECODE_VTAB \
  -DSQLITE_ENABLE_DESERIALIZE \
  -DSQLITE_ENABLE_EXPLAIN_COMMENTS \
  -DSQLITE_ENABLE_FTS3_PARENTHESIS \
  -DSQLITE_ENABLE_FTS4 \
  -DSQLITE_ENABLE_FTS5 \
  -DSQLITE_ENABLE_GEOPOLY \
  -DSQLITE_ENABLE_MATH_FUNCTIONS \
  -DSQLITE_ENABLE_MEMSYS5 \
  -DSQLITE_ENABLE_NORMALIZE \
  -DSQLITE_ENABLE_OFFSET_SQL_FUNC \
  -DSQLITE_ENABLE_PREUPDATE_HOOK \
  -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_SESSION \
  -DSQLITE_ENABLE_STMTVTAB \
  -DSQLITE_ENABLE_UNKNOWN_SQL_FUNCTION \
  -DSQLITE_ENABLE_STAT4 \
  -DSQLITE_ENABLE_STMT_SCANSTATUS \
  -DSQLITE_MAX_MEMORY=50000000 \
  -DSQLITE_MAX_MMAP_SIZE=0 \
  -DSQLITE_OMIT_LOAD_EXTENSION \
  -DSQLITE_PRINTF_PRECISION_LIMIT=1000 \
  -DSQLITE_PRIVATE="" \
  -DSQLITE_STRICT_SUBTYPE=1 \
  -DSQLITE_STATIC_RANDOMJSON

FUZZCHECK_SRC += $(TOP)/test/fuzzcheck.c
FUZZCHECK_SRC += $(TOP)/test/ossfuzz.c
FUZZCHECK_SRC += $(TOP)/test/fuzzinvariants.c
FUZZCHECK_SRC += $(TOP)/ext/recover/dbdata.c
FUZZCHECK_SRC += $(TOP)/ext/recover/sqlite3recover.c
FUZZCHECK_SRC += $(TOP)/test/vt02.c
FUZZCHECK_SRC += $(TOP)/ext/misc/percentile.c
FUZZCHECK_SRC += $(TOP)/ext/misc/randomjson.c
DBFUZZ_OPT =
ST_OPT = -DSQLITE_OS_KV_OPTIONAL

$(TCLSH_CMD):
has_tclsh84:
	sh $(TOP)/tool/cktclsh.sh 8.4 $(TCLSH_CMD)
	touch has_tclsh84

has_tclsh85:
	sh $(TOP)/tool/cktclsh.sh 8.5 $(TCLSH_CMD)
	touch has_tclsh85

has_tclconfig:
	@if [ x = "x$(TCL_CONFIG_SH)" ]; then \
		echo 'TCL_CONFIG_SH must be set to point to a "tclConfig.sh"' 1>&2; exit 1; \
	fi
	touch has_tclconfig

#
# This target creates a directory named "tsrc" and fills it with
# copies of all of the C source code and header files needed to
# build on the target system.  Some of the C source code and header
# files are automatically generated.  This target takes care of
# all that automatic generation.
#
.target_source: $(MAKE_SANITY_CHECK) $(SRC) $(TOP)/tool/vdbe-compress.tcl \
    fts5.c $(B.tclsh) # has_tclsh84
	rm -rf tsrc
	mkdir tsrc
	cp -f $(SRC) tsrc
	rm tsrc/sqlite.h.in tsrc/parse.y
	$(B.tclsh) $(TOP)/tool/vdbe-compress.tcl $(OPTS) <tsrc/vdbe.c >vdbe.new
	mv vdbe.new tsrc/vdbe.c
	cp fts5.c fts5.h tsrc
	touch .target_source

libsqlite3.LIB = libsqlite3$(T.lib)
libsqlite3.SO = libsqlite3$(T.dll)

# Rules to build the LEMON compiler generator
#
lemon$(B.exe): $(MAKE_SANITY_CHECK) $(TOP)/tool/lemon.c $(TOP)/tool/lempar.c
	$(B.cc) -o $@ $(TOP)/tool/lemon.c
	cp $(TOP)/tool/lempar.c .

# Rules to build the program that generates the source-id
#
mksourceid$(B.exe): $(MAKE_SANITY_CHECK) $(TOP)/tool/mksourceid.c
	$(B.cc) -o $@ $(TOP)/tool/mksourceid.c

sqlite3.h: $(MAKE_SANITY_CHECK) $(TOP)/src/sqlite.h.in \
    $(TOP)/manifest mksourceid$(B.exe) \
		$(TOP)/VERSION $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/mksqlite3h.tcl $(TOP) >sqlite3.h

sqlite3.c:	.target_source sqlite3.h $(TOP)/tool/mksqlite3c.tcl src-verify \
		$(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/mksqlite3c.tcl $(AMALGAMATION_GEN_FLAGS) $(EXTRA_SRC)
	cp tsrc/sqlite3ext.h .
	cp $(TOP)/ext/session/sqlite3session.h .

sqlite3r.h: sqlite3.h $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/mksqlite3h.tcl $(TOP) --enable-recover >sqlite3r.h

sqlite3r.c: sqlite3.c sqlite3r.h $(B.tclsh) # has_tclsh84
	cp $(TOP)/ext/recover/sqlite3recover.c tsrc/
	cp $(TOP)/ext/recover/sqlite3recover.h tsrc/
	cp $(TOP)/ext/recover/dbdata.c tsrc/
	$(B.tclsh) $(TOP)/tool/mksqlite3c.tcl --enable-recover $(AMALGAMATION_GEN_FLAGS) $(EXTRA_SRC)

sqlite3ext.h: .target_source
	cp tsrc/sqlite3ext.h .

# Rules to build individual *.o files from generated *.c files. This
# applies to:
#
#     parse.o
#     opcodes.o
#
DEPS_OBJ_COMMON = $(MAKE_SANITY_CHECK) $(HDR)
parse.o:	parse.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c parse.c

opcodes.o:	opcodes.c
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c opcodes.c

# Rules to build individual *.o files from files in the src directory.
#
alter.o:	$(TOP)/src/alter.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/alter.c

analyze.o:	$(TOP)/src/analyze.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/analyze.c

attach.o:	$(TOP)/src/attach.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/attach.c

auth.o:	$(TOP)/src/auth.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/auth.c

backup.o:	$(TOP)/src/backup.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/backup.c

bitvec.o:	$(TOP)/src/bitvec.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/bitvec.c

btmutex.o:	$(TOP)/src/btmutex.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/btmutex.c

btree.o:	$(TOP)/src/btree.c $(DEPS_OBJ_COMMON) $(TOP)/src/pager.h
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/btree.c

build.o:	$(TOP)/src/build.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/build.c

callback.o:	$(TOP)/src/callback.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/callback.c

complete.o:	$(TOP)/src/complete.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/complete.c

ctime.o:	$(TOP)/src/ctime.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/ctime.c

date.o:	$(TOP)/src/date.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/date.c

dbpage.o:	$(TOP)/src/dbpage.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/dbpage.c

dbstat.o:	$(TOP)/src/dbstat.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/dbstat.c

delete.o:	$(TOP)/src/delete.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/delete.c

expr.o:	$(TOP)/src/expr.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/expr.c

fault.o:	$(TOP)/src/fault.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/fault.c

fkey.o:	$(TOP)/src/fkey.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/fkey.c

func.o:	$(TOP)/src/func.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/func.c

global.o:	$(TOP)/src/global.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/global.c

hash.o:	$(TOP)/src/hash.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/hash.c

insert.o:	$(TOP)/src/insert.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/insert.c

json.o:	$(TOP)/src/json.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/json.c

legacy.o:	$(TOP)/src/legacy.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/legacy.c

loadext.o:	$(TOP)/src/loadext.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/loadext.c

main.o:	$(TOP)/src/main.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/main.c

malloc.o:	$(TOP)/src/malloc.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/malloc.c

mem0.o:	$(TOP)/src/mem0.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mem0.c

mem1.o:	$(TOP)/src/mem1.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mem1.c

mem2.o:	$(TOP)/src/mem2.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mem2.c

mem3.o:	$(TOP)/src/mem3.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mem3.c

mem5.o:	$(TOP)/src/mem5.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mem5.c

memdb.o:	$(TOP)/src/memdb.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/memdb.c

memjournal.o:	$(TOP)/src/memjournal.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/memjournal.c

mutex.o:	$(TOP)/src/mutex.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mutex.c

mutex_noop.o:	$(TOP)/src/mutex_noop.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mutex_noop.c

mutex_unix.o:	$(TOP)/src/mutex_unix.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mutex_unix.c

mutex_w32.o:	$(TOP)/src/mutex_w32.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/mutex_w32.c

notify.o:	$(TOP)/src/notify.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/notify.c

pager.o:	$(TOP)/src/pager.c $(DEPS_OBJ_COMMON) $(TOP)/src/pager.h
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/pager.c

pcache.o:	$(TOP)/src/pcache.c $(DEPS_OBJ_COMMON) $(TOP)/src/pcache.h
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/pcache.c

pcache1.o:	$(TOP)/src/pcache1.c $(DEPS_OBJ_COMMON) $(TOP)/src/pcache.h
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/pcache1.c

os.o:	$(TOP)/src/os.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/os.c

os_kv.o:	$(TOP)/src/os_kv.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/os_kv.c

os_unix.o:	$(TOP)/src/os_unix.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/os_unix.c

os_win.o:	$(TOP)/src/os_win.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/os_win.c

pragma.o:	$(TOP)/src/pragma.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/pragma.c

prepare.o:	$(TOP)/src/prepare.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/prepare.c

printf.o:	$(TOP)/src/printf.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/printf.c

random.o:	$(TOP)/src/random.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/random.c

resolve.o:	$(TOP)/src/resolve.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/resolve.c

rowset.o:	$(TOP)/src/rowset.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/rowset.c

select.o:	$(TOP)/src/select.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/select.c

status.o:	$(TOP)/src/status.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/status.c

sqlite3.o:	sqlite3.h sqlite3.c
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c sqlite3.c

table.o:	$(TOP)/src/table.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/table.c

threads.o:	$(TOP)/src/threads.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/threads.c

tokenize.o:	$(TOP)/src/tokenize.c keywordhash.h $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/tokenize.c

treeview.o:	$(TOP)/src/treeview.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/treeview.c

trigger.o:	$(TOP)/src/trigger.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/trigger.c

update.o:	$(TOP)/src/update.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/update.c

upsert.o:	$(TOP)/src/upsert.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/upsert.c

utf.o:	$(TOP)/src/utf.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/utf.c

util.o:	$(TOP)/src/util.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/util.c

vacuum.o:	$(TOP)/src/vacuum.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vacuum.c

vdbe.o:	$(TOP)/src/vdbe.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbe.c

vdbeapi.o:	$(TOP)/src/vdbeapi.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbeapi.c

vdbeaux.o:	$(TOP)/src/vdbeaux.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbeaux.c

vdbeblob.o:	$(TOP)/src/vdbeblob.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbeblob.c

vdbemem.o:	$(TOP)/src/vdbemem.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbemem.c

vdbesort.o:	$(TOP)/src/vdbesort.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbesort.c

vdbetrace.o:	$(TOP)/src/vdbetrace.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbetrace.c

vdbevtab.o:	$(TOP)/src/vdbevtab.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vdbevtab.c

vtab.o:	$(TOP)/src/vtab.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/vtab.c

wal.o:	$(TOP)/src/wal.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/wal.c

walker.o:	$(TOP)/src/walker.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/walker.c

where.o:	$(TOP)/src/where.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/where.c

wherecode.o:	$(TOP)/src/wherecode.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/wherecode.c

whereexpr.o:	$(TOP)/src/whereexpr.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/whereexpr.c

window.o:	$(TOP)/src/window.c $(DEPS_OBJ_COMMON)
	$(T.cc.sqlite) $(CFLAGS.libsqlite3) -c $(TOP)/src/window.c

tclsqlite.o:	$(TOP)/src/tclsqlite.c $(DEPS_OBJ_COMMON)
	$(T.compile) -DUSE_TCL_STUBS=1 $(TCL_INCLUDE_SPEC) $(CFLAGS.intree_includes) \
		-c $(TOP)/src/tclsqlite.c

tclsqlite-shell.o:	$(TOP)/src/tclsqlite.c $(DEPS_OBJ_COMMON)
	$(T.compile) -DTCLSH -o $@ -c $(TOP)/src/tclsqlite.c $(TCL_INCLUDE_SPEC)

tclsqlite-stubs.o:	$(TOP)/src/tclsqlite.c $(DEPS_OBJ_COMMON)
	$(T.compile) -DUSE_TCL_STUBS=1 -o $@ -c $(TOP)/src/tclsqlite.c $(TCL_INCLUDE_SPEC)

tclsqlite3$(T.exe):	has_tclconfig tclsqlite-shell.o $(libsqlite3.LIB)
	$(T.link) -o $@ tclsqlite-shell.o \
		 $(libsqlite3.LIB) $(TCL_INCLUDE_SPEC) $(TCL_LIB_SPEC) $(LDFLAGS.libsqlite3)

# Rules to build opcodes.c and opcodes.h
#
opcodes.c:	opcodes.h $(TOP)/tool/mkopcodec.tcl $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/mkopcodec.tcl opcodes.h >opcodes.c

opcodes.h:	parse.h $(TOP)/src/vdbe.c \
		$(TOP)/tool/mkopcodeh.tcl $(B.tclsh) # has_tclsh84
	cat parse.h $(TOP)/src/vdbe.c | $(B.tclsh) $(TOP)/tool/mkopcodeh.tcl >opcodes.h

# Rules to build parse.c and parse.h - the outputs of lemon.
#
parse.h:	parse.c

parse.c:	$(TOP)/src/parse.y lemon$(B.exe)
	cp $(TOP)/src/parse.y .
	./lemon$(B.exe) $(OPT_FEATURE_FLAGS) $(OPTS) -S parse.y

sqlite3rc.h:	$(TOP)/src/sqlite3.rc $(TOP)/VERSION $(B.tclsh) # has_tclsh84
	echo '#ifndef SQLITE_RESOURCE_VERSION' >$@
	echo -n '#define SQLITE_RESOURCE_VERSION ' >>$@
	cat $(TOP)/VERSION | $(B.tclsh) $(TOP)/tool/replace.tcl exact . , >>$@
	echo '#endif' >>sqlite3rc.h

mkkeywordhash$(B.exe): $(TOP)/tool/mkkeywordhash.c
	$(B.cc) -o $@ $(OPT_FEATURE_FLAGS) $(OPTS) $(TOP)/tool/mkkeywordhash.c
keywordhash.h:	mkkeywordhash$(B.exe)
	./mkkeywordhash$(B.exe) > $@

#
# sqlite3.c split into many smaller files.
#
sqlite3-all.c:	sqlite3.c $(TOP)/tool/split-sqlite3c.tcl $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/split-sqlite3c.tcl

#
# Static libsqlite3
#
$(libsqlite3.LIB): $(LIBOBJ)
	$(AR) crs $@ $(LIBOBJ)
lib: $(libsqlite3.LIB)
all: lib

#
# Dynamic libsqlite3
#
$(libsqlite3.SO):	$(LIBOBJ)
	$(T.link.shared) -o $@ $(LIBOBJ) $(LDFLAGS.libsqlite3)
$(libsqlite3.SO)-1: $(libsqlite3.SO)
$(libsqlite3.SO)-0 $(libsqlite3.SO)-:
so: $(libsqlite3.SO)-$(ENABLE_SHARED)
all: so

#
# Install the $(libsqlite3.SO) as $(libsqlite3.SO).$(VERSION.XYZ) and
# create symlinks which point to it. Do we really need all of this
# hoop-jumping? Can we not simply install the .so as-is to
# libsqlite3.so (without the versioned bits)?
#
# The historical SQLite build always used a version number of 0.8.6
# for reasons lost to history but having something to do with libtool
# (which is not longer used in this tree).
#
install-so-1: $(install-dir.lib) $(libsqlite3.SO)
	$(INSTALL) $(libsqlite3.SO) $(install-dir.lib)
	@echo "Setting up SO symlinks..."; \
		cd $(install-dir.lib) || exit $$?; \
		rm -f $(libsqlite3.SO).3 $(libsqlite3.SO).$(VERSION.XYZ) || exit $$?; \
		mv $(libsqlite3.SO) $(libsqlite3.SO).$(VERSION.XYZ) || exit $$?; \
		ln -s $(libsqlite3.SO).$(VERSION.XYZ) $(libsqlite3.SO).3 || exit $$?; \
		ln -s $(libsqlite3.SO).3 $(libsqlite3.SO) || exit $$?; \
		ls -la $(libsqlite3.SO) $(libsqlite3.SO).3 $(libsqlite3.SO).$(VERSION.XYZ)
install-so-0 install-so-:
install: install-so-$(ENABLE_SHARED)

#
# Install $(libsqlite3.LIB)
#
install-lib: $(install-dir.lib) $(libsqlite3.LIB)
	$(INSTALL.noexec) $(libsqlite3.LIB) $(install-dir.lib)
install: install-lib

#
# Install C header files
#
install-includes: sqlite3.h $(install-dir.include)
	$(INSTALL.noexec) sqlite3.h "$(TOP)/src/sqlite3ext.h" $(install-dir.include)
install: install-includes

#
# libtclsqlite3...
#
pkgIndex.tcl:
	echo 'package ifneeded sqlite3 $(VERSION.XYZ) [list load [file join $$dir libtclsqlite3[info sharedlibextension]] sqlite3]' > $@
libtclsqlite3.SO = libtclsqlite3$(T.dll)
$(libtclsqlite3.SO): tclsqlite.o $(libsqlite3.LIB)
	$(T.link.shared) -o $@ tclsqlite.o \
		$(TCL_INCLUDE_SPEC) $(TCL_STUB_LIB_SPEC) $(LDFLAGS.libsqlite3) \
		$(libsqlite3.LIB) $(TCLLIB_RPATH)
$(libtclsqlite3.SO)-1: $(libtclsqlite3.SO)
$(libtclsqlite3.SO)-0 $(libtclsqlite3.SO)-:
libtcl: $(libtclsqlite3.SO)-$(HAVE_TCL)
all: libtcl

install.tcldir = $(DESTDIR)$(TCLLIBDIR)
install-tcl-1: install-lib $(libtclsqlite3.SO) pkgIndex.tcl
	@if [ "x$(DESTDIR)" = "x$(install.tcldir)" ]; then echo "TCLLIBDIR is not set." 1>&2; exit 1; fi
	$(INSTALL) -d $(install.tcldir)
	$(INSTALL) $(libtclsqlite3.SO) $(install.tcldir)
	$(INSTALL.noexec) pkgIndex.tcl $(install.tcldir)
install-tcl-0 install-tcl-:
install: install-tcl-$(HAVE_TCL)

tclsqlite3.c:	sqlite3.c
	echo '#ifndef USE_SYSTEM_SQLITE' >tclsqlite3.c
	cat sqlite3.c >>tclsqlite3.c
	echo '#endif /* USE_SYSTEM_SQLITE */' >>tclsqlite3.c
	cat $(TOP)/src/tclsqlite.c >>tclsqlite3.c

CFLAGS.tclextension = $(CFLAGS.intree_includes) $(CFLAGS) $(OPT_FEATURE_FLAGS) $(OPTS)
#
# Build the SQLite TCL extension in a way that make it compatible
# with whatever version of TCL is running as $TCLSH_CMD, possibly defined
# by --with-tclsh=
#
tclextension: tclsqlite3.c
	$(TCLSH_CMD) $(TOP)/tool/buildtclext.tcl --build-only --cc "$(CC)" $(CFLAGS.tclextension)

#
# Install the SQLite TCL extension in a way that is appropriate for $TCLSH_CMD
# to find it.
#
tclextension-install: tclsqlite3.c
	$(TCLSH_CMD) $(TOP)/tool/buildtclext.tcl --cc "$(CC)" $(CFLAGS.tclextension)

#
# Install the SQLite TCL extension that is used by $TCLSH_CMD
#
tclextension-uninstall:
	$(TCLSH_CMD) $(TOP)/tool/buildtclext.tcl --uninstall

#
# List all installed the SQLite TCL extension that is are accessible
# by $TCLSH_CMD, included prior versions.
#
tclextension-list:
	$(TCLSH_CMD) $(TOP)/tool/buildtclext.tcl --info

#
# FTS5 things
#
FTS5_SRC = \
   $(TOP)/ext/fts5/fts5.h \
   $(TOP)/ext/fts5/fts5Int.h \
   $(TOP)/ext/fts5/fts5_aux.c \
   $(TOP)/ext/fts5/fts5_buffer.c \
   $(TOP)/ext/fts5/fts5_main.c \
   $(TOP)/ext/fts5/fts5_config.c \
   $(TOP)/ext/fts5/fts5_expr.c \
   $(TOP)/ext/fts5/fts5_hash.c \
   $(TOP)/ext/fts5/fts5_index.c \
   fts5parse.c fts5parse.h \
   $(TOP)/ext/fts5/fts5_storage.c \
   $(TOP)/ext/fts5/fts5_tokenize.c \
   $(TOP)/ext/fts5/fts5_unicode2.c \
   $(TOP)/ext/fts5/fts5_varint.c \
   $(TOP)/ext/fts5/fts5_vocab.c  \

fts5parse.c:	$(TOP)/ext/fts5/fts5parse.y lemon$(B.exe)
	cp $(TOP)/ext/fts5/fts5parse.y .
	rm -f fts5parse.h
	./lemon$(B.exe) $(OPTS) -S fts5parse.y

fts5parse.h: fts5parse.c

fts5.c: $(FTS5_SRC) $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/ext/fts5/tool/mkfts5c.tcl
	cp $(TOP)/ext/fts5/fts5.h .

fts5.o:	fts5.c $(DEPS_OBJ_COMMON) $(EXTHDR)
	$(T.cc.extension) -c fts5.c

sqlite3rbu.o:	$(TOP)/ext/rbu/sqlite3rbu.c $(DEPS_OBJ_COMMON) $(EXTHDR)
	$(T.cc.extension) -c $(TOP)/ext/rbu/sqlite3rbu.c


#
# Rules to build the 'testfixture' application.
#
# If using the amalgamation, use sqlite3.c directly to build the test
# fixture.  Otherwise link against libsqlite3.a.  (This distinction is
# necessary because the test fixture requires non-API symbols which are
# hidden when the library is built via the amalgamation).
#
TESTFIXTURE_FLAGS  = -DSQLITE_TEST=1 -DSQLITE_CRASH_TEST=1
TESTFIXTURE_FLAGS += -DTCLSH_INIT_PROC=sqlite3TestInit
TESTFIXTURE_FLAGS += -DSQLITE_SERVER=1 -DSQLITE_PRIVATE="" -DSQLITE_CORE
TESTFIXTURE_FLAGS += -DBUILD_sqlite
TESTFIXTURE_FLAGS += -DSQLITE_SERIES_CONSTRAINT_VERIFY=1
TESTFIXTURE_FLAGS += -DSQLITE_DEFAULT_PAGE_SIZE=1024
TESTFIXTURE_FLAGS += -DSQLITE_ENABLE_STMTVTAB
TESTFIXTURE_FLAGS += -DSQLITE_ENABLE_DBPAGE_VTAB
TESTFIXTURE_FLAGS += -DSQLITE_ENABLE_BYTECODE_VTAB
TESTFIXTURE_FLAGS += -DSQLITE_CKSUMVFS_STATIC
TESTFIXTURE_FLAGS += -DSQLITE_STATIC_RANDOMJSON
TESTFIXTURE_FLAGS += -DSQLITE_STRICT_SUBTYPE=1

TESTFIXTURE_SRC0 = $(TESTSRC2) $(libsqlite3.LIB)
TESTFIXTURE_SRC1 = sqlite3.c
TESTFIXTURE_SRC = $(TESTSRC) $(TOP)/src/tclsqlite.c
TESTFIXTURE_SRC += $(TESTFIXTURE_SRC$(USE_AMALGAMATION))

testfixture$(T.exe):	has_tclconfig has_tclsh85 $(TESTFIXTURE_SRC)
	$(T.link) -DSQLITE_NO_SYNC=1 $(TESTFIXTURE_FLAGS) \
		-o $@ $(TESTFIXTURE_SRC) \
		$(TCL_LIB_SPEC) $(TCL_INCLUDE_SPEC) \
		$(CFLAGS.libsqlite3) $(LDFLAGS.libsqlite3)

coretestprogs:	testfixture$(B.exe) sqlite3$(B.exe)

testprogs:	$(TESTPROGS) srcck1$(B.exe) fuzzcheck$(T.exe) sessionfuzz$(T.exe)

# A very detailed test running most or all test cases
fulltest:	alltest fuzztest

# Run most or all tcl test cases
alltest:	$(TESTPROGS)
	./testfixture$(T.exe) $(TOP)/test/all.test $(TESTOPTS)

# Really really long testing
soaktest:	$(TESTPROGS)
	./testfixture$(T.exe) $(TOP)/test/all.test -soak=1 $(TESTOPTS)

# Do extra testing but not everything.
fulltestonly:	$(TESTPROGS) fuzztest
	./testfixture$(T.exe) $(TOP)/test/full.test

#
# Fuzz testing
#
# WARNING: When the "fuzztest" target is run by the testrunner.tcl script,
# it does not actually run this code. Instead, it schedules equivalent
# commands. Therefore, if this target is updated, then code in
# testrunner_data.tcl (search for "trd_fuzztest_data") must also be updated.
#
fuzztest:	fuzzcheck$(T.exe) $(FUZZDATA) sessionfuzz$(T.exe)
	./fuzzcheck$(T.exe) $(FUZZDATA)
	./sessionfuzz$(T.exe) run $(TOP)/test/sessionfuzz-data1.db

valgrindfuzz:	fuzzcheck$(TEXT) $(FUZZDATA) sessionfuzz$(T.exe)
	valgrind ./fuzzcheck$(T.exe) --cell-size-check --limit-mem 10M $(FUZZDATA)
	valgrind ./sessionfuzz$(T.exe) run $(TOP)/test/sessionfuzz-data1.db

#
# The veryquick.test TCL tests.
#
tcltest:	./testfixture$(T.exe)
	./testfixture$(T.exe) $(TOP)/test/veryquick.test $(TESTOPTS)

#
# Runs all the same tests cases as the "tcltest" target but uses
# the testrunner.tcl script to run them in multiple cores
# concurrently.
testrunner:	testfixture$(T.exe)
	./testfixture$(T.exe) $(TOP)/test/testrunner.tcl

#
# This is the testing target preferred by the core SQLite developers.
# It runs tests under a standard configuration, regardless of how
# ./configure was run.  The devs run "make devtest" prior to each
# check-in, at a minimum.  Probably other tests too, but at least this
# one.
#
devtest:	srctree-check sourcetest
	$(TCLSH_CMD) $(TOP)/test/testrunner.tcl mdevtest $(TSTRNNR_OPTS)

mdevtest: srctree-check has_tclsh85
	$(TCLSH_CMD) $(TOP)/test/testrunner.tcl mdevtest $(TSTRNNR_OPTS)

sdevtest: has_tclsh85
	$(TCLSH_CMD) $(TOP)/test/testrunner.tcl sdevtest $(TSTRNNR_OPTS)

#
# Validate that various generated files in the source tree
# are up-to-date.
#
srctree-check:	$(TOP)/tool/srctree-check.tcl
	$(TCLSH_CMD) $(TOP)/tool/srctree-check.tcl

#
# Testing for a release
#
releasetest: srctree-check has_tclsh85 verify-source
	$(TCLSH_CMD) $(TOP)/test/testrunner.tcl release $(TSTRNNR_OPTS)

#
# Minimal testing that runs in less than 3 minutes
#
quicktest:	./testfixture$(T.exe)
	./testfixture$(T.exe) $(TOP)/test/extraquick.test $(TESTOPTS)

#
# Try to run tests on whatever options are specified by the
# ./configure.  The developers seldom use this target.  Instead
# they use "make devtest" which runs tests on a standard set of
# options regardless of how SQLite is configured.  This "test"
# target is provided for legacy only.
#
test:	srctree-check fuzztest sourcetest $(TESTPROGS) tcltest

#
# Run a test using valgrind.  This can take a really long time
# because valgrind is so much slower than a native machine.
#
valgrindtest:	$(TESTPROGS) valgrindfuzz
	OMIT_MISUSE=1 valgrind -v ./testfixture$(T.exe) $(TOP)/test/permutations.test valgrind $(TESTOPTS)

#
# A very fast test that checks basic sanity.  The name comes from
# the 60s-era electronics testing:  "Turn it on and see if smoke
# comes out."
#
smoketest:	$(TESTPROGS) fuzzcheck$(T.exe)
	./testfixture$(T.exe) $(TOP)/test/main.test $(TESTOPTS)

shelltest:
	$(TCLSH_CMD) $(TOP)/test/testrunner.tcl release shell

sqlite3_analyzer.c: sqlite3.c $(TOP)/src/tclsqlite.c $(TOP)/tool/spaceanal.tcl \
                    $(TOP)/tool/mkccode.tcl $(TOP)/tool/sqlite3_analyzer.c.in has_tclsh85
	$(B.tclsh) $(TOP)/tool/mkccode.tcl $(TOP)/tool/sqlite3_analyzer.c.in >sqlite3_analyzer.c

sqlite3_analyzer$(T.exe): has_tclconfig sqlite3_analyzer.c
	$(T.link) sqlite3_analyzer.c -o $@ $(TCL_LIB_SPEC) $(TCL_INCLUDE_SPEC) $(LDFLAGS.libsqlite3)

sqltclsh.c: sqlite3.c $(TOP)/src/tclsqlite.c $(TOP)/tool/sqltclsh.tcl \
            $(TOP)/ext/misc/appendvfs.c $(TOP)/tool/mkccode.tcl \
            $(TOP)/tool/sqltclsh.c.in has_tclsh85
	$(B.tclsh) $(TOP)/tool/mkccode.tcl $(TOP)/tool/sqltclsh.c.in >sqltclsh.c

sqltclsh$(T.exe): has_tclconfig sqltclsh.c
	$(T.link) sqltclsh.c -o $@ $(TCL_INCLUDE_SPEC) $(CFLAGS.libsqlite3) $(TCL_LIB_SPEC) $(LDFLAGS.libsqlite3)
# xbin: target for generic binaries which aren't usually built. It is
# used primarily for testing the build process.
xbin: sqltclsh$(T.exe)

sqlite3_expert$(T.exe): $(TOP)/ext/expert/sqlite3expert.h $(TOP)/ext/expert/sqlite3expert.c \
                       $(TOP)/ext/expert/expert.c sqlite3.c
	$(T.link)	$(TOP)/ext/expert/sqlite3expert.h $(TOP)/ext/expert/sqlite3expert.c \
		$(TOP)/ext/expert/expert.c sqlite3.c -o sqlite3_expert $(LDFLAGS.libsqlite3)
xbin: sqlite3_expert$(T.exe)

CHECKER_DEPS =\
  $(TOP)/tool/mkccode.tcl \
  sqlite3.c \
  $(TOP)/src/tclsqlite.c \
  $(TOP)/ext/repair/sqlite3_checker.tcl \
  $(TOP)/ext/repair/checkindex.c \
  $(TOP)/ext/repair/checkfreelist.c \
  $(TOP)/ext/misc/btreeinfo.c \
  $(TOP)/ext/repair/sqlite3_checker.c.in

sqlite3_checker.c:	$(CHECKER_DEPS) has_tclsh85
	$(B.tclsh) $(TOP)/tool/mkccode.tcl $(TOP)/ext/repair/sqlite3_checker.c.in >$@

sqlite3_checker$(T.exe):	has_tclconfig sqlite3_checker.c
	$(T.link) sqlite3_checker.c -o $@ $(TCL_INCLUDE_SPEC) $(CFLAGS.libsqlite3) $(TCL_LIB_SPEC) $(LDFLAGS.libsqlite3)
xbin: sqlite3_checker$(T.exe)

dbdump$(T.exe): $(TOP)/ext/misc/dbdump.c sqlite3.o
	$(T.link) -DDBDUMP_STANDALONE -o $@ \
           $(TOP)/ext/misc/dbdump.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: dbdump$(T.exe)

dbtotxt$(T.exe): $(TOP)/tool/dbtotxt.c
	$(T.link)-o $@ $(TOP)/tool/dbtotxt.c
xbin: dbtotxt$(T.exe)

showdb$(T.exe):	$(TOP)/tool/showdb.c sqlite3.o
	$(T.link) -o $@ $(TOP)/tool/showdb.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: showdb$(T.exe)

showstat4$(T.exe):	$(TOP)/tool/showstat4.c sqlite3.o
	$(T.link) -o $@ $(TOP)/tool/showstat4.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: showstat4$(T.exe)

showjournal$(T.exe):	$(TOP)/tool/showjournal.c sqlite3.o
	$(T.link) -o $@ $(TOP)/tool/showjournal.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: showjournal$(T.exe)

showwal$(T.exe):	$(TOP)/tool/showwal.c sqlite3.o
	$(T.link) -o $@ $(TOP)/tool/showwal.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: showwal$(T.exe)

showshm$(T.exe):	$(TOP)/tool/showshm.c
	$(T.link) -o $@ $(TOP)/tool/showshm.c
xbin: showshm$(T.exe)

index_usage$(T.exe): $(TOP)/tool/index_usage.c sqlite3.o
	$(T.link) $(SHELL_OPT) -o $@ $(TOP)/tool/index_usage.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: index_usage$(T.exe)

# Reminder: changeset does not build without -DSQLITE_ENABLE_SESSION
changeset$(T.exe):	$(TOP)/ext/session/changeset.c sqlite3.o
	$(T.link) -o $@ $(TOP)/ext/session/changeset.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: changeset$(T.exe)

changesetfuzz$(T.exe):	$(TOP)/ext/session/changesetfuzz.c sqlite3.o
	$(T.link) -o $@ $(TOP)/ext/session/changesetfuzz.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: changesetfuzz$(T.exe)

rollback-test$(T.exe):	$(TOP)/tool/rollback-test.c sqlite3.o
	$(T.link) -o $@ $(TOP)/tool/rollback-test.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: rollback-test$(T.exe)

atrc$(TEXX): $(TOP)/test/atrc.c sqlite3.o
	$(T.link) -o $@ $(TOP)/test/atrc.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: atrc$(TEXX)

LogEst$(T.exe):	$(TOP)/tool/logest.c sqlite3.h
	$(T.link) -I. -o $@ $(TOP)/tool/logest.c
xbin: LogEst$(T.exe)

wordcount$(T.exe):	$(TOP)/test/wordcount.c sqlite3.o
	$(T.link) -o $@ $(TOP)/test/wordcount.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: wordcount$(T.exe)

speedtest1$(T.exe):	$(TOP)/test/speedtest1.c sqlite3.c Makefile
	$(T.link) $(ST_OPT) -o $@ $(TOP)/test/speedtest1.c sqlite3.c $(LDFLAGS.libsqlite3)
xbin: speedtest1$(T.exe)

startup$(T.exe):	$(TOP)/test/startup.c sqlite3.c
	$(T.link) -Os -g -USQLITE_THREADSAFE -DSQLITE_THREADSAFE=0 -o $@ $(TOP)/test/startup.c sqlite3.c $(LDFLAGS.libsqlite3)
xbin: startup$(T.exe)

KV_OPT += -DSQLITE_DIRECT_OVERFLOW_READ

kvtest$(T.exe):	$(TOP)/test/kvtest.c sqlite3.c
	$(T.link) $(KV_OPT) -o $@ $(TOP)/test/kvtest.c sqlite3.c $(LDFLAGS.libsqlite3)
xbin: kvtest$(T.exe)

#rbu$(T.exe): $(TOP)/ext/rbu/rbu.c $(TOP)/ext/rbu/sqlite3rbu.c sqlite3.o
#	$(T.link) -I. -o $@ $(TOP)/ext/rbu/rbu.c sqlite3.o $(LDFLAGS.libsqlite3)
#xbin: rbu$(T.exe)

loadfts$(T.exe): $(TOP)/tool/loadfts.c $(libsqlite3.LIB)
	$(T.link) $(TOP)/tool/loadfts.c $(libsqlite3.LIB) -o $@ $(LDFLAGS.libsqlite3)
xbin: loadfts$(T.exe)

# This target will fail if the SQLite amalgamation contains any exported
# symbols that do not begin with "sqlite3_". It is run as part of the
# releasetest.tcl script.
#
VALIDIDS=' sqlite3(changeset|changegroup|session|rebaser)?_'
checksymbols: sqlite3.o
	nm -g --defined-only sqlite3.o
	nm -g --defined-only sqlite3.o | egrep -v $(VALIDIDS); test $$? -ne 0
	echo '0 errors out of 1 tests'

# Build a ZIP archive containing various command-line tools.
#
tool-zip:	testfixture$(T.exe) sqlite3$(T.exe) sqldiff$(T.exe) \
            sqlite3_analyzer$(T.exe) sqlite3_rsync$(T.exe) $(TOP)/tool/mktoolzip.tcl
	strip sqlite3$(T.exe) sqldiff$(T.exe) sqlite3_analyzer$(T.exe) sqlite3_rsync$(T.exe)
	./testfixture$(T.exe) $(TOP)/tool/mktoolzip.tcl
clean-tool-zip:
	rm -f sqlite-tools-*.zip
clean: clean-tool-zip
#XX# TODO: adapt the autoconf amalgamation for autosetup
#XX#
#XX## Build the amalgamation-autoconf package.  The amalamgation-tarball target builds
#XX## a tarball named for the version number.  Ex:  sqlite-autoconf-3110000.tar.gz.
#XX## The snapshot-tarball target builds a tarball named by the SHA1 hash
#XX##
#XX#amalgamation-tarball: sqlite3.c sqlite3rc.h
#XX#	TOP=$(TOP) sh $(TOP)/tool/mkautoconfamal.sh --normal
#XX#
#XX#snapshot-tarball: sqlite3.c sqlite3rc.h
#XX#	TOP=$(TOP) sh $(TOP)/tool/mkautoconfamal.sh --snapshot
#XX#

# The next two rules are used to support the "threadtest" target. Building
# threadtest runs a few thread-safety tests that are implemented in C. This
# target is invoked by the releasetest.tcl script.
#
THREADTEST3_SRC = $(TOP)/test/threadtest3.c    \
                  $(TOP)/test/tt3_checkpoint.c \
                  $(TOP)/test/tt3_index.c      \
                  $(TOP)/test/tt3_vacuum.c      \
                  $(TOP)/test/tt3_stress.c      \
                  $(TOP)/test/tt3_lookaside1.c

threadtest3$(T.exe): sqlite3.o $(THREADTEST3_SRC)
	$(T.link) $(TOP)/test/threadtest3.c $(TOP)/src/test_multiplex.c sqlite3.o -o $@ $(LDFLAGS.libsqlite3)
xbin: threadtest3$(T.exe)

threadtest: threadtest3$(T.exe)
	./threadtest3$(T.exe)

threadtest5: sqlite3.c $(TOP)/test/threadtest5.c
	$(T.link) $(TOP)/test/threadtest5.c sqlite3.c -o $@ $(LDFLAGS.libsqlite3)
xbin: threadtest5

sqlite3$(T.exe):	shell.c sqlite3.c $(LIBOBJ)
	$(T.link) -o $@ \
		shell.c $(LIBOBJ) \
		$(CFLAGS.readline) $(SHELL_OPT) \
		$(LDFLAGS.libsqlite3) $(LDFLAGS.readline)

#
# Build sqlite3$(T.exe) by default except in wasi-sdk builds.  Yes, the
# semantics of 0 and 1 are confusingly swapped here.
#
sqlite3$(T.exe)-1:
sqlite3$(T.exe)-0 sqlite3$(T.exe)-: sqlite3$(T.exe)
all: sqlite3$(T.exe)-$(HAVE_WASI_SDK)

install-shell-0: sqlite3$(TEXT) $(install-dir.bin)
	$(INSTALL) -s sqlite3$(TEXT) $(install-dir.bin)
install-shell-1 install-shell-:
install: install-shell-$(HAVE_WASI_SDK)

sqldiff$(T.exe):	$(TOP)/tool/sqldiff.c $(TOP)/ext/misc/sqlite3_stdio.h sqlite3.o sqlite3.h
	$(T.link) -o $@ $(TOP)/tool/sqldiff.c sqlite3.o $(LDFLAGS.libsqlite3)

install-diff: sqldiff$(T.exe) $(install-dir.bin)
	$(INSTALL) -s sqldiff$(TEXT) $(install-dir.bin)
#install: install-diff

dbhash$(T.exe):	$(TOP)/tool/dbhash.c sqlite3.o sqlite3.h
	$(T.link) -o $@ $(TOP)/tool/dbhash.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: dbhash$(T.exe)

RSYNC_SRC = \
  $(TOP)/tool/sqlite3_rsync.c \
  sqlite3.c

RSYNC_OPT = \
  -DSQLITE_ENABLE_DBPAGE_VTAB \
  -USQLITE_THREADSAFE \
  -DSQLITE_THREADSAFE=0 \
  -DSQLITE_OMIT_LOAD_EXTENSION \
  -DSQLITE_OMIT_DEPRECATED

sqlite3_rsync$(T.exe):	$(RSYNC_SRC)
	$(T.cc.sqlite) -o $@ $(RSYNC_OPT) $(RSYNC_SRC) $(LDFLAGS.libsqlite3)
xbin: sqlite3_rsync$(T.exe)

install-rsync: sqlite3_rsync$(T.exe) $(install-dir.bin)
	$(INSTALL) sqlite3_rsync$(TEXT) $(install-dir.bin)
#install: install-rsync

install-man1: $(install-dir.man1)
	$(INSTALL.noexec) $(TOP)/sqlite3.1 $(install-dir.man1)
install: install-man1

#
# sqlite3.pc is typically generated by the configure script but could
# conceivably be generated by hand.
install-pc: sqlite3.pc $(install-dir.pkgconfig)
	$(INSTALL.noexec) sqlite3.pc $(install-dir.pkgconfig)

scrub$(T.exe):	$(TOP)/ext/misc/scrub.c sqlite3.o
	$(T.link) -o $@ -I. -DSCRUB_STANDALONE \
		$(TOP)/ext/misc/scrub.c sqlite3.o $(LDFLAGS.libsqlite3)
xbin: scrub$(T.exe)

srcck1$(B.exe):	$(TOP)/tool/srcck1.c
	$(B.cc) -o srcck1$(B.exe) $(TOP)/tool/srcck1.c
xbin: srcck1$(B.exe)

sourcetest:	srcck1$(B.exe) sqlite3.c
	./srcck1$(B.exe) sqlite3.c

src-verify$(B.exe):	$(TOP)/tool/src-verify.c
	$(B.cc) -o src-verify$(B.exe) $(TOP)/tool/src-verify.c
xbin: src-verify$(B.exe)

verify-source:	./src-verify$(B.exe)
	./src-verify$(B.exe) $(TOP)

fuzzershell$(T.exe):	$(TOP)/tool/fuzzershell.c sqlite3.c sqlite3.h
	$(T.link) -o $@ $(FUZZERSHELL_OPT) \
	  $(TOP)/tool/fuzzershell.c sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: fuzzershell$(T.exe)
xbin: fuzzershell$(T.exe)

fuzzcheck$(T.exe):	$(FUZZCHECK_SRC) sqlite3.c sqlite3.h $(FUZZCHECK_DEP)
	$(T.link) -o $@ $(FUZZCHECK_OPT) $(FUZZCHECK_SRC) sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: fuzzcheck$(T.exe)
xbin: fuzzcheck$(T.exe)

fuzzcheck-asan$(T.exe):	$(FUZZCHECK_SRC) sqlite3.c sqlite3.h $(FUZZCHECK_DEP)
	$(T.link) -o $@ -fsanitize=address $(FUZZCHECK_OPT) $(FUZZCHECK_SRC) \
		sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: fuzzcheck-asan$(T.exe)
xbin: fuzzcheck-asan$(T.exe)

fuzzcheck-ubsan$(T.exe):	$(FUZZCHECK_SRC) sqlite3.c sqlite3.h $(FUZZCHECK_DEP)
	$(T.link) -o $@ -fsanitize=undefined $(FUZZCHECK_OPT) $(FUZZCHECK_SRC) \
		sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: fuzzcheck-ubsan$(T.exe)
xbin: fuzzcheck-ubsan$(T.exe)

# Usage:    FUZZDB=filename make run-fuzzcheck
#
# Where filename is a fuzzcheck database, this target builds and runs
# fuzzcheck, fuzzcheck-asan, and fuzzcheck-ubsan on that database.
#
# FUZZDB can be a glob pattern of two or more databases. Example:
#
#     FUZZDB=test/fuzzdata*.db make run-fuzzcheck
#
run-fuzzcheck:	fuzzcheck$(T.exe) fuzzcheck-asan$(T.exe) fuzzcheck-ubsan$(T.exe)
	@if test "$(FUZZDB)" = ""; then echo 'ERROR: No FUZZDB specified. Rerun with FUZZDB=filename'; exit 1; fi
	./fuzzcheck$(T.exe) --spinner $(FUZZDB)
	./fuzzcheck-asan$(T.exe) --spinner $(FUZZDB)
	./fuzzcheck-ubsan$(T.exe) --spinner $(FUZZDB)

ossshell$(T.exe):	$(TOP)/test/ossfuzz.c $(TOP)/test/ossshell.c sqlite3.c sqlite3.h
	$(T.link) -o $@ $(FUZZCHECK_OPT) $(TOP)/test/ossshell.c \
             $(TOP)/test/ossfuzz.c sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: ossshell$(T.exe)
xbin: ossshell$(T.exe)

sessionfuzz$(T.exe):	$(TOP)/test/sessionfuzz.c sqlite3.c sqlite3.h
	$(T.link) -o $@ $(TOP)/test/sessionfuzz.c $(LDFLAGS.libsqlite3)
fuzzy: sessionfuzz$(T.exe)

dbfuzz$(T.exe):	$(TOP)/test/dbfuzz.c sqlite3.c sqlite3.h
	$(T.link) -o $@ $(DBFUZZ_OPT) $(TOP)/test/dbfuzz.c sqlite3.c $(LDFLAGS.libsqlite3)
fuzzy: dbfuzz$(T.exe)
xbin: dbfuzz$(T.exe)

DBFUZZ2_OPTS = \
  -USQLITE_THREADSAFE \
  -DSQLITE_THREADSAFE=0 \
  -DSQLITE_OMIT_LOAD_EXTENSION \
  -DSQLITE_DEBUG \
  -DSQLITE_ENABLE_DBSTAT_VTAB \
  -DSQLITE_ENABLE_BYTECODE_VTAB \
  -DSQLITE_ENABLE_RTREE \
  -DSQLITE_ENABLE_FTS4 \
  -DSQLITE_ENABLE_FTS5

dbfuzz2$(T.exe):	$(TOP)/test/dbfuzz2.c sqlite3.c sqlite3.h
	$(T.cc) -I. -g -O0 \
		-DSTANDALONE -o dbfuzz2 \
		$(DBFUZZ2_OPTS) $(TOP)/test/dbfuzz2.c sqlite3.c $(LDFLAGS.libsqlite3)
	mkdir -p dbfuzz2-dir
	cp $(TOP)/test/dbfuzz2-seed* dbfuzz2-dir
fuzzy: dbfuzz2$(T.exe)
xbin: dbfuzz2$(T.exe)

mptester$(T.exe):	$(libsqlite3.LIB) $(TOP)/mptest/mptest.c
	$(T.link) -o $@ -I. $(TOP)/mptest/mptest.c $(libsqlite3.LIB) \
		$(LDFLAGS.libsqlite3)
xbin: mptester$(T.exe)

MPTEST1=./mptester$(T.exe) mptest.db $(TOP)/mptest/crash01.test --repeat 20
MPTEST2=./mptester$(T.exe) mptest.db $(TOP)/mptest/multiwrite01.test --repeat 20
mptest:	mptester$(T.exe)
	rm -f mptest.db
	$(MPTEST1) --journalmode DELETE
	$(MPTEST2) --journalmode WAL
	$(MPTEST1) --journalmode WAL
	$(MPTEST2) --journalmode PERSIST
	$(MPTEST1) --journalmode PERSIST
	$(MPTEST2) --journalmode TRUNCATE
	$(MPTEST1) --journalmode TRUNCATE
	$(MPTEST2) --journalmode DELETE

# Source and header files that shell.c depends on
SHELL_DEP = \
    $(TOP)/src/shell.c.in \
    $(TOP)/ext/consio/console_io.c \
    $(TOP)/ext/consio/console_io.h \
    $(TOP)/ext/expert/sqlite3expert.c \
    $(TOP)/ext/expert/sqlite3expert.h \
    $(TOP)/ext/intck/sqlite3intck.c \
    $(TOP)/ext/intck/sqlite3intck.h \
    $(TOP)/ext/misc/appendvfs.c \
    $(TOP)/ext/misc/base64.c \
    $(TOP)/ext/misc/base85.c \
    $(TOP)/ext/misc/completion.c \
    $(TOP)/ext/misc/decimal.c \
    $(TOP)/ext/misc/fileio.c \
    $(TOP)/ext/misc/ieee754.c \
    $(TOP)/ext/misc/memtrace.c \
    $(TOP)/ext/misc/pcachetrace.c \
    $(TOP)/ext/misc/percentile.c \
    $(TOP)/ext/misc/regexp.c \
    $(TOP)/ext/misc/series.c \
    $(TOP)/ext/misc/sha1.c \
    $(TOP)/ext/misc/shathree.c \
    $(TOP)/ext/misc/sqlar.c \
    $(TOP)/ext/misc/uint.c \
    $(TOP)/ext/misc/vfstrace.c \
    $(TOP)/ext/misc/zipfile.c \
    $(TOP)/ext/recover/dbdata.c \
    $(TOP)/ext/recover/sqlite3recover.c \
    $(TOP)/ext/recover/sqlite3recover.h \
    $(TOP)/src/test_windirent.c \
    $(TOP)/src/test_windirent.h

shell.c:	$(SHELL_DEP) $(TOP)/tool/mkshellc.tcl $(B.tclsh) # has_tclsh84
	$(B.tclsh) $(TOP)/tool/mkshellc.tcl >shell.c

#
# Rules to build the extension objects.
#
DEPS_EXT_COMMON = $(DEPS_OBJ_COMMON) $(EXTHDR)
icu.o:	$(TOP)/ext/icu/icu.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/icu/icu.c

fts3.o:	$(TOP)/ext/fts3/fts3.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3.c

fts3_aux.o:	$(TOP)/ext/fts3/fts3_aux.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_aux.c

fts3_expr.o:	$(TOP)/ext/fts3/fts3_expr.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_expr.c

fts3_hash.o:	$(TOP)/ext/fts3/fts3_hash.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_hash.c

fts3_icu.o:	$(TOP)/ext/fts3/fts3_icu.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_icu.c

fts3_porter.o:	$(TOP)/ext/fts3/fts3_porter.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_porter.c

fts3_snippet.o:	$(TOP)/ext/fts3/fts3_snippet.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_snippet.c

fts3_tokenizer.o:	$(TOP)/ext/fts3/fts3_tokenizer.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_tokenizer.c

fts3_tokenizer1.o:	$(TOP)/ext/fts3/fts3_tokenizer1.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_tokenizer1.c

fts3_tokenize_vtab.o:	$(TOP)/ext/fts3/fts3_tokenize_vtab.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_tokenize_vtab.c

fts3_unicode.o:	$(TOP)/ext/fts3/fts3_unicode.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_unicode.c

fts3_unicode2.o:	$(TOP)/ext/fts3/fts3_unicode2.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_unicode2.c

fts3_write.o:	$(TOP)/ext/fts3/fts3_write.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/fts3/fts3_write.c

rtree.o:	$(TOP)/ext/rtree/rtree.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/rtree/rtree.c

userauth.o:	$(TOP)/ext/userauth/userauth.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/userauth/userauth.c

sqlite3session.o:	$(TOP)/ext/session/sqlite3session.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/session/sqlite3session.c

stmt.o:	$(TOP)/ext/misc/stmt.c $(DEPS_EXT_COMMON)
	$(T.cc.extension) -c $(TOP)/ext/misc/stmt.c

#
# Windows section
#
dll: sqlite3.dll
sqlite3.def: $(LIBOBJ)
	echo 'EXPORTS' >sqlite3.def
	nm $(LIBOBJ) | grep ' T ' | grep ' _sqlite3_' \
		| sed 's/^.* _//' >>sqlite3.def

sqlite3.dll: $(LIBOBJ) sqlite3.def
	$(T.cc.sqlite) $(LDFLAGS.shobj) -o $@ sqlite3.def \
		-Wl,"--strip-all" $(LIBOBJ)


# Remove build products sufficient so that subsequent makes will recompile
# everything from scratch.  Do not remove:
#
#   *   test results and test logs
#   *   output from ./configure
#
tidy-.:
tidy: tidy-.
	rm -f *.o *.c *.da *.bb *.bbg gmon.* *.rws sqlite3$(T.exe)
	rm -f fts5.h keywordhash.h opcodes.h sqlite3.h sqlite3ext.h sqlite3session.h
	rm -rf .libs .deps tsrc .target_source
	rm -f lemon$(B.exe) sqlite*.tar.gz
	rm -f mkkeywordhash$(B.exe) mksourceid$(B.exe)
	rm -f parse.* fts5parse.*
	rm -f $(libsqlite3.SO) $(libsqlite3.LIB) $(libtclsqlite3.SO)
	rm -f tclsqlite3$(T.exe) $(TESTPROGS)
	rm -f LogEst$(T.exe) fts3view$(T.exe) rollback-test$(T.exe) showdb$(T.exe)
	rm -f showjournal$(T.exe) showstat4$(T.exe) showwal$(T.exe) speedtest1$(T.exe)
	rm -f wordcount$(T.exe) changeset$(T.exe) version-info$(T.exe)
	rm -f *.exp *.vsix pkgIndex.tcl
	rm -f sqlite3_analyzer$(T.exe) sqlite3_rsync$(T.exe) sqlite3_expert$(T.exe)
	rm -f mptester$(T.exe) rbu$(T.exe)	srcck1$(T.exe)
	rm -f fuzzershell$(T.exe) fuzzcheck$(T.exe) sqldiff$(T.exe) dbhash$(T.exe)
	rm -f dbfuzz$(T.exe) dbfuzz2$(T.exe)
	rm -fr dbfuzz2-dir
	rm -f fuzzcheck-asan$(T.exe) fuzzcheck-ubsan$(T.exe) ossshell$(T.exe)
	rm -f scrub$(T.exe) showshm$(T.exe) sqlite3_checker$(T.exe) loadfts$(T.exe)
	rm -f index_usage$(T.exe) kvtest$(T.exe) startup$(T.exe) threadtest3$(T.exe)
	rm -f sessionfuzz$(T.exe) changesetfuzz$(T.exe)
	rm -f dbdump$(T.exe) dbtotxt$(T.exe) atrc$(T.exe)
	rm -f threadtest5$(T.exe)
	rm -f src-verify$(B.exe) has_tclsh* has_tclconfig
	rm -f tclsqlite3.c
	rm -f sqlite3rc.h sqlite3.def

#
# Removes build products and test logs.  Retains ./configure outputs.
#
clean-.:
clean:	clean-. tidy
	rm -rf omittest* testrunner* testdir*

# Clean up everything.  No exceptions.
distclean-.:
distclean:	distclean-. clean
