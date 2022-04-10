FROM debian:buster-slim AS build

# Image metadata
# git commit
LABEL org.opencontainers.image.revision="-"
LABEL org.opencontainers.image.source="https://github.com/jkaldon/arm64v8-pocketcoin/tree/master"

ARG POCKETNET_CORE_BASE_URL=https://github.com/pocketnetteam/pocketnet.core.git
ARG POCKETNET_CORE_TAG=v0.20.19

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
  apt-get install -y \
    curl \
    build-essential \
    binutils-gold \
    bsdmainutils \
    autotools-dev \
    automake \
    libtool \
    libtool-bin \
    python3 \
    git \
    ccache \
    gettext \
    lcov \
    doxygen \
    cpio \
    pkg-config

RUN \
  git clone --depth 1 --branch $POCKETNET_CORE_TAG $POCKETNET_CORE_BASE_URL /usr/local/src/pocketcoin
 
# These RUN commands are broken up this way to improve
# build cycle times when something goes wrong.  Since 
# this is the "build" stage of a multistage dockerfile,
# I don't believe it makes a huge difference in the
# resulting docker image's layers.
RUN \
  cd /usr/local/src/pocketcoin/depends && \
  sed -i 's/_version=1\.2\.11/_version=1.2.12/' packages/zlib.mk && \
  sed -i 's/_sha256_hash=c3e5e9fdd5004dcb542feda5ee4f0ff0744628baf8ed2dd5d66f8ca1197cb1a1/_sha256_hash=91844808532e5ce316b3c010929493c0244f3d37593afd6de04f71821d5136d9/' packages/zlib.mk && \
  head packages/zlib.mk && \
  make download-linux && \
  make NO_QT=1

RUN \
  cd /usr/local/src/pocketcoin && \
  ./autogen.sh

RUN \
  cd /usr/local/src/pocketcoin && \
  ./configure --enable-cxx --disable-shared --with-pic --prefix=$PWD/depends/aarch64-unknown-linux-gnu --enable-glibc-back-compat --enable-reduce-exports LDFLAGS=-static-libstdc++

RUN \
  cd /usr/local/src/pocketcoin && \
  make

RUN \
  cd /usr/local/src/pocketcoin && \
  make install

FROM debian:buster-slim AS image

COPY --from=build /usr/local/src/pocketcoin/depends/aarch64-unknown-linux-gnu/ /usr/local/

RUN \
  apt-get update && \
  apt-get install -y python3 && \
  useradd -d /home/pocketcoin -m -s /usr/sbin/nologin pocketcoin && \
  mkdir /data && \
  chown -R pocketcoin.pocketcoin /data

USER pocketcoin

COPY --chown=pocketcoin:pocketcoin resources/* /home/pocketcoin/
COPY --chown=pocketcoin:pocketcoin --from=build /usr/local/src/pocketcoin/checkpoints/main.sqlite3 /home/pocketcoin/main.sqlite3.init
COPY --chown=pocketcoin:pocketcoin --from=build /usr/local/src/pocketcoin/share/rpcauth/rpcauth.py /home/pocketcoin/

RUN \
  ln -s /data/pocketcoin /home/pocketcoin/.pocketcoin && \
  chmod +x /home/pocketcoin/rpcauth.py

WORKDIR /home/pocketcoin

CMD [ \
  "/usr/local/bin/pocketcoind", \
  "-server", \
  "-pid=/home/pocketcoin/pocketcoind.pid", \
  "-conf=/home/pocketcoin/.pocketcoin/pocketcoin.conf", \
  "-datadir=/home/pocketcoin/.pocketcoin" \
]

