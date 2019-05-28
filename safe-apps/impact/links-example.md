
#

## What is SAFE?
SAFE is a platform for participants to issue certificates, link them to other certificates issued by other principals, and check validity of collections of certificates against various security policies.   In another aspect SAFE is a secure dynamic linking system for multi-principal logic programs.   The relationship between these two aspects is that SAFE encodes certificate content and policies in an expressive logic language, such that their union forms a logic program from which SAFE's standard logic engine can prove compliance.


Loosely, a *principal* corresponds to a *keypair*.  More precisely, principals (identities) in a networked system may have keypairs, so we can presume for now that each principal owns exactly one keypair.  SAFE principals (or their programs) issue *logical certificates* signed under their keypairs.  Each SAFE certificate contains a set of one or more statements in a trust logic, so we often refer to them as *logic sets*.  

SAFE checks compliance with security policies by evaluating collections of certificates: it takes the union of logic sets in the collection, merges the statements to form a single logic program, and issues one or more logical queries against it.  The content of the certificate collection forms the *context* for the query.


For example, a data server might pass a collection of certificates to the SAFE engine and ask it: *``Do the authenticated logic statements in these certificates allow me to prove that the subject qualifies for access to the requested data set according to my policy?''*  


To enable users to form certificate collections, SAFE stores certificates in a shared key-value store (Riak).  SAFE provides functions to link certificates securely and to fetch and cache linked certificates automatically.   Each stored certificate has a unique certified index key, called a *token*.  Given the token, anyone can link or retrieve the certificate. 

We use the same logic language to label the certificates with string names and to construct  links among labeled logic sets.   If you know a certificate's string label and the principal that issued it, then you can ``synthesize'' its token.


Since SAFE defines a standard format for logical certificates, we need only to standardize the logic content and linking structures for each application.  We represent the logic standards using a logic-based scripting language---called *slang*---with embedded templates for the actual logic content, including links and labels.   We use slang to implement compact trust scripts that specify the content and also serve directly as the implementation.

It's a powerful way to think about trust, and a powerful platform to build trust infrastructure.  But it is unfamiliar and it's a lot to digest.  The `links` scripts provide a simple example to illustrate some key concepts and features of SAFE and slang---and also some quirks and buried rakes.

## Running the `links` slang application

The `links` script runs within an HTTP server (safe-server) that serves a REST API defined within the script.   The server has an embedded logic engine, and acts as a client of the key-value store.  In a secure deployment, each principal runs its own instance of safe-server that acts on that principal's behalf.  The instance runs with the keypair of its controlling principal (owner), and accepts REST calls only from its owner.  The owner trusts the instance to sign certificates under its keypair, protect its private key, validate incoming certificates, evaluate the logic correctly, and apply local policy.


To keep things simpler for debugging and demos, a single SAFE instance can act on behalf of multiple principals with different keypairs.  It does not mean the principals trust one another: the scenario runs the same way if they each have a private SAFE instance.  But it is easier to configure and manage.


Either way, once we have a safe-server running, we need some way to issue REST commands to it.  You can use *curl* if you want!   Or you can write your own program to make the REST calls.  As an alternative, SAFE provides an interactive command shell called slang-shell.   It has functions to switch among multiple principals, issue script-specific REST calls to the safe-server, and store tokens and other values in named shell variables.


The slang-shell runs as its own process with slang scripts that define new commands.   These *client* slang scripts tend to be simple: they just issue REST calls against a single SAFE instance on behalf of the current principal.  In particular, they don't produce or consume any certificates, or even touch the key-value store.


