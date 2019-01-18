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
