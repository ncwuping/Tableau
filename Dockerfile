# base image is centos default image
FROM centos

ENV container=docker

# who's the owner?
MAINTAINER "Wu Ping" <ncwuping@hotmail.com>

# this is the version what we're building
ENV TABLEAU_VERSION="2018.3.7" \
    LANG=en_US.UTF-8

# make systemd dbus visible 
VOLUME /sys/fs/cgroup /run /tmp /var/opt/tableau

COPY config/lscpu /usr/bin/

# Install core bits and their deps:w
RUN yum clean all -y && yum makecache fast && yum update -y; \
    (cd /lib/systemd/system/sysinit.target.wants/; for i in *; do [ $i == systemd-tmpfiles-setup.service ] || rm -f $i; done); \
    rm -f /lib/systemd/system/multi-user.target.wants/*; \
    rm -f /etc/systemd/system/*.wants/*; \
    rm -f /lib/systemd/system/local-fs.target.wants/*; \
    rm -f /lib/systemd/system/sockets.target.wants/*udev*; \
    rm -f /lib/systemd/system/sockets.target.wants/*initctl*; \
    rm -f /lib/systemd/system/basic.target.wants/*; \
    rm -f /lib/systemd/system/anaconda.target.wants/*; \
    yum install -y epel-release \
 && yum clean all -y && yum install -y iproute sudo vim \
 && adduser tsm \
 && (echo tsm:tsm | chpasswd) \
 && (echo 'tsm ALL=(ALL) NOPASSWD:ALL' > /etc/sudoers.d/tsm) \
 && mkdir -p /run/systemd/system /opt/tableau/docker_build \
 && chmod +x /usr/bin/lscpu \
 && yum install -y \
             "https://downloads.tableau.com/esdalt/${TABLEAU_VERSION}/tableau-server-${TABLEAU_VERSION//\./-}.x86_64.rpm" \
             "https://downloads.tableau.com/drivers/linux/yum/tableau-driver/tableau-postgresql-odbc-9.5.3-1.x86_64.rpm" \
 && rm -rf /var/tmp/yum-* /var/cache/yum


COPY config/* /opt/tableau/docker_build/

RUN chmod +x /opt/tableau/docker_build/tableau-init-configure.sh \
 && mkdir -p /etc/systemd/system/ \
 && cp /opt/tableau/docker_build/tableau_server_install.service /etc/systemd/system/ \
 && systemctl enable tableau_server_install 

# Expose TSM and Gateway ports
EXPOSE 80 8850

CMD /sbin/init