In this demo, the slang-server and slang-shell run as scala processes on a single computer, alongside a Riak key-value store.  We can use the [standard docker setup for ImPACT](https://github.com/RENCI-NRIG/impact-docker-images/tree/master/safe-server), as in the strong (STRONG) application demo.   It runs Riak and safe-server within separate containers on the local computer.  The slang-shell runs in the safe container.


I used the Riak container, but I installed the SAFE repo and a Scala environment on my host laptop and ran the slang-shell and safe-server as separate sbt processes, with access to the keypairs stored in a local directory (I used ~/safe-scratch/principalkeys).  That requires a trivial amount of configuration: just poke safe-server/.../application.conf to point metastore at your Riak instance, and set a desired log level.  (The standard setup does that automatically.)


The standard setup uses python-dependent utilities in the safe repo to generate keypairs for four principals to use in the strong scenario.   We use the same keypairs with their strong names for the links demo scenario.

### Running the safe-server

Once your Riak is up, launch your safe-server.  Run it to load the `links` slang script.  This is a different script from the strong example: you can just kill the safe-server and restart it with the links script.  From within the top-level directory of a safe repo clone:

```
sbt "project safe-server" "run -f ../safe-apps/impact/links.slang -r safeService  -kd  ~/safe-scratch/principalkeys"
```

This just says to launch a SAFE process in the safeService role with the the links script file and the specified key directory.  By default the server serves on `localhost:7777`.  I left it there.  The slang-shell finds it there automatically, but you can give it a command to talk to a different IP address or port.  

### Running the slang-shell

Once the safe-server is up, launch your slang-shell in a different terminal.  From within the top-level directory of a safe repo clone:

```
sbt "project safe-lang" "run"
```

You get a slang-shell command prompt.  You now begin typing commands to slang-shell.  First, import the `links-client` script.

```
import("safe-apps/impact/links-client.slang").
```

By default it finds the safe-server at localhost:7777, as in the standard setup.  You can optionally issue a command to tell it where the safe-server is, by saying something like:

```
?ServerJVM := "localhost:7777".
```

##The `links` example scenario


From this point, we run the `links` scenario by typing commands to the slang-shell.  Most of the commands we use are implemented in `links-client.slang` and `links.slang`, but some are slang-shell builtins or standard safe commands implemented in `safe-client.slang` and `safe.slang`, which `links` imports.

You are encouraged to play around with it.  We can also issue ordinary `curl` requests to Riak from another terminal to observe certificates as they are stored.

The links application lets participants issue simple certificates, chain them together, and query the chains.  Each links certificate has a name, and a logic statement that asserts the name is present.  You can  query if a particular named certificate is in a chain.  Each issuer has its own name space for certificates.  You can query if a particular principal has asserted the name.  There is a shorthand to query if the current principal (`$Self`) has asserted the name.


Each certificate in the links application has either zero links or one link: this application builds certificate chains, but not generalized DAGs.   We arbitrarily call a certificate with zero links an *anchor certificate*, and a certificate with one link a *link certificate*.  In addition, each principal has a self-signed certificate called a *principal certificate* that contains the principal's full public key.

###1. Post the principal certificates

Each principal issues a SAFE `postRawIdSet` command to issue a self-signed certificate containing the issuer's public key: a *principal certificate*.   A principal certificate may also contain self-asserted facts about the identity in logic.  We call the logic set in a principal certificate an *IdSet*.

```
?Self := "strong-1".
?A := postRawIdSet($Self).
?Self := "strong-2".
?B := postRawIdSet($Self).
?Self := "strong-3".
?C := postRawIdSet($Self).
```

These commands use several slang-shell variables.  SAFE prefixes variable names with a `?`, and uses `$` to dereference a variable and substitute (interpolate) it with its value. 

The commands set the `?Self` variable to a name of the *current principal*.  Slang-shell commands always run with the identity of the current principal (*$Self*) and on its behalf.

The principal names correspond to files in the keypair directory given in the `-kd` option to safe-server.  We can generate the keypairs with whatever names we want, but here we use the keypairs generated as in the `strong` scenario (standard setup). 

Each `postRawIdSet` command posts a principal certificate in the store at a token that is the hash of the principal's public key (its *keyhash*).  The command returns the keyhash, which acts as the principal's *PrincipalID*.


SAFE requires principal certificates as a convention to enable compact names with secure authentication.  When principals make statements about one another or link to one another's certificates, they use the PrincipalID (keyhash) as a name.  Anyone who learns about another principal (e.g., from a statement in another certificate) learns its keyhash, which serves directly as a token to retrieve the principal's certificate from the store, which contains its IdSet.  The IdSet has the principal's full public key, which authenticates the principal's signatures and certificates. 


These commands store each returned keyhash in a slang-shell variable for future use.  For this scenario we chose variables named A, B, and C for principals Alice, Bob, and Cindy.  We can also use these variables to name the principals, e.g., `?Self := A`.



####How to view SAFE certificates

It is easy to view the certificates in the store by issuing a `curl` request from another terminal directly to the Riak service point to GET from the safe bucket at the token.  It looks something like this:

```
curl 'http://localhost:8098/types/safesets/buckets/safe/keys/BQ2CaH...tI0JjZTdo='
```



###2. Issue anchor certificates

Continuing with the scenario, each principal issues a named anchor certificate.  In slang-shell:

```
?Self:=$A.
?AT0 := dropAnchor("a0").
?Self:=$B.
?BT0 := dropAnchor("b0").
```

The `dropAnchor` command is given in the `links-client.slang` script.  It simply issues a dropAnchor call to the configured safe-server, passing some default required environment parameters and the Name argument.

```
defcall dropAnchor(?Name) :-
{
     dropAnchor($ServerJVM, $ReqEnvs, $Name).
}.
```
   
On the safe-server, dropAnchor lands in the `links.slang` script.  It posts a certificate created from a logic set constructor.  The certificate contains a single logical assertion that the name is present, and a label that is the same as the name.  Here is the slang code:

```
defcon conAnchor(?Name) :-
{
   present($Name).
   label($Name). 
}.
   
defpost dropAnchor(?Name) :-
   [conAnchor(?Name)].
```

Slang's syntax is what it is.   In a nutshell, each script element **def**ines an action: make a call (**defcall**), construct a logic set (**defcon**), post to the store (**defpost**).   Slang also has **defguard** to query a logic context assembled from certificates (see below).


The curly brackets `{}` in the **defcon** constructor open a logic set template, whose evaluation results in a logic set.  The lines in the template are statements in the trust logic language, and not in slang.  In this example, the first statement is a simple logic fact with a user-defined predicate (**present**).  The second statement is a pseudo-fact with the builtin **label** predicate, which labels the set with a string.   Slang scripts may pass slang variables into a set template; within the template, always use the `$` escape to substitute (interpolate) them with their values.


The square brackets `[]` in the **defpost** define a list, in this case a list of items to be posted.  This list has only one element: a logic set value returned from the defcon. The defpost issues a certificate encoding the logic set and signed under the issuer `$Self`, and posts it to the store.  It derives the token (index key) from the set's label and the issuer's principal ID.  The defpost returns the token to the client, which passes it back into slang-shell as the return value of the defcall.that 


Alice and Bob have now issued anchor certificates, each containing one logic statement: a fact asserting a name.  Each fact is spoken by the issuer of the containing certificate: Alice asserts name "a0", and Bob asserts name "b0".   The certificate tokens are in the slang-shell variables `?AT0` and `?BT0`.


Anyone who knows a certificate token can retrieve the certificate.  The certificate contains the PrincipalID who issued the certificate and spoke the logic statements it contains.   The issuer signed the certificate under its full public key, which anyone can retrieve given its PrincipalID: every certificate implicitly links to its issuer's IdSet.

###3. Query a certificate

Given a certificate token, it is easy to issue a logical query against the certificate's contents.  The links application has a present command for this purpose.  In slang-shell:

`
present("a0", $A, $AT0)?
present("b0", $B, $BT0)?
`

Each present query asks if a name is present, asserted by a given principalID, in the certificate or certificate chain referenced by a token.  These queries return "satisfied".   Note that it does not matter which principal issues the query, because this is a simple query about who said what, independent of any policy for the requester to decide whether it believes the assertion.  Later we show how to add a policy rule to a query to reason logically about belief based on the attribution of the statements.


The query lands at a corresponding `defguard` action in the safe-server, which is defined in the links script:

```
defguard queryPresent(?Name, ?Owner, ?RootToken) :-
{
   link($RootToken).
   $Owner:present($Name)?
}.
```

The defguard element defines a logic set containing a query.  The set uses `link` to import other logic content that defines the context for the query.  The set construction is similar to the defcon element above.   The link is a pseudo-fact with a reserved keyword in the logic language (like label): it links the target certificate by its token.  In a guard the effect of the link is to fetch the target certificate(s), validate them, and incorporate their logic content into the context: a guard context includes the union of all linked certificates.


The logic query asks if the target principal asserts that the name is present.  The ":" operator in the query (or in any atomic statement, i.e., logical atom) means "says": this query returns true only if the indicated principal says the fact.  The example queries return true (satisfied): in Alice's anchor certificate she asserts that "a0" is present, and similarly for Bob.


But if we ask about the wrong name, or a different principal who did not assert the name, or point at the wrong certificate, the query returns false (unsatisfied).  In slang-shell:

```
present("b0", $A, $AT0)?
present("b0", $A, $BT0)?
```

###4. Build certificate chains with link certificates

The next step is to show how to link certificates together.  Alice invokes the dropLink command to issue a link certificate---a certificate with one link that (in this example) points to her anchor certificate.

```
?Self:=$A.
?AT1 := dropLink("a1", $AT0).
```

On the safe-server, dropLink is implemented in the `links.slang` script.  It posts a certificate created from a logic set constructor.  The certificate contains a single logical assertion that the name is present, and a label that is the same as the name.  Here is the slang constructor:

```
defcon conLink(?Name, ?PrevToken) :-
{
   present($Name).
   link($PrevToken).
   label($Name). 
}.
```

Like the anchor certificates, the link certificate asserts that the name string is present, and labels the set with the name.  As with the anchor certificates, the corresponding defpost (not shown) converts the logic set to a certificate, generates the token from the set's label and the issuer's PrincipalID (its public key hash, which also serves as its IdSet token), and posts it in the key-value store indexed by its token.   What is different here is that the new link certificate also includes a link to the target certificate, forming a chain.


There is no requirement that all the certificates in the chain have the same issuer, as in this chain.   The issuer could be anyone.  For example, Bob can create a certificate that links to the head of Alice's chain, forming a chain with three certificates issued by two different principals.

```
?Self:=$B.
?BT1 := dropLink("b1", $AT1).
```

It is important to recognize that the link itself confers no authority: it only helps others to locate relevant certificates.  Guards evaluate certificates based solely on their authenticated logic content, which is spoken by their issuers and evaluated on that basis, regardless of how anyone links to them.  Thus there is no integrity concern with allowing untrusted principals to link to trusted certificates.  However, knowledge of the token permits anyone to read the certificate's content, which may raise privacy concerns.  If an attacker intercepts or otherwise obtains the tokens---or knows which public key you use and how you label your certificates---it can find them and read them.

###5. Query certificate chains

Anyone can query a certificate chain in the same way that it interrogates a certificate.  When a guard issues a query against a certificate, the logic context for the query includes the statements in all linked certificates, recursively (the transitive closure)---if they are valid and the linking structure is not "too large" (cycles are ignored).  So we can use present queries just like we did before.  In slang-shell:

```
present("a0", $A, $BT1)?
present("a1", $A, $BT1)?
present("b1", $B, $BT1)?
```

All of these queries are satisfied: the query context includes all the name assertions.   As before, the guard rejects any query with the wrong speaker, or a  name that was never asserted, or a chain that does not include the requested name assertion.

```
present("a0", $B, $BT1)?
present("xx", $A, $BT1)?
present("b1", $B, $AT1)?
```

As with the examples to query a certificate, it does not matter which principal issues the query, because this is a simple query about who said what, independent of any policy rules for the requester to reason about whether it believes any given assertion (see below).

###6. Synthesizing tokens

Anyone who knows the issuer and label of a posted certificate can determine its token, and anyone who knows a certificate's token can retrieve it from the store.  Although these properties of SAFE may raise privacy concerns (above), they are frequently useful.  For example, we can query a certificate chain without knowing the link.  In slang-shell:

```
// presentByName(?Name, ?Owner, ?RootName, ?RootOwner)
presentByName("a0", $A, "b1", $B)?
```

This example is the same query as present("a0", $A, $BT1) above.  The token $BT1 is synthesized from the certificate's issuer ID and label (name).


The corresponding slang defguard element in the links.slang script shows how to use slang's label builtin to synthesize a token.


```
defguard queryPresentByName(?Name, ?Owner, ?RootName, ?RootOwner) :-
   ?RootToken = label(?RootOwner, ?RootName),
{
   link($RootToken).
   $Owner:present($Name)?
}.
```

There are two points to note about this code:

  *The label call appears in slang code outside of the set template.  It uses the slang variable names: in this case no $ escape is needed (or allowable) because the slang interpreter uses the variable values in the normal way outside of a set template.

...A slang procedural element is secretly just a logic rule under the hood---hence the `:-`, which is logic syntax for the *implies* operator.  The right-hand side of a logic rule consists of a list of goals separated by commas.  The  interpreter evaluates each goal in sequence unless and until it encounters a goal that returns nil.  The result of the invocation is the value returned by the last goal it evaluates.  For this defguard, the result of evaluating the last goal---the set template that defines the logic query context---is the logic query result.

  *The token value for the target certificate (or chain) is stored in a slang variable (?RootToken).  The set template incorporates the token value by interpolating the variable with a $ escape in the usual fashion.  Any slang variables that are not escaped in this way pass through the logic set, where they are understood as logic variables rather than slang variables.

...A logic set is declarative (datalog): it has no slang code and no procedural constructs at all beyond a few SAFE-specific builtins.  Thus there is no risk to a remote participant to evaluate a logic set: evaluation is a reasoning process that either succeeds in proving a query or yields false, in a bounded time, with no side effects.  Logic may contain variables, but only in restricted ways, and only in logic rules, following the restrictions known as safe ordinary datalog.  In this case, the resulting query context contains no logic rules, only the query and the simple name assertions (facts) extracted from the certificate chain.  The resulting logic contains no variables, only constants (e.g., PrincipalIDs, string names) interpolated from the values of the slang variables at logic generation time.

###7. Adding a trust policy rule to reason from belief

We added an exemplary trust policy to demonstrate the use of logical policy rules.  This example is a bit contrived: it introduces the idea that someone might not accept that a given named certificate is present just because some untrusted party asserts it.   It introduces an endorsing principal that endorses other principals as trusted (an arbitrary predicate), and a rule that believes an assertion only if its speaker is trusted.  Obviously, this idea has value in other contexts, but for the links example it is only an illustration.  A later version should split the logical policy concept into a separate tutorial.

The scenario starts with Cindy endorsing Alice.  In slang-shell:

```
?Self:=$C.
?CEAT := endorse($A).
```

Cindy posts a certificate stating that Alice is trusted, and saves the token in the cindy-endorses-alice-token variable (?CEAT).  This is just another kind of anchor certificate.  The corresponding script element on the safe-server is:

```
defcon endorsement(?Endorsee) :-
{
    trusted($Endorsee).
    label("endorse $Endorsee").
}.
```

This logic set constructor defines a standard for endorsement certificates.  It has a single statement by which the issuer asserts that the endorsee is trusted, a new predicate defined in the policy, and whose name is arbitary.   The statement includes the public key of the endorsee (the subject), which is included under the issuer's signature, so it is not possible to forge an endorsement certificate or use it for the wrong principal.  The label also includes the PrincipalID of the endorsee, so that endorsements of different principals have different labels, and therefore different tokens, and so won't overwrite each other in the key-value store.   Endorsements of the same principal by different issuers also have different tokens, since defpost derives the token from both the label and the issuer together.  Although Riak does not check it, SAFE assumes that the key-value store disallows any principal from writing on a token that it does not own, to block malicious entities from overwriting a victim's certificates as a denial-of-service attack.


Next, Alice issues a link certificate asserting that name "a2" is present, and linking to Cindy's endorsement of Alice.  In slang-shell:

```
?Self:=$A. 
?AT2 := dropLink("a2", $CEAT).
```

It is useful for a principal to link a certificate to others that substantiate its authority to issue the certificate in this way.  The trust scripts for all example SAFE applications link to support in this way to build certificate DAGs by construction, enabling a requester to assemble a logic context with information that is relevant to a given query.  It is trivial to link certificates when all principals run in the same slang-shell with shared global variables!  The real world is more complicated: Cindy must pass the endorsement token ($CEAT) to Alice out of band, e.g., maybe Alice requests the endorsement from Cindy, or maybe Cindy advertises it on a web site, links all her endorsements at a well-known link (an anchor set), or posts the endorsement with a well-known label so that other principals can find it.  These choices are part of the software embedding for a SAFE application.


Now we are ready to consider logical policy rules.   Bob creates a policy package that declares and governs when Bob believes or accepts a present assertion that is spoken by another principal.  

```
?Self:=$B.
?BPT := trustPolicy($C).
```

The request lands at the slang constructor for the policy package in the safe-server's links script.   The example policy states that Bob trusts a name only if its issuer is trusted.  Bob passes the PrincipalID of an endorser principal---Cindy in this case---whose endorsements Bob accepts.   Bob trusts a name if Bob asserted the name himself (Rule 1), or if some other principal asserted the name, and Cindy endorsed the speaking principal as trusted (Rule 2).

```
defcon trustPolicySet(?Endorser) :-
{
   endorser($Endorser).
   // **Rule 1**:
   trustedName(?Name) :-
        present(?Name).
   // **Rule 2**:
   trustedName(?Name) :-
        ?Speaker:present(?Name),
        ?Endorser:trusted(?Speaker),
		endorser(?Endorser).
   label("accept trustedName endorsements from $Endorser").	   
}.
```

The policy set contains three logic statements and a label.   The resulting logic set contains these statements spoken by Bob, which is posted as a certificate signed by Bob.


The first statement is a fact in which Bob accepts Cindy as an endorser.  The endorser identity is interpolated from the slang parameter, so this endorser trust anchor appears as a constant (Cindy's PrincipalID) in the logic certificate.


The next two statements are logical policy rules for a new "trustedName" predicate.  The rules contain logic variables: each variable is scoped to its containing rule and assigned to a constant value if the rule is satisfied, in accordance with the requirements of safe ordinary datalog logic.  These rules are self-contained and tractable to evaluate in any query context.


Now suppose Bob issues a query on Alice's certificate chain $AT2 consructed above, and using his policy set.  Does the chain contain the trusted name "a2"?  In slang-shell:

```
?Self:=$B.
queryTrustedName("a2", $AT2, $BPT)?
```

This query lands at the corresponding slang guard in the links script on the safe-server:

```
defguard queryTrustedName(?Name, ?RootToken, ?Policy) :-
{
   link($RootToken).
   link($Policy).
   trustedName($Name)?
}.
```

As with queryPresent above, this query takes the name and a link to the certificate chain as arguments.   The difference is that for queryPresent the requester must specify the required issuer (owner) of the name, while queryTrustedName is satisfied if it finds a name whose issuer is trusted according to the policy rules in the linked policy set.


In this case, the guard assembles a context containing the policy set and the certificate chain, and issues the query.  The query asks whether the certificate chain contains a trustedName according to the policy of the caller---Bob.  In this case, the logic engine sees that the answer is yes: Alice asserts the requested name, and
Cindy endorses Alice, and Bob trusts Cindy as an endorser.  Logic rules are a powerful formalism to specify a wide range of validation criteria for certificate collections, and to evaluate them automatically.


We again emphasize that Bob's policy set is specific to Bob.  Bob has no authority to specify policy for Alice, or even for Cindy.  For example, if Alice issues the same query, it is unsatisfied because the logic engine has no rules to determine when Alice believes a trustedName.  The query fails even though Alice asserted the name herself!  In slang-shell:

```
?Self:=$A.
queryTrustedName("a2", $AT2, $BPT)?
```

The logic engine approves compliance only if an applicable governing policy states a set of requirements, and the authenticated logic statements in the context meet those requirements according to some valid chain of logical reasoning---a proof.  In this case, the query fails because the logic engine cannot prove that it succeeds from the certified logic in the context.


SAFE is a powerful environment, but a key remaining challenge is to provide better tools for developers and (to a lesser extent) for users to understand why a query fails and how to obtain the credentials to enable access.  A failing query suggests that either the statements required to proof it were never issued, or they exist somewhere but are missing from the context, or they are invalid in some way. 


This example demonstrates that policy rules are principal-specific, and no principal can unilaterally issue policy rules on another principal's behalf.   However, logical policies are transportable among principals: it is easy for a principal to apply the policy of another principal on that principal's behalf.  This property of policy mobility enables more powerful forms of delegation.  Various example SAFE applications depend on it.


To demonstrate mobile policy rules, another variant of queryTrustedName takes another "believer" PrincipalID as an argument, and asks whether the believer believes the trustedName, according to the believer's known policy rules.

```
?Self:=$A. 
queryTrustedName("a2", $B, $AT2, $BPT)?
```

This query is satisfied because the context includes Bob's policy rules, and the logic engine can prove the query goal from those rules and the assertions in the context, in the same way as for Bob's query above.  The corresponding guard query for this variant of queryTrustedName is slightly different:

```
     $Believer:trustedName($Name)?
```

The query applies the policy on behalf of the believer by using the says (`:`) operator to query if the believer says or believes the query goal.  It then does not matter whether the caller believes the goal according to its own policy. 


###Slang-shell basics

####How to switch principals in slang-shell

Slang-shell enables you to issue commands on behalf of different principals in a scenario.  To set the current principal, set the `?Self` variable to a particular keypair file name in the keypair directory.

As an alternative, you can set `?Self` to a principal's keyhash, once the principal certificate is posted.  For example, suppose the variable `A` received Alice's keyhash when Alice posted her principal certificate, e.g., with `postRawIdSet`.  Then to switch to principal Alice:

```
?Self := $A.
```

####How to save and restore the environment

You can get a list of environment variables and their values:

```
env.
```

You can save the slang-shell environment variables to a file and reload them later. 

```
saveEnvTo("env.txt").
//later...
import("env.txt").
env.
```

####How to restart and continue where you left off

**To restart slang-shell**.  It is a good practice to use commands that save all returned tokens in slang-shell variables, as in the examples.  If you follow that practice, then once you quit slang-shell after you save the environment with `saveEnvTo().`  Exit with ctrl-c or `quit.`  Run slang-shell again when you are ready. Use `import` to restore the environment in the new slang-shell instance.  Then just continue where you left off.

**To restart safe-server**.  Just restart it!  The safe-server caches certificates, and it loses the cache when it restarts.   But the certificates persist in the store, so it can fetch them given their tokens.  And it has their tokens, because you save all tokens in the slang-shell and pass them to the commands as needed.


**Changing the slang scripts**.  it is OK to change the slang scripts on the fly as long as the change does not affect the content of generated certificates.  Just remember that any existing certificates do not reflect the new content: they were generated with the old scripts.

**Using multiple hosts**.  You can run the safe-server on a different host as long as all participating safe-servers share the same Riak K/V service.  

####Principals may use separate SAFE instances.

You can run these scenarios with a separate slang-shell and safe-server for each principal.  That is how SAFE should run in production.  The only wrinkle is that they often must pass tokens to one another.  Token-passing is easy in these examples because we run them in the same slang-shell with shared environment variables. 

####It is safe to reissue old commands (no side effects).


If you reissue a command that constructs and posts a certificate, it generates a new certificate that overwrites the old one.  Any other certificates that linked to the old version now link to the new version. If we use the same arguments, the script generates an identical certificate, so nothing changes (scripts are deterministic). So we can freely reissue these commands. 

But what if you use different arguments?  Depending on the scripts, issuing a variant of an earlier command with different arguments might or might not overwrite the old certificate, and if it does, the new version might or might not be different from the old version.  It is a good practice to incorporate parameter values into the label to prevent unexpected side effects.








