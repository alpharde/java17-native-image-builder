FROM ghcr.io/alpharde/docker-build:latest AS builder

RUN mkdir -p /usr/src
RUN git clone https://github.com/richfelker/musl-cross-make -b v0.9.9 /usr/src/musl-cross-make
COPY config.mak /usr/src/musl-cross-make/config.mak
RUN cd /usr/src/musl-cross-make &&\
    make &&\
    make install

RUN git clone https://github.com/madler/zlib -b v1.2.12 /usr/src/zlib
RUN export PATH=$PATH:/opt/cross/bin &&\
    which x86_64-linux-musl-gcc &&\
    cd /usr/src/zlib &&\
    CC=x86_64-linux-musl-gcc ./configure --static --prefix=/opt/cross/x86_64-linux-musl &&\
    make CC=x86_64-linux-musl-gcc &&\
    make install

FROM debian:stable-slim

ARG JAVA=17
ARG VER=22.1.0

COPY --from=builder /opt/cross /opt/cross
COPY "https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-${VER}/graalvm-ce-java${JAVA}-linux-amd64-${VER}.tar.gz" "/root/graalvm-ce-java${JAVA}-linux-amd64-${VER}.tar.gz"

RUN tar xvf "/root/graalvm-ce-java${JAVA}-linux-amd64-${VER}.tar.gz" -C /opt

RUN mkdir -p /root/graalconf &&\
    cd "/opt/graalvm-ce-java${JAVA}-${VER}/bin" &&\
    ./gu install native-image
