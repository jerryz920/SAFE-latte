# Simple ImPACT Scenario (MVP)

The MVP scenario illustrates basic elements of ImPACT: published workflows with user and common elements whose completion is attested by a Notary Service, per-dataset policies published by a Dataset Owner, and access checks by a Data Provider (Presidio server).

As a SAFE application, the ImPACT scenario illustrates several interesting features:

* Third-party evaluation of certified policy rules issued by multiple entities: the data provider combines and evaluates policy rules issued by the dataset owner and workflow publisher.

* Integration of logical trust with Shibboleth identity management and CILogon.   A notary server and the data provider authenticate users via web sign-on, and verify project memberships before issuing attestations.  The logic represents user and project identities as ordinary strings (their Shibboleth/Grouper/CoManage names), while the infrastructure services use keypairs to authenticate and certify their policies and attestations.

* Use of synthesized links to issue high-level queries against the key-value certificate store.  The infrastructure services use common labeling conventions embodied in prepackaged SAFE trust scripts.  In essence these are precomputed indexes for the set of query types used in the scenario.

An ImPACT document discusses the structure and rationale of the MVP scenario in detail.  Currently it is in the [SAFE Integration Notes](https://docs.google.com/document/d/1aEVEKz8eBntmC92U3Ug_J4pgfuOs9UMnCCGv0cHYybQ).

## Running the MVP scenario

For ease of use, this variant of the scenario runs with a single SAFE trust script that combines the actions of all four actors (principals).  We describe a more realistic variant below (future).

To run it you need a local SAFE install with a slang-shell issuing REST calls to a safe-server.  The safe-server is a client of a shared KV store (Riak) and is pointed at a local keypair directory with four keypairs.

One way to get set up is to follow the [standard docker setup for ImPACT](https://github.com/RENCI-NRIG/impact-docker-images/tree/master/safe-server), also known as the STRONG application demo.  But for this MVP scenario your safe-server loads the script `safe-apps/impact/mvp.slang` rather than the STRONG script.  The `mvp.slang` script defines the certificate formats and linking patterns for the application.

So: you launch the server with a command like:

```
cd safe
sbt "project safe-server" "run -f ../safe-apps/impact/mvp.slang -r safeService  -kd  ~/safe-scratch/principalkeys"
```

Your slang-shell loads the matching `mvp-client.slang` script, as described below.

###1. Start a slang-shell

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

If your safe-server is indeed running on localhost on port 7777, this command is optional: it given as the default in the `mvp.slang` safe-server script.

Finally, load the MVP client script into your slang-shell:

```
import("safe-apps/impact/mvp-client.slang").
```

###2. Post the principal certificates

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

Each principal certificates is posted in the shared K/V store at a token that is the principal's keyhash.  Each `postRawIdSet` returns the keyhash, and slang-shell saves it in a shell variable that names the principal for future commands.

####The players
There are four principals involved in the demo:


* **$WP**: Workflow Publisher

* **$DSO**: Data Set Owner

* **$NSV**: Notary Service

* **$DP**: Data Provider (Presidio)

###3. Set up scids for workflows and dataset

This example involves three *secure objects*: two workflows (**$WF1** and **$WF2**) and the dataset (**$DataSet**).  They are *objects* in a particular sense.  Like principals,  we can make logical statements about them (e.g., in certificates) and reason about them according to those statements and various logical policy rules.  However, the objects do not themselves issue statements or certificates: they are not principals, and therefore do not have keypairs.  The objects are *secure* in the sense that their names (constants in the logic) are certified, so that an untrusted principal cannot hijack another principal's object and make undetectably bogus statements about it.

Specifically, each secure object is named by a *self-certifying identifier* (scid).  The scid is bound to the object's *controlling principal* or *owner*: an object's owner is the principal who creates the object and is empowered to direct how others should reason about the object.  A scid is formed by concatenating the owner's keyhash with a unique object name chosen by the owner, e.g., a UUID.

So we make three scids to represent these objects in future commands:

```
?UUID1 := "6ec7211c-caaf-4e00-ad36-0cd413accc91".
?UUID2 := "1b924687-a317-4bd7-a54f-a5a0151f49d3".
?UUID3 := "26dbc728-3c8d-4433-9c4b-2e065b644db5".

?WF1 := "$WP:$UUID1".
?WF2 := "$WP:$UUID2".
?DataSet := "$DSO:$UUID3".
```

###4. Workflow Publisher: post completion rules for workflows

When a WP publishes a new workflow, it posts rules to verify that the workflow is complete for a specified user under a specified project.   An NS attests that various parties have completed various elements of the workflow.  The workflow rules validate these attestations and verify that all required attestations are present.

This example has two workflows.  The WP posts completion rules for each of them.

```
?Self := $WP.
postPerFlowRule($WF1).
postPerFlowRule($WF2).
```
###5. DataSet Owner: post access policy for dataset

The DSO posts an access policy for each dataset.   In this example the DSO policy requires completion of two workflows.

```
?Self := $DSO.
postTwoFlowDataOwnerPolicy($DataSet, $WF1, $WF2).
```

###6. Notary Service: post completion receipts for both workflows

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

In the MVP, the NS also knows the dataset that the user intends to request, and the workflows required to access the dataset.   Also, in the MVP the same NS attests all required workflows for each given dataset: the NS links the attestations for all required workflows into a *link receipt* for the dataset, user, and project.  A sequence of calls can add multiple workflow completions to the same link receipt.

```
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF1).
postLinkReceiptForDataset("someUser", "someProject", $DataSet, $WF2).
```

###7. Data Provider (Presidio): check access

Now we are ready for a DP to check access for the dataset.   We assume in this scenario that the DP is operated by a separate principal from the dataset owner (DSO), but this is optional: nothing about the example or the code requires it.

The DP must know the authenticated identities of the user and project.  These are authenticated via SSO (e.g., Shibboleth) in the same way as for the NS, and so they are given as strings.  It also must know the the public key of the NS that attested this user and project.   In the real scenario the user passes the selected project name and NS public key as web tokens (JWT).

The DP issues a guard query against this information.  The trust script retrieves all needed policies and attestations: it fetches policy for the dataset, which links to the WP's completion rules for the required workflows.  It fetches the link receipt issued by the NS for the dataset, user, and project.  The closure of the link receipt includes all required attestations.

```
?Self := $DP.
access($DataSet, "someUser", $NSV, "someProject" )?
```

