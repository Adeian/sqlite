/*
** 2024-09-23
**
** The author disclaims copyright to this source code.  In place of
** a legal notice, here is a blessing:
**
**    May you do good and not evil.
**    May you find forgiveness for yourself and forgive others.
**    May you share freely, never taking more than you give.
**
*************************************************************************
**
** This app's single purpose is to emit parts of the Makefile code for
** building sqlite3's WASM build. The main motivation is to generate
** code which "can" be created via GNU Make's eval command but is
** highly illegible when built that way. Attempts to write this app in
** Bash and TCL have failed because both require escaping $ symbols,
** making the resulting script code as illegible as the eval spaghetti
** we want to get away from. Writing it in C is, somewhat
** surprisingly, _slightly_ less illegible than writing it in bash,
** tcl, or native Make code.
**
** The emitted makefile code is not standalone - it depends on
** variables and $(call)able functions from the main makefile.
**
*/

#undef NDEBUG
#define DEBUG 1
#include <assert.h>
#include <stdio.h>
#include <string.h>

#define pf printf
#define ps puts
/* Very common printf() args combo. */
#define zNM zName, zMode

/*
** Valid names for the zName arguments.
*/
#define JS_BUILD_NAMES sqlite3 sqlite3-wasmfs
/*
** Valid names for the zMode arguments.
*/
#define JS_BUILD_MODES vanilla esm bundler-friendly node

/*
** Emits common vars needed by the rest of the emitted code (but not
** needed by code outside of these generated pieces).
*/
static void mk_prologue(void){
  ps("########################################################################");
  ps("# extern-post-js* and extern-pre-js* are files for use with");
  ps("# Emscripten's --extern-pre-js and --extern-post-js flags.");
  ps("extern-pre-js.js := $(dir.api)/extern-pre-js.js");
  ps("extern-post-js.js.in := $(dir.api)/extern-post-js.c-pp.js");
  ps("# Emscripten flags for --[extern-][pre|post]-js=... for the");
  ps("# various builds.");
  ps("pre-post-common.flags := --extern-pre-js=$(sqlite3-license-version.js)");
  ps("# pre-post-jses.deps.* = a list of dependencies for the");
  ps("# --[extern-][pre/post]-js files.");
  ps("pre-post-jses.deps.common := $(extern-pre-js.js) $(sqlite3-license-version.js)");
}

/*
** Emits makefile code for setting up values for the --pre-js=FILE,
** --post-js=FILE, and --extern-post-js=FILE emcc flags, as well as
** populating those files.
*/
static void mk_pre_post(const char *zName, const char *zMode){
  pf("pre-post-%s-%s.flags ?=\n", zNM);

  /* --pre-js=... */
  pf("pre-js.js.%s-%s.intermediary := $(dir.tmp)/pre-js.%s-%s.intermediary.js\n",
     zNM, zNM);
  pf("pre-js.js.%s-%s := $(dir.tmp)/pre-js.%s-%s.js\n",
     zNM, zNM);
  pf("$(eval $(call C-PP.FILTER,$(pre-js.js.in),$(pre-js.js.%s-%s.intermediary),"
     "$(c-pp.D.%s-%s)))\n", zNM, zNM);

  /* --post-js=... */
  pf("post-js.js.%s-%s := $(dir.tmp)/post-js.%s-%s.js\n", zNM, zNM);
  pf("$(eval $(call C-PP.FILTER,$(post-js.js.in),"
     "$(post-js.js.%s-%s),$(c-pp.D.%s-%s)))\n", zNM, zNM);

  /* --extern-post-js=... */
  pf("extern-post-js.js.%s-%s := $(dir.tmp)/extern-post-js.%s-%s.js\n", zNM, zNM);
  pf("$(eval $(call C-PP.FILTER,$(extern-post-js.js.in),$(extern-post-js.js.%s-%s),"
     "$(c-pp.D.%s-%s)))\n", zNM, zNM);

  /* Combine flags for use with emcc... */
  pf("pre-post-common.flags.%s-%s := "
     "$(pre-post-common.flags) "
     "--post-js=$(post-js.js.%s-%s) "
     "--extern-post-js=$(extern-post-js.js.%s-%s)\n", zNM, zNM, zNM);

  pf("pre-post-%s-%s.flags += $(pre-post-common.flags.%s-%s) "
     "--pre-js=$(pre-js.js.%s-%s)\n", zNM, zNM, zNM);

  pf("$(pre-js.js.%s-%s): $(pre-js.js.%s-%s.intermediary) $(MAKEFILE)\n",
     zNM, zNM);
  pf("\tcp $(pre-js.js.%s-%s.intermediary) $@\n", zNM);
  /* Amend $(pre-js.js.zName-zMode) for all targets except the plain
     "sqlite3" build... */
  if( 0==strcmp("sqlite3-wasmfs", zName) ){
    pf("\t@echo 'delete Module[xNameOfInstantiateWasm]; /"
       "* for %s build *" "/' >> $@\n", zName);
  }else if( 0!=strcmp("sqlite3", zName) ){
    pf("\t@echo 'Module[xNameOfInstantiateWasm].uri = \"$(1).wasm\";' >> $@\n");
  }

  /* Set up deps... */
  pf("pre-post-jses.%s-%s.deps := $(pre-post-jses.deps.common) "
     "$(post-js.js.%s-%s) $(extern-post-js.js.%s-%s)\n",
     zNM, zNM, zNM);
  pf("pre-post-%s-%s.deps := $(pre-post-jses.%s-%s.deps) $(dir.tmp)/pre-js.%s-%s.js\n",
     zNM, zNM, zNM);
}

