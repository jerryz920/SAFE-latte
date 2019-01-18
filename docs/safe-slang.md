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

## Context-layer Functions

Slang provides several useful functions as a standard library to operate directly on slogsets. These functions include aggregate functions such as length(), max(), min(); parse functions operating on a safeset such as getName(), getSpeaker(), getSubject(), verifySignature(); functions to compute hash and load/generate keypairs; and support of speaksFor delegation. 

| Function Name | Description |
|------|-----|
| parseCertificate(?Certificate) | parse a certificate to an internal representation and return a reference |
| getName(?CertificateRef) | get the slogset name on the certificate |
| getIssuer(?CertificateRef) | get the issuer’s ID on the certificate |
| getSubject(?CertificateRef) | get the subject’s ID on the certificate |
| verifySignature(?CertificateRef) | verify the signature on the certificate |
| getID(?SubjectID, ?Name) | get the slogset identifier with issuer as subject id and local name as name |
| mkLink(?Name) | get the slogset identifier with issuer as Self and local name as name |
| import(?Name) | import the slogsets into the current proof context |
| iName() | generate a self-certifying name; used for as- signing names to objects |
| rootID(?IID) | extract the root ID of the self-certifying identifier, i.e., the ID of the principal which assigns the name to the object represented by this IID |
| fetch(?BearerRef) | fetch a transitive closure of slogset ref by traversing all the links |
| fetchSRN(?SetRef, ?SRN) | fetch a transitive closure of logic set reference by traversing the links as guided by the safe resource name (SRN) | 
| post(?SlogSetRef) | post the set contents referenced by ?SlogSetRef and return the certificate reference |
| for(?A, ?B, ?PC) | verify whether the subject A speaksFor the subject B given the proof context reference PC |

## Policies

Slang provides a set of common policy templates via libraries that are useful to issue certificates and write guard queries. Policy APIs for slang specified in Scala. These APIs are implemented as trust-logic functional rules in slang.

| API | Description | 
|-----|------|
| endorse(entity:  IName, attr:  Symbol):  IName | endorse an entity by asserting an attribute |
| endorseWithValue(entity: IName, attrName:  Symbol, attrValue:  Symbol):  IName | endorse an entity by asserting an attribute name-value pair |
| delegate(subject:  ID): IName | issue delegation to subject via ‘speaksFor’ |
| grantCap(subject:  ID, object:  IName, priv: Symbol):  IName | grant a capability for a subject on an object |
| grantCapByPrefix(subject:ID, prefix:  IName, priv:Symbol):  IName |  grant a capability for a subject on all objects matching a prefix 
| delegateCap(subject:ID, object:  SCN, priv:Symbol):  IName | grant a delegatable capability for a subject on an object |
| delegateCapByPrefix(subject:ID, object:  SCN, priv: Symbol):  IName | grant a delegatable capability for a subject on all objects matching a prefix |
| createGroup():  IName | create a group and return the self-certifying name that identifies the group |
| createObject():  IName | create an object and return the self-certifying name that identifies the object |
| createRole(roleName:Symbol, subject:  ID,slogSetRef:  IName):  IName | create a role for the subject and assign the creden- tials via ‘slogSetRef’ |
| grantMembership(subject:ID, group:  IName):  IName | grant membership for a subject in the group |
| attachSubGroup(targetGroup:IName, parentGroup:  SCN):IName | grant membership for ‘targetGroup’ in ‘parentGroup’ upon which the ‘targetGroup’ becomes a subset of ‘parentGroup’. The caller must control ‘parentGroup’.| 
| resolveName(pathName:SRN): ID | resolve a multicomponent pathname, which may cross domain boundaries |
| attachPolicy(policy:Policy, object:  IName): IName | attach a policy to an object; the caller must control the object |
| attachCredential(credential:Credential, object: IName):  IName | attach a credential to an object; the caller must control the object |
| attachGroup(group:  IName, object:  IName):  IName | attach a group to an object; the caller must control the object |
| attach(slogSetRef:  IName, object:  IName):  IName | attach a slogset to an object; the caller must control the object|
| checkAccessCap(subject:ID, object:  IName, priv:  Symbol, slogSetRef: Option[ID]): Boolean | check access capability ‘priv’ for a subject on an object. The subject may optionally provide the slogset reference set. |

An endorsement set is identified by its issuer and an entity for which the endorsement is issued. Issuing an endorsement asserts the subject attributes. Below snippets show the slang templates for endorsement set.
```
defcon endorse(?Entity, ?Attr) :-
  spec('endorse an entity ?Entity as ?Attr'),
  ''endorse/$Entity''{
     endorse($Entity, $Attr).
  }
end
```

```
defcon endorseWithValue(?Entity, ?AttrName, ?AttrValue) :-
  spec('endorse an entity ?Entity as ?AttrName and ?AttrValue'),
  ''endorse/$Entity''{
    endorse($Entity, $AttrName, $AttrValue).
    }
end
```
Instead of directly issuing the endorsements, the issuer can assert a rule for an attribute-based delegation from a trusted entity.
```
defcon endorseByDelegation(?TrustedRoot) :-
  spec('delegate authority on an attribute to a trustedRoot'),
  ''endorse/delegate/$Attr''{
    endorse(?Entity, ?Attr) :-
    endorse(?Delegator, $TrustedRoot),
    ?Delegator: endorse(?Entity, ?Attr).
  }
end
```

A delegation set is identified by an issuer and a subject. A delegation set may grant unrestricted authority via speaksFor. Code Snippet shows the slang template for delegation set.
```
defcon delegate(?Subject) :-
  spec('delegate authority to a subject'),
  ''delegate/$Subject''{
    speaksFor($Subject, $Self).
  }
end
```

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
