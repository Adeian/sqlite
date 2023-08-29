import {default as ns} from './SQLTester.mjs';

globalThis.sqlite3 = ns.sqlite3;
const log = function f(...args){
  console.log('SQLTester.run:',...args);
  return f;
};

const out = function f(...args){ return f.outer.out(...args) };
out.outer = new ns.Outer();
out.outer.getOutputPrefix = ()=>'SQLTester.run: ';
const outln = (...args)=>{ return out.outer.outln(...args) };

const affirm = function(expr, msg){
  if( !expr ){
    throw new Error(arguments[1]
                    ? ("Assertion failed: "+arguments[1])
                    : "Assertion failed");
  }
}

console.log("Loaded",ns);

log("ns =",ns);
outln("SQLTester is ready.");

let ts = new ns.TestScript('/foo.test',`
--print Hello, world.
--close all
--oom
--db 0
--new my.db
--null zilch
--testcase 1.0
SELECT 1, null;
--result 1 zilch
--glob *zil*
--notglob *ZIL*
SELECT 1, 2;
intentional error;
--run
--testcase json-1
SELECT json_array(1,2,3)
--json [1,2,3]
--testcase tableresult-1
  select 1, 'a';
  select 2, 'b';
--tableresult
  # [a-z]
  2 b
--end
--testcase json-block-1
  select json_array(1,2,3);
  select json_object('a',1,'b',2);
--json-block
  [1,2,3]
  {"a":1,"b":2}
--end
--testcase col-names-on
--column-names 1
  select 1 as 'a', 2 as 'b';
--result a 1 b 2
--testcase col-names-off
--column-names 0
  select 1 as 'a', 2 as 'b';
--result 1 2
--close
--print Until next time
`);

const sqt = new ns.SQLTester();
try{
  affirm( !sqt.getCurrentDb(), 'sqt.getCurrentDb()' );
  sqt.openDb('/foo.db', true);
  affirm( !!sqt.getCurrentDb(),'sqt.getCurrentDb()' );
  sqt.verbosity(0);
  if(false){
    affirm( 'zilch' !== sqt.nullValue() );
    ts.run(sqt);
    affirm( 'zilch' === sqt.nullValue() );
  }
  sqt.addTestScript(ts);
  sqt.runTests();
}finally{
  sqt.reset();
}
log( 'sqt.getCurrentDb()', sqt.getCurrentDb() );
log( "Metrics:", sqt.metrics );

