from ubuntu:18.04

RUN apt-get update && apt-get install -y build-essential
RUN apt-get install -y gdb
RUN apt-get install -y default-jdk
RUN apt-get install -y git curl make htop vim emacs wget

RUN apt-get install -y libssl1.0.0
RUN apt-get install -y libpam0g-dev
RUN apt-get install -y libssl-dev

# install riak
# RUN curl -s https://packagecloud.io/install/repositories/basho/riak/script.deb.sh | bash
# RUN apt-get install -y riak=2.2.3-1
RUN wget -O - https://packages.erlang-solutions.com/erlang/riak/FLAVOUR_1_main/riak_2.2.5-1~ubuntu~bionic_amd64.deb >  riak_2.2.5.deb
RUN dpkg -i riak_2.2.5.deb

COPY start.sh   /root/
COPY test.sh    /root/

EXPOSE 8098 8087

ENTRYPOINT ["/bin/bash", "/root/start.sh"]
#ENTRYPOINT ["/bin/sh", "-c"]