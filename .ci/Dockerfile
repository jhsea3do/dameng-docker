FROM centos:centos7.9.2009 AS cmake

COPY .ci/centos.sh   /tmp
RUN \
  bash /tmp/centos.sh && rm -rf /tmp/centos.sh


FROM cmake as builder
ARG DAMENG_IMAGE=dm8_20230104_x86_rh6_64.iso
ARG DAMENG_NAME=dm8-20230104-x86_64-linux

COPY files          /tmp/files
COPY .ci/make.sh   /tmp

ENV DAMENG_IMAGE=$DAMENG_IMAGE
ENV DAMENG_NAME=$DAMENG_NAME

RUN \
  set -x && \
  mkdir -p /dist && \
  cd /tmp && \
  DAMENG_IMAGE=$DAMENG_IMAGE bash make.sh make && \
  DAMENG_IMAGE=$DAMENG_IMAGE bash make.sh arch && \
  rm -rf /tmp/files /tmp/make.sh /tmp/build

FROM centos:centos7.9.2009
ARG DAMENG_IMAGE=dm8_20230104_x86_rh6_64.iso
ARG DAMENG_NAME=dm8-20230104-x86_64-linux

COPY .ci/docker-entrypoint.sh /docker-entrypoint.sh
COPY --from=builder /dist/$DAMENG_NAME.tar.gz /tmp

ENV DAMENG_IMAGE=$DAMENG_IMAGE
ENV DAMENG_NAME=$DAMENG_NAME

RUN \
  set -x && \
  mkdir -p /opt && \
  groupadd -g 5236 dmdba && \
  useradd -u 5236 -g dmdba dmdba

RUN \
  set -x && \
  mkdir -p /opt/Dameng && \
  chown 5236:5236 /opt/Dameng && \
  chmod +x /docker-entrypoint.sh && \
  chown 5236:5236 /tmp/$DAMENG_NAME.tar.gz

USER dmdba

ENTRYPOINT [ "/docker-entrypoint.sh" ]

ENV DM_HOME=/opt/Dameng/dmv8
ENV DM_DATA=/opt/Dameng/data
ENV DM_LOGS=/opt/Dameng/logs

RUN \
  set -x && \
  mkdir -p /opt/Dameng/data /opt/Dameng/logs && \
  tar xzvf /tmp/$DAMENG_NAME.tar.gz -C /opt/Dameng && \
  cd /opt/Dameng && ln -s $DAMENG_NAME dmv8 && \
  rm -rf /tmp/$DAMENG_NAME.tar.gz

WORKDIR "/home/dmdba"

EXPOSE 5236

STOPSIGNAL SIGQUIT
