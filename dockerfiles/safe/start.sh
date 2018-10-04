#!/bin/bash
# Run SAFE server

cd ~/SAFE

# Set up: configuration the storage server for SAFE
sed -i "/.*url = \"http/ s:.*:    url = \"http\://${RIAK_IP}\:8098/types/safesets/buckets/safe/keys\":" safe-server/src/main/resources/application.conf

strong_root=`python /root/hash_gen.py /principalkeys/${STRONG_ROOT_PUB}`

sed -i "/.*defenv RootDir()/ s:.*:defenv RootDir() \:- \"${strong_root}\:root\"\.:" /imports/${SLANG_CONF}

# Run
~/sbt/bin/sbt "project safe-server" "run -f /imports/${SLANG_SCRIPT} -r safeService  -kd  /principalkeys"

#bash ~/test.sh
/bin/bash
