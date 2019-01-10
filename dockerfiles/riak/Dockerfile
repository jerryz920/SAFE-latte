from ubuntu:14.04

RUN apt-get update && apt-get install -y build-essential
RUN apt-get install -y gdb
RUN apt-get install -y default-jdk
RUN apt-get install -y git curl make htop vim emacs wget

RUN apt-get install -y libssl1.0.0
RUN apt-get install -y libpam0g-dev
RUN apt-get install -y libssl-dev

# install riak
RUN curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash
RUN apt-get install -y riak=2.2.3-1

COPY start.sh   /root/
COPY test.sh    /root/

EXPOSE 8098 8087

ENTRYPOINT ["/bin/bash", "/root/start.sh"]
#ENTRYPOINT ["/bin/sh", "-c"]
