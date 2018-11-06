ARG TAG="20181106-edge"

FROM huggla/alpine-official:$TAG as alpine

ARG BUILDDEPS="build-base postgresql-dev libffi-dev git python3-dev"
ARG DESTDIR="/pgadmin4"
ARG PGADMIN4_TAG="REL-3_5"

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

FROM scratch as image

COPY --from=alpine /rootfs /apps
