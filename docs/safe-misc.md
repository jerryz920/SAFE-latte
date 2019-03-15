# Miscellaneous features

## Dynamic script loading

SAFE allows a trust script to be loaded into an authorization server dynamically. A SAFE server reads the source code of a requested trust script, compiles it, and merges (with needed deduplication) the compiled SAFE constructs (logical templates and guards) into the script that the server currently runs.  SAFE includes two built-in guards for loading scripts: *import* and *importSource*. *import* requests the server to load a trust script specified by a pathname; *importSource* passes in source code via a request argument (a string).  Along with other guards defined in the start script, these loading guards are deployed on the server as REST APIs when SAFE stands up. The usage of import and importSource can be find from these two CURL requests and the server responses:

```
$ curl -H "Content-Type:application/json" -XPOST http://${ServerJVM}:7777/import -d  '{ "principal": "principal010", "methodParams": ["/path/to/safe/safe-apps/geni/fine-grained-linking/geni.slang"]}'

{
  "message": "Import completed"
}

$ curl -H "Content-Type:application/json" -XPOST http://${ServerJVM}:7777/importSource -d  '{ "principal": "principal010", "methodParams": ["defpost postObjectAcl(?ObjectId, ?Property) :- [addObjectAcl(?ObjectId, ?Property)]."]}'

{
  "message": "Import completed"
}
```

## inferSet()

Logical statement sets are immutable. SAFE introduces a built-in *inferSet()* in the scripting layer for automated deduction of statements based on an existing statement set and a user-defined rule set. This enables a number of useful applications, such as naming and *speaksFor*. It also allows compliance check over a dynamic list of properties and query optimization through Datalog materialization.  

Transformation of logic statement sets by inferSet() is dynamic, flexible, and efficient, but at no cost for a need to complicate the underlying logic. inferSet() has two parameters -- a reference to a statement set and a reference to a rule set. Both of them can refer to either a remote set or a local set in the SAFE instance cache. They together constitute a context for statement deduction. Below is an example use of inferSet() in STRONG naming.   At runtime, inferSet() invokes the logic inference engine to deduct all statements using the logical rules. The resulting statements are put in a newly created set whose reference is returned to the caller. Therefore, inferSet() does not make any change to the input logical sets (statement set and rule set), but only generates a result set containing all deducted statements.

```
...
?ScidSet := inferSet(?RulesRef, ?ObjDelToken),
...
```

Next: inferQuerySet()


## SAFE testing

SAFE's testing mainly covers four parts of the SAFE system: logical-layer parsing and inference, slang script-layer parsing and runtime, slang shell environment creation, persistence and restoration, and cross-JVM authorization with caching, retirement and updates to certificates.

[Logic] SAFE has an implementation of Datalog, but uses Styla as the default underlying logic engine. The set of [testing logical programs](../safe-styla/progs) by Styla are put under progs of safe-styla. SAFE also has a [weaver utility](path-to-be-added) that takes predicates, rules, and configuration parameters and generates Datalog programs with various logic chaining patterns such as chain length.

#### Run SAFE login engine against a Styla testing program (also for SAFE's own inference engine?)
```
cmd to be added
```

#### Run SAFE weaver utility to generate customized testing logic
```
cmd to be added
```

[Slang] Scripts under [safe-apps](../safe-apps) can be used to test slang parsing. We use [Strong](../safe-apps/strong) to test functionalities of Slang primitives, including defcon, defguard, defpost, defcall, defenv, and definit. 

#### Run Slang to parse a Slang script
```
cmd to be addded
```

#### Post a logical set using Strong and then check against SafeSets
```
\# post set

\# fetch from SafeSets and verify post
```

#### ToDo: testing the rest of Slang primitives


[Slang Shell] Slang shell builds an execution environment for a client and exposes defcalls for it to interact with remote SAFE servers. We documented a [Strong running example](../safe-apps/strong/example-with-slang-shell.txt)  with commands used to build an envrioment and execute queries. We use this for testing.

#### Run Slang shell and load a sequence of Strong commands per the Strong running example
```
CMDs to be segregated from the running example
```


[Integral benchmark involving multiple JVMs](../safe-benchmark) is conducted under coordination of a test harness. Under safe-benchmark directory, a ready-to-use SafeBench provides common functionalities needed for benchmarking a SAFE application. These reusable functions have implemented key loading and principal initialization, Id/subject set construction and posting, simple delegation and acceptance among principals, and cache testing via delegate-then-query and directing the query to a cold cache. It also interfaces with a slang performance collector to gather, order, compute, and persist performance statistics per a test harness.In the following, we use STRONG as an example to walk through a typcial process of SAFE testing.

