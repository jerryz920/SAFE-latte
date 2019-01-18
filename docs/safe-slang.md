# SAFE scripting language (Slang)

## Basic syntax

## Built-ins

* ? identifies a variable local to a logic rule or a def construct. For pure datalog, one can omit "?" for rule-local variables, but the first character of the variable name still needs to be capitalized.

* The usage of $ is the same as how is used in bash. It identifies a reference to an env variable.

* In slang, a parameterized datalog program, i.e., an ensemble of parameterized statements and/or rules, is often embedded in the body of a def construct (in between a pair of curly braces). When a logic rule/statement is nested into a def construct in this way, the def construct provides an additional environment to the rule/statement. Therefore, a $-prefixed variable in the rule/statement can refer to a variable local to the containing def construct.  Since such a variable can also refer to a global environmental variable, developers use names to differentiate a def variable and a global env variable.

* ~ identifies a template for retracting a statement. Retraction statements are useful, for example, to clean up attestation of a principal when the principal reaches the end of its lifecycle.

* $Self is a system environment variable in slang, similar to $PATH in linux. Selfie() is a slang built-in for setting $Self using a key pair. It's invoked when the trust script is loaded and at that time it sets $Self automatically. It's per-connection. Again, it's like $PATH in linux. And a connection/query request in slang is like a request to open a terminal in Linux. It will first inherit the existing value of $Self and overwrite $Self if the request comes with an intended principal (indicated by the principal field in the REST call). The execution of the handler of every request uses a brand new $Self. This is similar to Linux terminals where each terminal has its own copy of $PATH.

* datalog is based on substitution of strings. These constants are interpreted as strings.  1, '1', "1" are the same thing. when you pass one of these to an arithmetic operator, the operation treats them as integers.
It does not have a strict type system.
string is the basic type. and a string can be converted to another required type based on the semantics of built-in operators.

* This comes by the design of definit.
definit will be invoked on any new server principal
it is to initialize the context for a principal and will be invoked automatically on any new principal.

## Common idioms

| Syntax | Semantics | Example | Description |
|--------|-----------|---------|-------------|
| : | says | Bob:coworker(Charlie). | Bob says(signs) Charlie as his coworker |
| := | assignment | ?Value := +(2, 4). | Evaluates the right expression and assigns the value to left variable | 
| ~ | statement suffix denoting a retraction | Bob:coworker(Charlie)~ | Bob retracts Charlie from his coworker’s list. |
| ? | prefix of a named variable or suffix of a statement denoting a query | Bob:coworker(?Who)? | Bob queries for his coworkers list. |
| _ | anonymous variable | Bob:coworker(_)? | Bob queries for his coworkers list. |
| $ | environment variable or a bounded variable passed from slang to the logic engine | ?Who:coworker($Self)? | List the speakers who said I am their coworker. |
| " " | string interpolation | "My identity is $Self" | Interpolates the string by substituting the variable ?Self with a bounded value in scope. |
|r" " | regular expression | coworker(r"^C.*?")? | List all coworkers starting with letter C |
| { } | mutable set of logic statements with a name | 'Bob/coworkers' {Bob:coworker(Charlie).} | A credential with a local name as 'Bob/coworkers' in Bob's namespace |
| {{ }} | immutable set of logic statements with a derived name | {{ [application/pdf] 0xcafe96f6e2f42}} | A content object with the name derived as hash of its set contents | 
| def* | define rule as a function | defenv EFF :- 'const'. | $EFF will resolve to a constant value string | 

Slang provides some builtin functional features for rules prefixed with keyword tags `defenv` for initializing environment variables; `defcon` for set construction; and `defguard` for externally visible entry points to the slang program for authorizing incoming requests.

Slang rules tagged with `defun` may include embedded native Scala code, which is compiled on-the-fly during load (or reload). This feature allows seamless interoperability with the host language and uses its libraries for implementing
complex functions. For example, the builtins in the slang library for string interpolation, regular expressions, crypto operations, and networking are implemented using `defun` and native scala code.

The function arguments are passed through the native Scala code enclosed in
`` ` ` `` as string arguments similar to invoking the main(args: Array[String]) function. Within the Scala code, the slang variables are accessed with the prefix $ instead of ? since all the variables are bound before invoking the native code. Following Scala conventions, the last expression is the return value of the function call, which is transformed into a constant atom in slang.
Example:
```
  defun times(?X, ?Y) :-
    spec('multiply ?X and ?Y and return the value'),
    `
       $X.toInt * $Y.toInt
    `
end
```

