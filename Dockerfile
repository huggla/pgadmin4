ARG TAG="20181204"

FROM huggla/alpine-official:$TAG as alpine

ARG BUILDDEPS="build-base postgresql-dev libffi-dev git python3-dev libsodium-dev linux-headers"
ARG PGADMIN4_TAG="REL-3_5"

RUN apk add $BUILDDEPS \
 && mkdir -p /rootfs/usr/bin /rootfs/usr/lib/python3.6 \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && pip3 --no-cache-dir install --upgrade pip \
 && pip3 --no-cache-dir install gunicorn \
 && git clone --branch $PGADMIN4_TAG --depth 1 https://git.postgresql.org/git/pgadmin4.git \
 && pip3 install --no-cache-dir -r $buildDir/pgadmin4/requirements.txt \
 && cp -a $buildDir/pgadmin4/web /rootfs/pgadmin4 \
 && cp -a /usr/bin/gunicorn /rootfs/usr/bin/ \
 && rm -rf $buildDir /rootfs/pgadmin4/regression /rootfs/pgadmin4/pgadmin/feature_tests \
 && find /rootfs/pgadmin4 -name tests -type d | xargs rm -rf \
 && mv /rootfs/pgadmin4 /pgadmin4 \
 && python3.6 -OO -m compileall /pgadmin4 \
 && mv /pgadmin4 /rootfs/pgadmin4 \
 && cp -a /usr/lib/python3.6/site-packages /rootfs/usr/lib/python3.6/ \
 && apk --purge del $BUILDDEPS

FROM node AS node

COPY --from=alpine /rootfs /rootfs
COPY --from=alpine /rootfs /

RUN yarn --cwd /pgadmin4 install \
 && yarn --cwd /pgadmin4 run bundle \
 && yarn cache clean \
 && mkdir -p /rootfs/pgadmin4/pgadmin/static/js/generated \
 && cp -a /pgadmin4/pgadmin/static/js/generated/* /rootfs/pgadmin4/pgadmin/static/js/generated/ \
 && rm -rf /pgadmin4 /rootfs/pgadmin4/babel.cfg /rootfs/pgadmin4/karma.conf.js /rootfs/pgadmin4/package.json /rootfs/pgadmin4/webpack* /rootfs/pgadmin4/yarn.lock /rootfs/pgadmin4/.e* /rootfs/pgadmin4/.p*

FROM huggla/busybox:$TAG as image

COPY --from=node /rootfs /apps
