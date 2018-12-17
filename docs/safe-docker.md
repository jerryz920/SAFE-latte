# SAFE in Docker

## Overview

SAFE is containerized for convenience using docker-compose. Container definitions are located under [dockerfiles](dockerfiles/) directory. Using docker-compose it is possible to stand up both the Riak-based SafeSets instance and the SAFE inference engine/authorizer. Multiple other deployments are possible using this scheme, however the defined containers are primarily intended for use for developing, testing and learning about SAFE. Production deployments would need to be modified the specific requirements of the system.

## Containerized SAFE service

The commands below walk through the steps for launching a SAFE server backed by a SafeSets (a certificate store) through docker-compose. We assume you have got a VM machine (e.g., one obtained from ExoGENI) and have docker-compose installed on it.  

Clone SAFE repository from github
```
$ git clone https://github.com/RENCI-NRIG/SAFE.git
$ cd SAFE
$ git pull origin master
$ git checkout working-session
```

Generate 10 principal keys
```
$ cd utility
$ bash safe_keygen.sh  strong-  10  ../dockerfiles/principalkeys
```

Build docker images for SAFE and SafeSets
```
$ cd ../dockerfiles
$ docker-compose build
```

Launch SafeSets
```
$ docker-compose up riak
$ docker-compose logs riak
```

Launch SAFE (make sure the [start script](../dockerfiles/safe/start.sh) does what you expect - this is deployment-dependent; for testing/hello world you want to simply start the container without starting the SAFE server).
```
$ docker-compose up safe
```