`definit` is invoked when a slang program is initially loaded. It invokes all the goals specified in its declaration.
```
  definit ?X := times(2, 4), times(?X, 8).
  // Results in evaluating the goal terms giving us the
  // result 8, 32 respectively.
```

`defenv` initializes environment variables via late binding, i.e., at the first reference to the variable. The environment variables declared through defenv are globally scoped but may be shadowed by the lexically scoped variables defined in rules with local scope.

Example:
```
  (* Selfie initializes $Self and $SelfKey, the hash of the public key
   * and the public key value respectively.
   *)
  defenv Selfie :-
    spec('load the key pair for the issuer'),
    principal('issuer_keyPair.pem')
end
```
In general, the issuer/authorizer’s keypairs are declared as environment variables by initializing the variable Selfie. Selfie initializes Self and SelfKey, which contains the identity/fingerprint of the issuer/authorizer and public key respectively. The builtin variables in slang are described in the following table:

| Variable Name | Description | 
|------|-----|
|?Self | hash of the issuer’s public key |
| ?Selfie | issuer’s key pair |
| ?SelfKey | issuer’s public key |
| ?Subject | hash of the requester’s public key |
| ?Speaker | hash of the server proxy (principal) that is making a request on the behalf of the subject (end-user) principal |
| ?Object | object IID for which the access is requested | 
| ?BearerRef | set identifier passed by the requester |

A `defcon` rule creates or modifies a named slogset and returns its value—a set constructor. These rules should end with a set of slog statements enclosed in name{}, where name is the local name (label) of the slogset assigned by its issuer. The constructed slogset is materialized as a certificate upon a subsequent export, e.g., a post to SafeSets.
The slogset statements may contain some predefined predicates such as link/1, subject/2, issuer/3, validity/3, signatureAlgorithm/1, which are metapredicates that are interpreted by slang for encoding slogsets as certificates. In particular, link is useful to reference another logic set. 

Example:
```
  defenv Charlie :- 'hash-of-Charlie-PK'.
  defcon makeSlogSet() :-
    spec('create a simple set with a local name coworker'),
    "endorse/$Charlie"{ // the local name of this slogset 'endorse/Charlie'
       endorse("$Charlie", coworker).
       mkLink("controls/coworker-group").
    }
end
```

A `defguard` rule is where the guard queries are defined and access-check operations are performed. The rule imports the assembled proof context for each query through the import predicate, which takes a set reference as an argument, and performs certified evaluation through slog.
Example:
```
  defguard authorizer(?Subject, ?Object, ?Priv) :-
    spec('guard to check the authorization access for the subject'),
    ?Controller := rootID(?Object),
    ?ProofContext := fetch("?Controller:controls/?Object"),
  {
     import("$ProofContext").
     grant($Subject, $Object, $Priv)?
  }
end
```
In addition, the defguard rule acts as an external entry point to the slang program, invoked via a REST API to check policy compliance (e.g., for an application-level request) when the slang interpreter is configured to run as a service. 

## Queries

Guards (defguard) in Slang carry logical queries through which SAFE applications request to perform compliance check before approving an authorization.  These queries are written in standard Datalog and are evaluated against the proof context specified in a guard. The two exemplary queries below check the source IP address of a request, and the membership of a requesting principal, respectively.    

```
TrustedIPAddress($IP)?
membership($G, $P)?
```

In SAFE, an authorization decision can be made based on the results of multiple queries. Applications can easily realize this by putting multiple queries into a guard (defguard). SAFE has made an extension to the Datalog query interface to handle multi-type, multi-number queries. Similar to AWS IAM, it supports three types of queries, i.e., *require*, *allow*, and *deny*, for authorizing or denying requests, depending on the application contexts. A guard (defguard) can contain queries of one and more types, with one or more queries for each type. *require* queries implement conjunction: an authorization can be granted if every such query returns *true*; *allow* queries implement disjunction: an authorization can be granted if any such query returns *true*; *deny* queries implement negation: a request is denied if any such query returns *true*. Below are a few examples of annotated queries in SAFE. *=@=* identifies the type of a query. By default, SAFE queries are *allow* queries and the annotation of the queries can be omitted.  

```
haveAccessForTag(t0)? =@= require
haveAcesssForTag(t1)? =@= require
haveAccessToDir("path/to/dir")? =@= allow
denyAccessToFile("path/to/dir/f0")? =@= deny
```
