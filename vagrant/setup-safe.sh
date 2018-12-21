#!/bin/bash

set -eux

# download opennsa
pushd /home/vagrant

# SBT (Scala Build Tool)
SBT_VERSION=1.2.3
wget -q https://github.com/sbt/sbt/releases/download/v${SBT_VERSION}/sbt-${SBT_VERSION}.tgz && tar -zxf sbt-${SBT_VERSION}.tgz 

# SAFE (branch normally set to master)
SAFE_BRANCH="working-session"

git clone https://github.com/RENCI-NRIG/SAFE.git
cd SAFE
git checkout ${SAFE_BRANCH}

# build SAFE dockers
pushd dockerfiles/
docker-compose build

