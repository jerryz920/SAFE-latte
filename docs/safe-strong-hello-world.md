# SAFE primer using Strong policy framework

## Overview

The Strong policy framework permits set-based resource ownership and
access privilege with delegations over namespaces. The namespace and
privilege delegation are backed by a logical machinery that can
issue and check statements about creation of a symbolic pathname,
attachment of required permission, delegation of access privilege, and
authorization of resource access.

A resource object is represented by a Self-Certifying Identifier
(SCID). A scid is a string comprised of two parts that are
concatenated with a colon (**:**): the first part is the ID of the
principal that owns the object; the second part is a label chosen by
the principal for the represented object. Based on Scids, Strong
allows assignment of a pathname to a resource object and association of
policies. Typically, resource pathnames are created under a
many-rooted naming hierarchy. Creation of a name entry ought to specify
a parent scid, a child scid, and a name component. A pathname could
originate from a namespace of any principal, but each name delegation
requires mutual consent between the principals of the parent scid and
the child scid. 

Privileges and roles are groups. A needed privilege for access can be
attached to a resource object or a directory as a group tag. A role can
be assumed by a principal if it is part of a corresponding group. A
group is also an object, identified by a scid and under its controlling
principal. In particular, a group is governed by associated policy
rules that determine who hold a group membership, what privileges one
has due to membership of the group, and who are able to further
delegate membership and privilege. The Strong library provides a common
set of policy rules for group management. Developers can extend it to
incorporate customized policies and link to a group.

The Strong policy definition is located [here](../safe-apps/strong).

## Tutorial steps

Follow the instructions in [SAFE in Docker](safe-docker.md) to start up Riak and SAFE containers (and making sure at least 5 keys are generated for the principals in this example).

Login to the SAFE container (already running SAFE Strong server):
```
$ docker exec -ti safe /bin/bash
root@safe:/#
```

Start the SAFE Slang Shell inside the container - we will be issuing commands through the shell to the SAFE server running Strong to test the Strong policy. The shell can be started elsewhere as it communicated using REST with the SAFE server, this is a convenience choice for this simplified example. Change ServerJVM setting in the example below if not running from the same container.

```
$ cd root/SAFE
$ ../sbt/bin/sbt "project safe-lang" "run"
```
You should see the following Slang Shell prompt. Refer to [SAFE Slang](safe-slang.md) document for details about syntax:
```
Welcome to
  ____       _      _____   _____
 / ___|     / \    |  ___| | ____|
 \___ \    / _ \   | |_    |  _|  
  ___) |  / ___ \  |  _|   | |___
 |____/  /_/   \_\ |_|     |_____|

Safe Language v0.1: Fri, 21 Dec 2018 21:18:53 GMT (To quit, press Ctrl+D or q.)
slang>
```
All the following commands are issued to the Slang shell (ignoring comment lines with start with '#' added for readability). To every statement the Shell should return a [satisfied] or [info] response:
```
# Import client slang into the shell
# note that the container mounts SAFE/safe-apps as imports/
slang>import("/imports/strong/strong-client.slang").

# Point the shell to the SAFE server running Strong policy authorizer
strong-1@slang> ?ServerJVM := "localhost:7777".

# Designate five principals for this example and post identity set
# for each of them. Their identities are known to Strong server from
# the 10 keys we generated in principalkeys/
# Every time we issue a ?Self := ... statement, the shell assumes the
# identity of that principal. Strong-client script does the initial
# ?Self := "strong-1" assignment

strong-1@slang> ?P1 := postRawIdSet("strong-1").
strong-1@slang> ?Self := "strong-2".
strong-2@slang> ?P2 := postRawIdSet("strong-2").
strong-2@slang> ?Self := "strong-3".
strong-3@slang> ?P3 := postRawIdSet("strong-3").
strong-3@slang> ?Self := "strong-4".
strong-4@slang> ?P4 := postRawIdSet("strong-4").
strong-4@slang> ?Self := "strong-5".
strong-5@slang> ?P5 := postRawIdSet("strong-5").

# Create 4 UUIDs for namespaces
strong-5@slang> ?UUID1 := "6ec7211c-caaf-4e00-ad36-0cd413accc91".
strong-5@slang> ?UUID2 := "1b924687-a317-4bd7-a54f-a5a0151f49d3".
strong-5@slang> ?UUID3 := "26dbc728-3c8d-4433-9c4b-2e065b644db5".
strong-5@slang> ?UUID4 := "1ef7e6dd-5342-414e-8cce-54e55b3b9a83".

# Create a namespace hierarchy rooted at $P1:$UUID1 and chain
# delegations of sub-namespace along a path from the root to
# $P2:$UUID2, $P3:$UUID3, and $P4:$UUID4.

strong-5@slang> delegateName("project00", $P1, $UUID1, $P2, $UUID2)?
xHjlQ-vLQREF5uwmNw4NdQPHt-TWKEKwo_oTqwtkCj0=@slang> delegateName("dataset00", $P2, $UUID2, $P3, $UUID3)?
H3RFFi8NYRUlAa9wQTPgFzW4RqicobTcdsxnWLxn9S8=@slang> delegateName("part00", $P3, $UUID3, $P4, $UUID4)?

# Check name delegations
TJD9gT4DC4VQXdWNNiIB7MJlAlzqbqCatZ2vO-7Y3Kw=@slang> queryName("$P1:$UUID1", "project00/dataset00/part00")?
[satisfied]

# Tag a directory with a group privilege
H3RFFi8NYRUlAa9wQTPgFzW4RqicobTcdsxnWLxn9S8=@slang> ?Self := $P3.
6U4CtuwUY1CSJeDLVhplcdXKCmd9rGehNLi2tm0kWOc=@slang> postDirectoryAccess("$P5:group0", "$P3:$UUID3")?

# Add a member into the group
slang> ?Self := $P5.
hD_uYbm1ivhX_5Ph5C08_A1MvCAVZfvQq128BQuXjYA=@slang> ?Membership := postGroupMember("$P5:group0", $P5, "true")?
hD_uYbm1ivhX_5Ph5C08_A1MvCAVZfvQq128BQuXjYA=@slang> ?SubjectSet := updateSubjectSet($Membership).

# Exercise access privilege using group membership
hD_uYbm1ivhX_5Ph5C08_A1MvCAVZfvQq128BQuXjYA=@slang> ?ReqEnvs := ":::$SubjectSet".
hD_uYbm1ivhX_5Ph5C08_A1MvCAVZfvQq128BQuXjYA=@slang> ?Self := $P4.
TJD9gT4DC4VQXdWNNiIB7MJlAlzqbqCatZ2vO-7Y3Kw=@slang> accessNamedObject($P5, "project00/dataset00", "$P1:$UUID1")?
[satisfied]
TJD9gT4DC4VQXdWNNiIB7MJlAlzqbqCatZ2vO-7Y3Kw=@slang> accessNamedObject($P5, "project00/dataset00/part00", "$P1:$UUID1")?
[satisfied]

# Access to a directory not covered by a tag will not be authorized.
TJD9gT4DC4VQXdWNNiIB7MJlAlzqbqCatZ2vO-7Y3Kw=@slang> accessNamedObject($P5, "project00", "$P1:$UUID1")?
[unsatisfied]

```
