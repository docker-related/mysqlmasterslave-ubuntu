FROM ubuntu:trusty
MAINTAINER ek <417@xmlad.com>

ENV DEBIAN_FRONTEND noninteractive
ENV HOME /root
RUN apt-mark hold initscripts udev plymouth mountall
RUN dpkg-divert --local --rename --add /sbin/initctl && ln -sf /bin/true /sbin/initctl

RUN apt-get install -y --force-yes --no-install-recommends wget
ADD sources.list.alicloud /
RUN wget -qO- ipinfo.io | grep "country.*CN" && cp /sources.list.alicloud /etc/apt/sources.list || return 0
RUN rm /sources.list.alicloud

RUN apt-get update \
    && apt-get install -y --force-yes --no-install-recommends \
        openssh-server sudo \
        net-tools \
    && apt-get autoclean \
    && apt-get autoremove \
    && rm -rf /var/lib/apt/lists/*
ADD run.sh /
ADD install.sh /
RUN chmod 755 /run.sh
RUN chmod 755 /install.sh
EXPOSE 3386
EXPOSE 22
WORKDIR /
ENTRYPOINT ["/run.sh"]
RUN /run.sh