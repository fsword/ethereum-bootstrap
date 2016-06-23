FROM ethereum/client-go
MAINTAINER fsword

RUN sed -i -e 's/archive.ubuntu.com/mirrors.ustc.edu.cn/g' /etc/apt/sources.list
RUN apt-get update && apt-get install solc -y

RUN mkdir /ethereum /data
VOLUME /data

ADD . /ethereum/
WORKDIR /ethereum

RUN ["bin/import_keys.sh"]

ENTRYPOINT ["./bin/private_blockchain.sh"]
