#!/bin/bash

if [[ "$USER" != "root" ]]; then
  echo "script must run as root"
  exit 1
fi

set -eux

# dependencies
apt-get update -y
apt-get install -y apt-transport-https ca-certificates curl software-properties-common git wget
apt-get install -y gdb default-jdk python git curl make htop wget libssl1.0.0 libpam0g-dev libssl-dev python-crypto

# docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
apt-get update -y
apt-get install -y docker-ce

# docker-compose
curl -L "https://github.com/docker/compose/releases/download/1.23.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose >& /dev/null
chmod +x /usr/local/bin/docker-compose
curl -L https://raw.githubusercontent.com/docker/compose/1.23.1/contrib/completion/bash/docker-compose -o /etc/bash_completion.d/docker-compose >& /dev/null

# docker user
usermod -aG docker vagrant

