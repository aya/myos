# from: https://github.com/thorsten-l/389ds-docker-alpine
FROM --platform=$BUILDPLATFORM alpine:3.19 as builder
ARG TARGETPLATFORM
ARG BUILDPLATFORM
RUN echo "*** BUILDPLATFORM=$BUILDPLATFORM TARGETPLATFORM=$TARGETPLATFORM"

ARG BUILD_VERSION
ARG DOCKER_BUILD_DIR

RUN apk add build-base wget libtool autoconf automake openssl-dev cracklib-dev \
            libevent-dev nspr-dev nss-dev openldap-dev db-dev icu-dev \
            net-snmp-dev krb5-dev pcre-dev make rsync nss-tools openssl \
            linux-pam-dev python3 py3-pip python3-dev git py3-setuptools \
            py3-argcomplete py3-ldap3 py3-dateutil lmdb-dev json-c-dev pcre2-dev

RUN if [ "$TARGETPLATFORM" != "linux/arm/v7" ]; then apk add rust cargo ; fi 

RUN mkdir /build
WORKDIR /build
RUN wget "https://github.com/389ds/389-ds-base/archive/refs/tags/389-ds-base-$BUILD_VERSION.tar.gz"
RUN tar xvfz "389-ds-base-$BUILD_VERSION.tar.gz"
WORKDIR "/build/389-ds-base-389-ds-base-$BUILD_VERSION"

RUN ./autogen.sh
RUN if [ "$TARGETPLATFORM" != "linux/arm/v7" ]; then ./configure --with-openldap --enable-rust ; fi 
RUN if [ "$TARGETPLATFORM" == "linux/arm/v7" ]; then ./configure --with-openldap; fi 

RUN sed -e 's/.*build_manpages.*/\tcd \$\(srcdir\)\/src\/lib389\; \$\(PYTHON\) setup.py build/g' Makefile > M
RUN mv M Makefile

COPY ${DOCKER_BUILD_DIR}/setup.py src/lib389/setup.py

RUN echo "@testing https://dl-cdn.alpinelinux.org/alpine/edge/testing" >> /etc/apk/repositories \
 && apk add zig@testing

RUN make -j 8 && make lib389 -j 8 && make install && make lib389-install

FROM alpine:3.19 

RUN apk add openssl cracklib libevent nspr nss openldap db icu \
            net-snmp krb5 pcre nss-tools openssl linux-pam python3 \
            lmdb json-c pcre2 elfutils libffi libexpat 

COPY --from=builder /opt /opt
COPY --from=builder /usr/sbin/ds* /usr/sbin/
COPY --from=builder /usr/lib/python3.10 /usr/lib/python3.10
COPY --from=builder /usr/libexec/dirsrv /usr/libexec/dirsrv

RUN mkdir -p /data /data/config /data/run /opt/dirsrv/var/run/dirsrv; \
    ln -s /data/run /opt/dirsrv/var/run/dirsrv; \
    ln -s /data/ssca /opt/dirsrv/etc/dirsrv/ssca; \
    ln -s /data/config /opt/dirsrv/etc/dirsrv/slapd-localhost 

HEALTHCHECK --start-period=5m --timeout=5s --interval=5s --retries=2 \
    CMD /usr/libexec/dirsrv/dscontainer -H

WORKDIR /data
VOLUME /data

EXPOSE 3389 3636

CMD [ "/usr/libexec/dirsrv/dscontainer", "-r" ]