A principal of STRONG uses a trusted SAFE server instance to publish statements, delegate access privileges, and guard its ImPACT data repositories. Testing of this multi-principal, multi-action, and multi-server identity, access, and trust management service is conducted under coordination of a test harness. The test harness is configured with location of each principal, keeps track of various delegation states in the system, and implements workloads to stress test interested SAFE components. For example, it builds delegation chains of varying length to evaluate how fast the logic engine solves queries and how it scales with chain length, navigates delegations to principals across server JVMs to create desired patterns that evaluate the efficiency of SafeSets linking and help identify performant linking patterns for ImPACT, and controls cache states and query directives to servers to examine how SAFE cache performs and how caching impacts overall performance in resolving queries. 


#### Set up SAFE servers and load each key pairs of principals who trust it
```
  Follow [safe-docker](safe-docker.md) or [safe-build](safe-build.md) to create key pairs and launch multiple SAFE server instances.
```

#### Create a principal-jvm map under resources to inform test harness the locations of principals
```
<key-dir> <jvm-addr>
```
An exmaple map:
```
/opt/multi-principal-keys-duke/     10.10.1.1:7777
/opt/multi-principal-keys-renci/    10.10.1.2:7777
/opt/multi-principal-keys-odum/     10.10.1.3:7777
```

#### Run test harness
```
sbt
project safe-benchmark
run -f ../safe-apps/strong/strong-client.slang  -jvmm src/main/resources/principal_jvm.map -c ${numConReqs}
```

#### Caveat: code needs to be cleaned up before these fully function. When it's done, this disclaimer will be gone.



