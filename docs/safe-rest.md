# Interacting with a SAFE server using REST

Each method defined in a SAFE server script via `defpost` or `defguard` is automatically exposed as a REST call, which can be invoked via a simple curl command. This document describes the process.

Assume your SAFE server script looks as below.

```
defcon makeMyIdentitySet(?CN) :-
  spec('Construct an identity set for self'),
  {
    principal($SelfKey) :- spec("identity set for $CN").
  }.

defpost postRawIdSet(?CN) :- [makeMyIdentitySet(?CN)].
```
If you are using slang shell, you would also have the slang shell script as follows:
```
defcall postRawIdSet(?CN) :-
  {
    postRawIdSet($ServerJVM, $ReqEnvs, $CN).
}.
```

In this example `postRawIdSet` is a common SAFE function that allows a principal to post their identity to SafeSets (Riak). The safe server running the script is presumed to have access to a directory (in this case ~/principalkeys) containing public/private keys of the principals, generated using e.g. [this script](../utility/safe_keygen.sh) - in this case the keys are `strong-1.pub`, `strong-1.key`.

Typically the invocation via slang-shell may look like this:
```
slang> import("~/my-slang-client-script.slang").
slang> ?KD := "~/principalkeys".
slang> ?Principal := getIdFromPub("$KD/strong-1.pub").
slang> ?Self := $Principal.
slang> ?ServerJVM := "localhost:7777".
slang> ?P1 := postRawIdSet("strong-1").
```
The last shell command would typically produce an output like this
```
"['wrZvIM4CYb9jvBS_4gJ0VIUVXJQYrc0yrEmveTod5Hk=']"
```

To use curl you do *not* need to have the slang client script. You can interact with the SAFE server directly as follows:
```
$ export SAFE_HOST=localhost
$ export SAFE_PORT=7777
$ curl  http://$SAFE_HOST:$SAFE_PORT/postRawIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"strong-1\", \"methodParams\": [\"strong-1\"] }"  
```
which produces an output similar to the follows:
```
{
 "result": "succeed"
 "message" : "['wrZvIM4CYb9jvBS_4gJ0VIUVXJQYrc0yrEmveTod5Hk=']"
}
```

You can use `jq` command to parse the JSON return values as follows:
```
$ curl  http://$SAFE_HOST:$SAFE_PORT/postRawIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"strong-1\", \"methodParams\": [\"strong-1\"] }"  | jq ".result, .message"
```

If we look at the curl invocation, the structure becomes clear:

- The URL must include the name of the method being invoked
- There are two mandatory parameters: `principal` and `methodParams`
  - `principal` refers to the name of the key of the principal making the assertion. The key must be accessible to the SAFE server.
  - `methodParams` is a JSON-formatted array of strings passing method parameters, in the same order they are listed in the script. SAFE is typeless, so no other parameter information is necessary.

In this example there is a single parameter, which is the principal itself (referred to by its key name). Other parameters can be joined using commas, and making sure they are surrounded by escaped double quotes:

```
$ curl  http://$SAFE_HOST:$SAFE_PORT/postRawIdSet -H "Content-Type: application/json" -d "{ \"principal\": \"strong-1\", \"methodParams\": [\"param1\", \"param2\", \"param3\" ] }"
```

Queries on defguards using curl are similar. They produce a more verbose output message, like e.g. a successful query below:
```
{
  "result" : "succeed"
  "message" : "{ 'BjDPqyYcbTxX__VvRAG8fI3YT7M3eoQJuBjQMJuXhyo=':grantAccess('wrZvIM4CYb9jvBS_4gJ0VIUVXJQYrc0yrEmveTod5Hk=','wrZvIM4CYb9jvBS_4gJ0VIUVXJQYrc0yrEmveTod5Hk=:26dbc728-3c8d-4433-9c4b-2e065b644db5',someUser,'9QbzxpBeorl7MyPRY5JkHj38Xmzs6tssAXbdP5F2-0c=',someProject) }"
}
```

or a failed query:
```
{
  "result": "fail"
  "message" : "Query failed with msg: java.lang.RuntimeException: Unsatisfied queries: List(access('wrZvIM4CYb9jvBS_4gJ0VIUVXJQYrc0yrEmveTod5Hk=:26dbc728-3c8d-4433-9c4b-2e065b644db5', 'someUser', '9QbzxpBeorl7MyPRY5JkHj38Xmzs6tssAXbdP5F2-0c=', 'someProject')?)  List()"
}
```
