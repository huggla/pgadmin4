ARG TAG="20190206"

FROM huggla/alpine-official as alpine

ARG BUILDDEPS="build-base postgresql-dev libffi-dev git python3-dev libsodium-dev linux-headers"
ARG PGADMIN4_TAG="REL-4_2"

RUN apk add $BUILDDEPS \
 && mkdir -p /rootfs/usr/bin /rootfs/usr/lib/python3.6 \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && pip3 --no-cache-dir install --upgrade pip \
 && pip3 --no-cache-dir install gunicorn \
 && git clone --branch $PGADMIN4_TAG --depth 1 https://git.postgresql.org/git/pgadmin4.git || true \
 && pip3 install --no-cache-dir -r $buildDir/pgadmin4/requirements.txt || true