/*
** Emits makefile code for one build of the library, primarily defined
** by the combination of zName and zMode, each of which must be values
** from JS_BUILD_NAMES resp. JS_BUILD_MODES.
*/
static void mk_lib_mode(const char *zName     /* build name */,
                        const char *zMode     /* build mode */,
                        int bIsEsm            /* true only for ESM build */,
                        const char *zApiJsOut /* name of generated sqlite3-api.js/.mjs */,
                        const char *zJsOut    /* name of generated sqlite3.js/.mjs */,
                        const char *zCmppD    /* extra -D flags for c-pp */,
                        const char *zEmcc     /* extra flags for emcc */){
  assert( zName );
  assert( zMode );
  assert( zApiJsOut );
  assert( zJsOut );
  if( !zCmppD ) zCmppD = "";
  if( !zEmcc ) zEmcc = "";

  pf("#################### begin build [%s-%s]\n", zNM);
  pf("$(info Setting up build [%s-%s]: %s)\n", zNM, zJsOut);
  pf("c-pp.D.%s-%s := %s\n", zNM, zCmppD);
  mk_pre_post(zNM);
  pf("emcc.flags.%s.%s ?=\n", zNM);
  if( zEmcc[0] ){
    pf("emcc.flags.%s.%s += %s\n", zNM, zEmcc);
  }
  pf("$(eval $(call C-PP.FILTER, $(sqlite3-api.js.in), %s, %s))\n",
     zApiJsOut, zCmppD);

  /* target zJsOut */
  pf("%s: %s $(MAKEFILE) $(sqlite3-wasm.cfiles) $(EXPORTED_FUNCTIONS.api) "
     "$(pre-post-%s-%s.deps)\n",
     zJsOut, zApiJsOut, zNM);
  pf("\t@echo \"Building $@ ...\"\n");
  pf("\t$(emcc.bin) -o $@ $(emcc_opt_full) $(emcc.flags) \\\n");
  pf("\t\t$(emcc.jsflags) -sENVIRONMENT=$(emcc.environment.%s) \\\n", zMode);
  pf("\t\t$(pre-post-%s-%s.flags) \\\n", zNM);
  pf("\t\t$(emcc.flags.%s) $(emcc.flags.%s.%s) \\\n", zName, zNM);
  pf("\t\t$(cflags.common) $(SQLITE_OPT) \\\n"
     "\t\t$(cflags.%s) $(cflags.%s.%s) \\\n"
     "\t\t$(cflags.wasm_extra_init) $(sqlite3-wasm.cfiles)\n", zName, zNM);
  if( bIsEsm ){
    /* TODO? Replace this CALL with the corresponding makefile code.
    ** OTOH, we also use this $(call) in the speedtest1-wasmfs build,
    ** which is not part of the rules emitted by this program. */
    pf("\t@$(call SQLITE3.xJS.ESM-EXPORT-DEFAULT,1,%d)\n",
       0==strcmp("sqlite3-wasmfs", zName) ? 1 : 0);
  }
  pf("\t@dotwasm=$(basename $@).wasm; \\\n"
     "\tchmod -x $$dotwasm; \\\n"
     "\t$(maybe-wasm-strip) $$dotwasm; \\\n");
  /*
  ** The above $(emcc.bin) call will write zJsOut and will create a
  ** like-named .wasm file. That .wasm file name gets hard-coded into
  ** zJsOut so we need to, for some cases, patch zJsOut to use the
  ** name sqlite3.wasm instead. Note that the resulting .wasm file is
  ** identical for all builds for which zEmcc is empty.
  */
  if( 0==strcmp("bundler-friendly", zMode)
      || 0==strcmp("node", zMode) ) {
    pf("\techo 'Patching $@ for %s.wasm...' \\\n", zName);
    pf("\trm -f $$dotwasm; dotwasm=; \\\n"
       "\tsed -i -e 's/%s-%s.wasm/%s.wasm/g' $@ || exit $$?; \\\n",
       zNM, zName);
  }
  pf("\tls -la $$dotwasm $@\n");
  if( 0!=strcmp("sqlite3-wasmfs", zName) ){
    /* The sqlite3-wasmfs build is optional and needs to be invoked
    ** conditionally using info we don't have here. */
    pf("all: %s\n", zJsOut);
  }
  pf("#################### end build [%s-%s]\n\n", zNM);
}

int main(void){
  int rc = 0;
  pf("# What follows was GENERATED by %s. Edit at your own risk.\n", __FILE__);
  mk_prologue();
  mk_lib_mode("sqlite3", "vanilla", 0,
              "$(sqlite3-api.js)", "$(sqlite3.js)", 0, 0);
  mk_lib_mode("sqlite3", "esm", 1,
              "$(sqlite3-api.mjs)", "$(sqlite3.mjs)",
              "-Dtarget=es6-module", 0);
  mk_lib_mode("sqlite3", "bundler-friendly", 1,
              "$(sqlite3-api-bundler-friendly.mjs)", "$(sqlite3-bundler-friendly.mjs)",
              "$(c-pp.D.sqlite3-esm) -Dtarget=es6-bundler-friendly", 0);
  mk_lib_mode("sqlite3" , "node", 1,
              "$(sqlite3-api-node.mjs)", "$(sqlite3-node.mjs)",
              "$(c-pp.D.sqlite3-bundler-friendly) -Dtarget=node", 0);
  mk_lib_mode("sqlite3-wasmfs", "esm" ,1,
              "$(sqlite3-api-wasmfs.mjs)", "$(sqlite3-wasmfs.mjs)",
              "$(c-pp.D.sqlite3-bundler-friendly) -Dwasmfs",
              "-sEXPORT_ES6 -sUSE_ES6_IMPORT_META");
  return rc;
}
