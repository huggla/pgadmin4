ARG TAG="20181204"

FROM huggla/pyinstaller-alpine:$TAG as pyinstaller
FROM huggla/python2.7-alpine:$TAG as alpine

ARG BUILDDEPS="build-base postgresql-dev libffi-dev git libsodium-dev linux-headers"
ARG PGADMIN4_TAG="REL-3_6"

RUN apk add $BUILDDEPS \
 && mkdir -p /rootfs/usr/bin /rootfs/usr/lib/python2.7 \
 && buildDir="$(mktemp -d)" \
 && cd $buildDir \
 && pip --no-cache-dir install --upgrade pip \
 && pip --no-cache-dir install gunicorn \
 && git clone --branch $PGADMIN4_TAG --depth 1 https://git.postgresql.org/git/pgadmin4.git \
 && pip install --no-cache-dir -r $buildDir/pgadmin4/requirements.txt \
 && sed -i 's/SERVER_MODE = True/SERVER_MODE = False/' $buildDir/pgadmin4/web/config.py \
 && cp -a $buildDir/pgadmin4/web /rootfs/pgadmin4 \
 && cp -a /usr/local/bin/gunicorn /rootfs/usr/bin/ \
 && cd / \
# && rm -rf $buildDir /rootfs/pgadmin4/regression /rootfs/pgadmin4/pgadmin/feature_tests \
# && find /rootfs/pgadmin4 -name tests -type d | xargs rm -rf \
 && mv -f /rootfs/pgadmin4 /pgadmin4

ARG PIP_PACKAGES="pycrypto"
ARG PYINSTALLER_TAG="v3.4"

COPY --from=pyinstaller /pyinstaller /pyinstaller

RUN apk add zlib-dev musl-dev libc-dev gcc git pwgen upx tk tk-dev build-base binutils \
 && pip --no-cache-dir install $PIP_PACKAGES \
 && git clone --depth 1 --single-branch --branch $PYINSTALLER_TAG https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
 && cd /tmp/pyinstaller/bootloader \
 && python ./waf configure --no-lsb all \
 && pip --no-cache-dir install .. \
 && rm -Rf /tmp/pyinstaller \
 && chmod a+x /pyinstaller/*
 
WORKDIR /pgadmin4

ENV PYTHONOPTIMIZE="2"

RUN /pyinstaller/pyinstaller.sh -y -F --clean pgAdmin4.py setup.py
# && python2.7 -OO -m compileall /pgadmin4 \
# && mv /pgadmin4 /rootfs/pgadmin4 \
# && cp -a /usr/local/lib/python2.7/site-packages /rootfs/usr/lib/python2.7/ \
# && apk --purge del $BUILDDEPS

#FROM node AS node

#COPY --from=alpine /rootfs /rootfs
#COPY --from=alpine /rootfs /

#RUN yarn --cwd /pgadmin4 install \
# && yarn --cwd /pgadmin4 run bundle \
# && yarn cache clean \
# && mkdir -p /rootfs/pgadmin4/pgadmin/static/js/generated \
# && cp -a /pgadmin4/pgadmin/static/js/generated/* /rootfs/pgadmin4/pgadmin/static/js/generated/ \
# && rm -rf /pgadmin4 /rootfs/pgadmin4/babel.cfg /rootfs/pgadmin4/karma.conf.js /rootfs/pgadmin4/package.json /rootfs/pgadmin4/webpack* /rootfs/pgadmin4/yarn.lock /rootfs/pgadmin4/.e* /rootfs/pgadmin4/.p*

#FROM huggla/busybox:$TAG as image

#COPY --from=node /rootfs /apps
