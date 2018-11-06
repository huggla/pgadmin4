ARG TAG="20181106-edge"

FROM huggla/alpine-official:$TAG as alpine

ARG BUILDDEPS="build-base postgresql-dev libffi-dev git python3-dev"
ARG DESTDIR="/pgadmin4"
ARG PGADMIN4_TAG="REL-3_3"

RUN apk --no-cache add $BUILDDEPS \
 && mkdir -p /rootfs/usr/local/bin /rootfs/usr/lib/python3.6 \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && pip3 --no-cache-dir install --upgrade pip \
 && pip3 --no-cache-dir install gunicorn \
 && git clone --branch $PGADMIN4_TAG --depth 1 https://git.postgresql.org/git/pgadmin4.git \
 && pip3 install --no-cache-dir -r $buildDir/pgadmin4/requirements.txt \
 && cp -a $buildDir/pgadmin4/web "/rootfs$DESTDIR" \
 && cp -a /usr/bin/gunicorn /rootfs/usr/local/bin/ \
 && rm -rf $buildDir /rootfs$DESTDIR/regression /rootfs$DESTDIR/pgadmin/feature_tests \
 && find /rootfs$DESTDIR -name tests -type d | xargs rm -rf \
 && mv /rootfs$DESTDIR / \
 && python3.6 -O -m compileall $DESTDIR \
 && mv $DESTDIR /rootfs/ \
 && cp -a /usr/lib/python3.6/site-packages /rootfs/usr/lib/python3.6/ \
 && apk --no-cache --purge del $BUILDDEPS

FROM node:6 AS node

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
