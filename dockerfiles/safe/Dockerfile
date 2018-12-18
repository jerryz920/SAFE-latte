from ubuntu:18.04

RUN apt-get update && apt-get install -y build-essential
RUN apt-get install -y gdb default-jdk python git curl make htop wget libssl1.0.0 libpam0g-dev libssl-dev python-crypto python

# Install sbt
ENV SBT_VERSION 1.2.3
RUN cd ~/ && wget https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz && cd ~/ && tar -zxvf sbt-${SBT_VERSION}.tgz

# Download SAFE
RUN cd ~/ && git clone https://github.com/RENCI-NRIG/SAFE.git
RUN cd ~/SAFE && git pull origin master && git checkout working-session

# Compile SAFE
RUN cd ~/SAFE && ~/sbt/bin/sbt "project safe-server" "compile"

COPY start.sh     /root/
COPY test.sh      /root/
RUN cd ~/SAFE && cp utility/safe_keygen.sh /root/ && cp utility/hash_gen.py /root/

VOLUME ["/imports", "/principalkeys"]
ENTRYPOINT ["/bin/bash", "/root/start.sh"]
#ENTRYPOINT ["/bin/sh", "-c", "tail -f /dev/null"]
