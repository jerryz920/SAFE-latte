# SAFE in Docker

## Overview

SAFE is containerized for convenience using docker-compose. Container definitions are located under [dockerfiles](dockerfiles/) directory. Using docker-compose it is possible to stand up both the Riak-based SafeSets instance and the SAFE inference engine/authorizer. Multiple other deployments are possible using this scheme, however the defined containers are primarily intended for use for developing, testing and learning about SAFE. Production deployments would need to be modified the specific requirements of the system.


## Installing prerequisites

The commands below walk through the steps for launching a SAFE server backed by a SafeSets (a certificate store) through docker-compose. We assume you have got a VM machine (e.g., one obtained from ExoGENI) and have docker-compose installed on it.  

Clone SAFE repository from github
```
$ git clone https://github.com/RENCI-NRIG/SAFE.git
$ cd SAFE
$ git pull origin master
$ git checkout working-session
```

## Containerized SAFE service

Generate 10 principal keys (to be used for [Strong policy example](safe-strong-hello-world.md))
```
$ cd dockerfiles/
$ ../utility/safe_keygen.sh  strong-  10  ./principalkeys
```

It is important that the keys exist under dockerfiles/principalkeys as docker-compose.yml makes a mount point for SAFE container using this directory. It is also important the keys are named strong-1, strong-2 etc. as the Strong example script expects that convention.

Build docker images for SAFE and SafeSets
```
$ docker-compose build
```

Launch SafeSets in Riak container as a daemon and wait for them to start:
```
$ docker-compose up -d riak
$ docker-compose logs riak
```

Wait until you see something like
```
Attaching to riak
riak    | pong
riak    | safesets created
riak    |
riak    | WARNING: After activating safesets, nodes in this cluster
riak    | can no longer be downgraded to a version of Riak prior to 2.0
riak    | safesets has been activated
riak    |
riak    | WARNING: Nodes in this cluster can no longer be
riak    | downgraded to a version of Riak prior to 2.0
riak    | safesets updated
riak    |   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
riak    |                                  Dload  Upload   Total   Spent    Left  Speed
100    19    0     0  100    19      0    119 --:--:-- --:--:-- --:--:--   120
riak    |   % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
riak    |                                  Dload  Upload   Total   Spent    Left  Speed
100    19  100    19    0     0   2402      0 --:--:-- --:--:-- --:--:--  2714
```
Launch SAFE (make sure the [start script](../dockerfiles/safe/start.sh) does what you expect - this is deployment-dependent; the default setup has it starting a headless SAFE server with Strong policy script)
```
$ docker-compose up safe
```

After a while you will see a list of remote methods defined on the server, which should look like

```
safe    | Time used to compile all sources: 50392 ms
safe    | Time used to compile and assemble all code: 50882 ms
safe    | MethodName: accessNamedObject
safe    | MethodName: updateSubjectSet
safe    | MethodName: queryName
safe    | MethodName: postGroupMember
safe    | MethodName: postDirectoryAccess
safe    | MethodName: postMembershipDelegation
safe    | MethodName: updateIDSet
safe    | MethodName: updateNameObjectSet
safe    | MethodName: updateGroupSet
safe    | MethodName: postNameDelegation
safe    | MethodName: postRawIdSet
safe    | MethodName: loadingSlangFromIP
safe    | MethodName: queryMembership
safe    | MethodName: postGroupDelegation
safe    | MethodName: postIdSet
safe    | MethodName: postSubjectSet
safe    | MethodName: whoami
```

After completing running the example you can delete the docker containers as follows:
```
docker-compose down
```

Individual docker containers can be stopped and restarted using `docker-compose start <safe|riak>` and `docker-compose stop <safe|riak>`.

## Using Docker with Vagrant

There is also an option to run SAFE docker containers inside a Vagrant VM. Make sure Vagrant is installed and also has the `vagrant-reload` plugin:

```
$ vagrant plugin install vagrant-reload
$ vagrant plugin list
vagrant-reload (0.0.1)
```
The definition of the VM is under [vagrant/](vagrant/) directory. Simply

```
$ cd vagrant
$ vagrant up
```
wait for a long  time (ignore code warnings), then login to the VM:
```
$ vagrant ssh
```

When you login to the VM as shown above you will be user 'vagrant' with SAFE/ and other prerequisites (including Docker) installed on the VM and docker containers already built. You can do

```
$ docker image ls
```

to see that there are 'safe.local' and 'riak.local' images present. To start the dockers refer to the previous section.

Vagrant VM can be stopped with `vagrant halt`.
