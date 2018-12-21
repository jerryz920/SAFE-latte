#!/bin/bash
# Run SAFE server

cd ~/SAFE

# Set up: configuration the storage server for SAFE
sed -i "/.*url = \"http/ s:.*:    url = \"http\://${RIAK_IP}\:8098/types/safesets/buckets/safe/keys\":" safe-server/src/main/resources/application.conf

# turn on server log
# sed -i "/.*<root level=\"error/ s:.*:    <root level=\"info\">:" safe-server/src/main/resources/logback.xml

strong_root=`python /root/hash_gen.py /principalkeys/${STRONG_ROOT_PUB}`

sed -i "/.*defenv RootDir()/ s:.*:defenv RootDir() \:- \"${strong_root}\:root\"\.:" /imports/strong/${SLANG_CONF}

# Run the strong server
~/sbt/bin/sbt "project safe-server" "run -f /imports/strong/${SLANG_SCRIPT} -r safeService  -kd  /principalkeys"
# Start the CLI
#~/sbt/bin/sbt "project safe-lang" "run" 

exec "${@}"
