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

Generate 10 principal keys (primarily for [Strong policy example](safe-strong-hello-world.md))
```
$ cd dockerfiles/
$ ../utility/safe_keygen.sh  strong-  10  ./principalkeys
```

Build docker images for SAFE and SafeSets
```
$ docker-compose build
```

Launch SafeSets in Riak container and wait for them to start
```
$ docker-compose up riak
$ docker-compose logs riak
```

Launch SAFE (make sure the [start script](../dockerfiles/safe/start.sh) does what you expect - this is deployment-dependent; the default setup has it starting a headless SAFE server with Strong policy script)
```
$ docker-compose up safe
```

## Using Docker with Vagrant

There is also an option to run SAFE docker containers inside a Vagrant VM. The definition of the VM is under [vagrant/](vagrant/) directory. Simply

```
$ cd vagrant
$ vagrant up
$ vagrant ssh
```

When you login to the VM as shown above you will be user 'vagrant' with SAFE/ and other prerequisites (including Docker) installed on the VM and docker containers already built. You can do

```
$ docker image ls
```

to see that there are 'safe.local' and 'riak.local' images present. To start the dockers refer to the previous section.
