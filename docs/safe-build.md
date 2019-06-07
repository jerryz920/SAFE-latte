# Building SAFE

## Overview

SAFE is written in Scala and uses a (mostly) off-the shelf implementation of SafeSets based on Riak key-value store.

## Prerequisites

### Riak

The best way to understand how Riak is installed is to inspect the
Riak [Dockerfile](../dockerfiles/riak/Dockerfile).  Riak is a
stand-in for a cooperative key-value store (e.g., a DHT) required by SAFE.

### SAFE

Most of the details are similarly contained in the SAFE [Dockerfile](../dockerfiles/safe/Dockerfile). A brief summary:

Install bundled prerequisites:
```
apt-get install -y gdb default-jdk python git curl make htop wget libssl1.0.0 libpam0g-dev libssl-dev python-crypto
```
Install SBT version 1.2.3
```
SBT_VERSION=1.2.3
wget https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz && cd ~/ && tar -zxvf sbt-${SBT_VERSION}.tgz
export PATH=/wherever/sbt/bin:$PATH
```
Install SAFE
```
git clone https://github.com/RENCI-NRIG/SAFE.git
```


## Building  and configuring

### Riak

Update /etc/riak/riak.conf to use your host's IP address:
```
listener.http.internal = ${internal_ip}:8098
listener.protobuf.internal = ${internal_ip}:8087
riak@${internal_ip}
```

Initialize Riak
```
riak start
riak ping
riak-admin bucket-type create safesets '{"props":{"n_val":1, "w":1, "r":1, "pw":1, "pr":1}}'
riak-admin bucket-type activate safesets
riak-admin bucket-type update safesets '{"props":{"allow_mult":false}}'
```

Test Riak
```
RIAK_IP=`hostname -i`

curl -XPUT  http://${RIAK_IP}:8098/types/safesets/buckets/safe/keys/b5SCs-dUqRWMvs1GbwvwRC9Pi9yHYuSVj6oxLSU8wXs  -H 'Content-Type: text/plain'   -d 'herzlich willkommen'

curl http://${RIAK_IP}:8098/types/safesets/buckets/safe/keys/b5SCs-dUqRWMvs1GbwvwRC9Pi9yHYuSVj6oxLSU8wXs
```
Expected response: herzlich willkommen

### SAFE

Compile SAFE
```
$ cd SAFE/
$ sbt "project safe-server" "compile"
```

Generate principal identities
```
$ mkdir principalkeys
$ utility/safe-keygen.sh key- 10 principalkeys/
```

Configure to talk to SafeSets/Riak by modifying safe-server/src/main/resources/application.conf
```
url = "http://${RIAK_IP}:8098/types/safesets/buckets/safe/keys
```

Run SAFE shell
```
sbt “project safe-lang” “run”
```

or run SAFE server
```
export SLANG_SCRIPT="strong/strong-client.slang"
sbt "project safe-server" "run -f safe-apps/${SLANG_SCRIPT} -r safeService  -kd  principalkeys/"
```