## SAFE debugging: an exemplary logical proof

     ========================================== SAFE PROOF ========================================
    |                                                                                              |
    |                                                                                              |
    |        EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(sub20/sub1/sub2,Et29c        |
    |        7tSAdSffRNkk1J8R_96XM9SmhtoAV6ZO1Hbqko:object000001)                                  |
    |                  ||                                                                          |
    |                  || EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(?Name,?S        |
    |                  || cid) :- EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: splitLast(?N        |
    |                  || ame,?Init,?LastComponent), EK624CkV-eF-wcA6q0tz3DYy11MqgfI8Wbtenu        |
    |                  || ZVyJE: srnNameToID(?Init,?Dir), EK624CkV-eF-wcA6q0tz3DYy11MqgfI8W        |
    |                  || btenuZVyJE: is_nonnum(?DirAuthority,rootPrincipal(?Dir)), ?DirAut        |
    |                  || hority: nameObject(?LastComponent,?Scid,?Dir).                           |
    |                  ||                                                                          |
    |                  || sub20/sub1/sub2=>?Name;    Et29c7tSAdSffRNkk1J8R_96XM9SmhtoAV6ZO1        |
    |                  || Hbqko:object000001=>?Scid;    sub20/sub1=>?Init;    sub2=>?LastCo        |
    |                  || mponent                                                                  |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |        EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(sub20/sub1,bUo205gB8-        |
    |        MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001);    EK624CkV-eF-wcA6q0tz3DYy11        |
    |        MqgfI8WbtenuZVyJE: is_nonnum(bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g,rootP        |
    |        rincipal(bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001));    bUo205        |
    |        gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g: nameObject(sub2,Et29c7tSAdSffRNkk1J8R_9        |
    |        6XM9SmhtoAV6ZO1Hbqko:object000001,bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:        |
    |        object000001)                                                                         |
    |                  ||                                                                          |
    |                  || EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(?Name,?S        |
    |                  || cid) :- EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: splitLast(?N        |
    |                  || ame,?Init,?LastComponent), EK624CkV-eF-wcA6q0tz3DYy11MqgfI8Wbtenu        |
    |                  || ZVyJE: srnNameToID(?Init,?Dir), EK624CkV-eF-wcA6q0tz3DYy11MqgfI8W        |
    |                  || btenuZVyJE: is_nonnum(?DirAuthority,rootPrincipal(?Dir)), ?DirAut        |
    |                  || hority: nameObject(?LastComponent,?Scid,?Dir).                           |
    |                  ||                                                                          |
    |                  || sub20/sub1=>?Name;    bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g        |
    |                  || :object000001=>?Scid;    sub20=>?Init;    sub1=>?LastComponent           |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |        EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(sub20,lZfcr5mhhY7MKyu        |
    |        5uGauxzszdUFAupms2kwa-Ceb0ww:object000001);    EK624CkV-eF-wcA6q0tz3DYy11MqgfI        |
    |        8WbtenuZVyJE: is_nonnum(lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww,rootPrinci        |
    |        pal(lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:object000001));    lZfcr5mhhY7        |
    |        MKyu5uGauxzszdUFAupms2kwa-Ceb0ww: nameObject(sub1,bUo205gB8-MbFjQ7TYYDYuFLo8tq        |
    |        U2aUSrSLjeoq__g:object000001,lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:objec        |
    |        t000001);    EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: is_nonnum(bUo205gB8-        |
    |        MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g,rootPrincipal(bUo205gB8-MbFjQ7TYYDYuFLo8tqU2        |
    |        aUSrSLjeoq__g:object000001));    bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:         |
    |        nameObject(sub2,Et29c7tSAdSffRNkk1J8R_96XM9SmhtoAV6ZO1Hbqko:object000001,bUo20        |
    |        5gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001)                                  |
    |                  ||                                                                          |
    |                  || EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: srnNameToID(?Name,?S        |
    |                  || cid) :- EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: singleCompon        |
    |                  || ent(?Name), EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: is_nonnu        |
    |                  || m(?RootAuthority,rootPrincipal(_Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFN        |
    |                  || IzWiY87hM:root)), ?RootAuthority: nameObject(?Name,?Scid,_Multe5K        |
    |                  || Ngvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM:root).                               |
    |                  ||                                                                          |
    |                  || sub20=>?Name;    lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:obje        |
    |                  || ct000001=>?Scid;    _Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM=>        |
    |                  || ?RootAuthority                                                           |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |        _Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM: nameObject(sub20,lZfcr5mhhY7MKyu5        |
    |        uGauxzszdUFAupms2kwa-Ceb0ww:object000001,_Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzW        |
    |        iY87hM:root);    EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: is_nonnum(lZfcr5        |
    |        mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww,rootPrincipal(lZfcr5mhhY7MKyu5uGauxzszdU        |
    |        FAupms2kwa-Ceb0ww:object000001));    lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0        |
    |        ww: nameObject(sub1,bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001,l        |
    |        Zfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:object000001);    EK624CkV-eF-wcA6q        |
    |        0tz3DYy11MqgfI8WbtenuZVyJE: is_nonnum(bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq        |
    |        __g,rootPrincipal(bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001));         |
    |           bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g: nameObject(sub2,Et29c7tSAdSffR        |
    |        Nkk1J8R_96XM9SmhtoAV6ZO1Hbqko:object000001,bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrS        |
    |        Ljeoq__g:object000001)                                                                |
    |                  ||                                                                          |
    |                  || _Multe5KNgvw3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM: nameObject(sub20,lZf        |
    |                  || cr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:object000001,_Multe5KNgv        |
    |                  || w3Wk6eYF7_ZVXMXnKwxsTFNIzWiY87hM:root).                                  |
    |                  ||                                                                          |
    |                  || lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww:object000001=>?Dir;          |
    |                  ||   lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww=>?DirAuthority             |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |        lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww: nameObject(sub1,bUo205gB8-MbFjQ7T        |
    |        YYDYuFLo8tqU2aUSrSLjeoq__g:object000001,lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-C        |
    |        eb0ww:object000001);    EK624CkV-eF-wcA6q0tz3DYy11MqgfI8WbtenuZVyJE: is_nonnum        |
    |        (bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g,rootPrincipal(bUo205gB8-MbFjQ7TYY        |
    |        DYuFLo8tqU2aUSrSLjeoq__g:object000001));    bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSr        |
    |        SLjeoq__g: nameObject(sub2,Et29c7tSAdSffRNkk1J8R_96XM9SmhtoAV6ZO1Hbqko:object0        |
    |        00001,bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001)                       |
    |                  ||                                                                          |
    |                  || lZfcr5mhhY7MKyu5uGauxzszdUFAupms2kwa-Ceb0ww: nameObject(sub1,bUo2        |
    |                  || 05gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001,lZfcr5mhhY7M        |
    |                  || Kyu5uGauxzszdUFAupms2kwa-Ceb0ww:object000001).                           |
    |                  ||                                                                          |
    |                  || bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001=>?Dir;          |
    |                  ||   bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g=>?DirAuthority             |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |        bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g: nameObject(sub2,Et29c7tSAdSffRNkk        |
    |        1J8R_96XM9SmhtoAV6ZO1Hbqko:object000001,bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLje        |
    |        oq__g:object000001)                                                                   |
    |                  ||                                                                          |
    |                  || bUo205gB8-MbFjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g: nameObject(sub2,Et29        |
    |                  || c7tSAdSffRNkk1J8R_96XM9SmhtoAV6ZO1Hbqko:object000001,bUo205gB8-Mb        |
    |                  || FjQ7TYYDYuFLo8tqU2aUSrSLjeoq__g:object000001).                           |
    |                  ||                                                                          |
    |                 \||/                                                                         |
    |                  \/                                                                          |
    |                                                                                              |
    |                  {}                                                                          |
    |                                                                                              |
     ========================================= END OF PROOF =======================================
