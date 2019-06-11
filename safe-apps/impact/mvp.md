# Simple ImPACT Scenario (MVP)

The MVP scenario illustrates basic elements of ImPACT: published workflows with user and common elements whose completion is attested by a Notary Service, per-dataset policies published by a Dataset Owner, and access checks by a Data Provider (Presidio server).

As a SAFE application, the ImPACT scenario illustrates several interesting features:

* Third-party evaluation of certified policy rules issued by multiple entities: the data provider combines and evaluates policy rules issued by the dataset owner and workflow publisher.

* Integration of logical trust with Shibboleth identity management and CILogon.   A notary server and the data provider authenticate users via web sign-on, and verify project memberships before issuing attestations.  The logic represents user and project identities as ordinary strings (their Shibboleth/Grouper/CoManage names), while the infrastructure services use keypairs to authenticate and certify their policies and attestations.

* Use of synthesized links to issue high-level queries against the key-value certificate store.  The infrastructure services use common labeling conventions embodied in prepackaged SAFE trust scripts.  In essence these are precomputed indexes for the set of query types used in the scenario.

An ImPACT document discusses the structure and rationale of the MVP scenario in detail.  Currently it is in the [SAFE Integration Notes](https://docs.google.com/document/d/1aEVEKz8eBntmC92U3Ug_J4pgfuOs9UMnCCGv0cHYybQ).

## Running the MVP scenario

For ease of use, this variant of the scenario runs with a single SAFE trust script that combines the actions of all four actors (principals).  We describe a more realistic **split** variant below that separates the principals so their only interaction is through the shared K/V store, and some static initializer inputs.

To run it you need a local SAFE install with a slang-shell issuing REST calls to a safe-server.  The safe-server is a client of a shared KV store (Riak) and is pointed at a local keypair directory with four keypairs.

One way to get set up is to follow the [standard docker setup for ImPACT](https://github.com/RENCI-NRIG/impact-docker-images/tree/master/safe-server), also known as the STRONG application demo.  But for this MVP scenario your safe-server loads the script `safe-apps/impact/mvp.slang` rather than the STRONG script.  The `mvp.slang` script defines the certificate formats and linking patterns for the application.

So: you launch the server with a command like this.  Here we assume that the pathname of the keypair directory is "~/safe-scratch/principalkeys", but you can put it wherever you want.

```
cd safe
sbt "project safe-server" "run -f ../safe-apps/impact/mvp.slang -r safeService  -kd  ~/safe-scratch/principalkeys"
```

Your slang-shell loads the matching `mvp-client.slang` script, as described below.

### 1. Start a slang-shell

Start your slang-shell in the usual fashion.  Something like:

```
cd safe
sbt "project safe-lang" "run"
```

From this point forward we run the scenario by issuing commands to the slang-shell.   These commands run on behalf of the different principals in the scenario.

Once the slang-shell gives you a prompt, point it at your safe-server.    Something like:

```
?ServerJVM := "localhost:7777".
```

If your safe-server is indeed running on localhost on port 7777, this command is optional: it is given as the default in the `mvp.slang` safe-server script.

Finally, load the MVP client script into your slang-shell:

```
import("safe-apps/impact/mvp-client.slang").
```

### 2. Post the principal certificates

As always, the principals must post their IdSet certificates.   These slang-shell commands presume that you are using the same keypairs generated as for the STRONG example:

```
?Self := "strong-1".
?WP := postRawIdSet("strong-1").
?Self := "strong-2".
?DSO := postRawIdSet("strong-2").
?Self := "strong-3".
?NSV := postRawIdSet("strong-3").
?Self := "strong-4".
?DP := postRawIdSet("strong-4").
```

Each principal certificate is posted in the shared K/V store at a token that is the principal's keyhash.  Each `postRawIdSet` returns the keyhash, and slang-shell saves it in a shell variable that names the principal for future commands.

#### The players

There are four principals involved in the demo:


* **$WP**: Workflow Publisher

* **$DSO**: Data Set Owner

* **$NSV**: Notary Service

* **$DP**: Data Provider (Presidio)

### 3. Set up scids for workflows and dataset

This example involves three *secure objects*: two workflows (**$WF1** and **$WF2**) and the dataset (**$DataSet**).  They are *objects* in a particular sense.  Like principals,  we can make logical statements about them (e.g., in certificates) and reason about them according to those statements and various logical policy rules.  However, the objects do not themselves issue statements or certificates: they are not principals, and therefore do not have keypairs.  The objects are *secure* in the sense that their names are certified, so that an untrusted principal cannot hijack another principal's object and make undetectably bogus statements about it.

Specifically, each secure object is named by a *self-certifying identifier* (scid).  The scid is bound to the object's *controlling principal* or *owner*: an object's owner is the principal who creates the object and is empowered to direct how others should reason about the object.  A scid is formed by concatenating the owner's keyhash with a unique object name chosen by the owner, e.g., a UUID.

Scids act as constants that name the objects in the scripts and logic rules.  Logic or slang scripts can extract the owner keyhash from a scid, and verify that other statements (e.g., object attributes or policy rules) are spoken by the object's owner.

So we make three scids to represent these objects in future commands:

```
?UUID1 := "6ec7211c-caaf-4e00-ad36-0cd413accc91".
?UUID2 := "1b924687-a317-4bd7-a54f-a5a0151f49d3".
?UUID3 := "26dbc728-3c8d-4433-9c4b-2e065b644db5".

?WF1 := "$WP:$UUID1".
?WF2 := "$WP:$UUID2".
?DataSet := "$DSO:$UUID3".
```

### 4. Workflow Publisher: post completion rules for workflows

When a WP publishes a new workflow, it posts rules to verify that the workflow is complete for a specified user under a specified project.   An NS attests that various parties have completed various elements of the workflow.  The workflow rules validate these attestations and verify that all required attestations are present.

This example has two workflows.  The WP posts completion rules for each of them.

```
?Self := $WP.
postPerFlowRule($WF1).
postPerFlowRule($WF2).
```
### 5. DataSet Owner: post access policy for dataset

The DSO posts an access policy for each dataset.   In this example the DSO policy requires completion of two workflows.

```
?Self := $DSO.
postTwoFlowDataOwnerPolicy($DataSet, $WF1, $WF2).
```

### 6. Notary Service: post completion receipts for both workflows

Users and administrators interact with the NS through a Web browser to view and complete the workflows.  A workflow may have common elements (e.g., administrative approval) as well as user-specific elements.

The NS uses an SSO (e.g., Shibboleth) to authenticate the user identity for each Web session.  It also self-validates the user membership in the stated project, and the authority of adminstrators to complete the common elements for any given workflow and project.

The NS issues an attestation (a completion receipt) for each required element, and links the receipts for each workflow together.  

```
?Self := $NSV.
postCommonCompletionReceipt("someProject", $WF1).
postUserCompletionReceipt("someUser", "someProject", $WF1).

postCommonCompletionReceipt("someProject", $WF2).
postUserCompletionReceipt("someUser", "someProject", $WF2).
```

In the MVP, the NS also knows the dataset that the user intends to request, and the workflows required to access the dataset.   Also, in the MVP the same NS attests all required workflows for each given dataset.  These restrictions in the MVP enable the NS to link the attestations for all required workflows into a *link receipt* for the dataset, user, and project.  A sequence of calls can add multiple workflow completions to the same link receipt.

```
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF1).
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF2).
```

### 7. Data Provider (Presidio): check access

Now we are ready for a DP to check access for the dataset.   We assume in this scenario that the DP is operated by a separate principal from the dataset owner (DSO), but that is optional: nothing about the example or the code requires it.

The DP must know the authenticated identities of the user and project.  These are authenticated via SSO (e.g., Shibboleth) in the same way as for the NS, and so they are given as strings.  The DP also must know the the public key of the NS that attested this user and project.   In the real scenario the user passes the selected project name and NS public key as web tokens (JWT).

The DP issues a guard query against this information.  The trust script retrieves all needed policies and attestations: it fetches policy for the dataset, which links to the WP's completion rules for the required workflows.  It fetches the link receipt issued by the NS for the dataset, user, and project.  The closure of the link receipt includes all required attestations.

```
?Self := $DP.
access($DataSet, "someUser", $NSV, "someProject" )?
```

## Separating the principals: Split MVP demo

In the MVP demo above all principals share the same safe-server with the same trust script.  In a real deployment we expect that mutually suspicious principals run their own safe-servers under their local control, since each principal must trust its safe-server.   Now we show how to split principals and run them separately.

The split MVP demo is the same as the simple MVP demo, EXCEPT for these differences:

* *Split up mvp.slang into separate scripts for the four principals.*  There is nothing unsafe about them all running the same trust script, but  it helps to see the code each principal runs and that each principal runs only its own code.

* *Run four separate safe-servers, one for each principal.* Each serves on a different port, loads only its own trust script code, and knows only its own principal's keypair.   (Of course all the safe-servers use the same Riak K/V store.)

* *Run four separate slang-shells, one for each principal.*  Each slang-shell sends requests only to its own principal's safe-server.

* *Each slang-shell receives only the commands for its principal.*

### Note on the key distribution problem and SAFE integration

The ImPACT scenarios require that the principals distribute their keyhashes to one another out of band.  Some scids are also distributed out of band, as are the string names for users and projects (e.g., given by CILogon and CoManage).

The deployable software infrastructure for ImPACT handles this out-of-band distribution.  Specifically:

* Dataset Owner ($DSO) must know the *workflow scids* $WF1 and $WF2 that it requires for its policy.  These can be obtained from an online catalog, or the $DSO may act as its own workflow publisher ($WP).

* Notary Service ($NSV) must know the *workflow scids* for each workflow that it handles.  Workflows are registered with the NSV.

* For MVP, Notary Service ($NSV) must know the *$DataSet* scid that the user will request and the workflows required to access it.  This requirement enables $NSV to generate *link receipts* (see above) so that Presidio can fetch required attestation receipts without knowing the $DSO's policy.   It also helps usability, because the same information permits NSVs to assist users in finding the required forms.  DSOs register datasets with NSVs, and users browse and select datasets. 

* Presidio data server must know the *user name*, which it obtains via TLS client authentication (e.g., with a CILogon-issued certificate),  and the *$DataSet* scid, which it retrieves from its filesystem.

* Presidio also must know the attesting *$NSV keyhash*  and the *project name* that the user acts under.  It is sufficient for the user to pass this information to Presidio in arguments or via an unsigned JWT.

**Dissenting opinion** (Chase): As of this writing the MVP design calls for the Notary Service (NSV) to generate a signed JWT with the user name, project name, a TTL, and other information.  This JWT certifies to Presidio that the NSV has verified (via CILogon and CoManage) that the user is authorized to act under the project for the purpose of accessing data.   This signed JWT is insufficient because the design relies on SAFE to validate that the issuer is a valid Notary Service anyway.  It is unnecessary because the NSV also certifies the same user-project association via SAFE, and it can put a TTL on that certification as well.    But the scheme will work when combined with the other mechanisms in place.

### 1. Save the keyhashes and scids

Distribution of keyhashes and other values is easy in the unified example (using `mvp.slang`) because all of the principals share a slang-shell: we just use slang-shell variables to share the various values among the principals.

But we need another way to do it for the split example.  The values are not fixed: for example, the keyhashes and scids depend on the principal keypairs in the specified keypair directory. 

The simplest solution is to save the variables in a file and import them into each of the slang-shells, as described below.  We assume that your slang-shells each have a copy of the file at the same relative pathname.  You can assure this by running all of the slang-shells in the same clone of the SAFE repository.  If they really run on different nodes, then each must have a copy of the file.



Run a slang-shell in the usual way.  It must have access to your keypair directory in its file system.

```
sbt "project safe-lang" "run"
```

Suppose again that the pathname of the keypair directory is "~/safe-scratch/principalkeys".  Then feed these commands to your slang-shell:

```
?KD := "~/safe-scratch/principalkeys".

?WP := getIdFromPub("$KD/strong-1.pub").
?DSO := getIdFromPub("$KD/strong-2.pub").
?NSV := getIdFromPub("$KD/strong-3.pub").
?DP := getIdFromPub("$KD/strong-4.pub").

?UUID1 := "6ec7211c-caaf-4e00-ad36-0cd413accc91".
?UUID2 := "1b924687-a317-4bd7-a54f-a5a0151f49d3".
?UUID3 := "26dbc728-3c8d-4433-9c4b-2e065b644db5".

?WF1 := "$WP:$UUID1".
?WF2 := "$WP:$UUID2".
?DataSet := "$DSO:$UUID3".

saveEnvTo("myenv.txt").
```

You may then quit this slang-shell: we won't use it again.

### 2. Run and prime the safe-servers

Run four safe-servers, from four separate shells (terminal windows).  The servers run four different trust scripts and serve on four different ports.  Here are exemplary commands.  Pick whatever HTTP ports you want, but make sure they match the later steps. 

```
cd ~/safe
sbt "project safe-server" "run -f ../safe-apps/impact/mvp-wp.slang -r safeService  -hp 7778 -kd  ~/safe-scratch/principalkeys"
sbt "project safe-server" "run -f ../safe-apps/impact/mvp-dso.slang -r safeService  -hp 7779 -kd  ~/safe-scratch/principalkeys"
sbt "project safe-server" "run -f ../safe-apps/impact/mvp-ns.slang -r safeService  -hp 7780 -kd  ~/safe-scratch/principalkeys"
sbt "project safe-server" "run -f ../safe-apps/impact/mvp-presidio.slang -r safeService  -hp 7781 -kd  ~/safe-scratch/principalkeys```
```

### 3. Run and prime the slang-shells

Run four slang-shells in four different terminal windows, in the usual fashion:

```
cd ~/safe
sbt "project safe-lang" "run"
```

Once each slang-shell starts up, give it the following commands:

```
import("safe-apps/impact/mvp-client.slang").
import("myenv.txt").
```

The remaining steps show the slang-shell command sets for each of the four principals.  You can run them in sequence.  Be sure to assign each principal to a different slang-shell.  Of course, the ServerJVM variables must be set to bind each principal's slang-shell to its safe-server: you might need to fix them in the remaining steps if you deviate from the example.

### 4. Workflow Publisher (WP)

```
?Self := $WP. 
?ServerJVM := "localhost:7778".

postRawIdSet("strong-1"). 
postPerFlowRule($WF1).
postPerFlowRule($WF2).
```

### 5. Dataset Owner (DSO)

```
?Self := $DSO.
?ServerJVM := "localhost:7779".

postRawIdSet("strong-2"). 
postTwoFlowDataOwnerPolicy($DataSet, $WF1, $WF2).
```

### 6. Notary Service (NSV)

```
?Self := $NSV.
?ServerJVM := "localhost:7780".

postRawIdSet("strong-3"). 
postCommonCompletionReceipt("someProject", $WF1).
postUserCompletionReceipt("someUser", "someProject", $WF1).
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF1).
postCommonCompletionReceipt("someProject", $WF2).
postUserCompletionReceipt("someUser", "someProject", $WF2).
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF2).
```

### 7. Data Provider/Server (DP: Presidio)

```
?Self := $DP.
?ServerJVM := "localhost:7781".

access($DataSet, "someUser", $NSV, "someProject" )?
```

This access request query returns as **satisfied**.  If you change the user name or project name then you should see
that access is denied (**unsatisfied**).


