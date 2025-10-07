FROM rockylinux:9


RUN \
  dnf -y update \
  && dnf install -y wget \
  && dnf install -y https://dl.rockylinux.org/pub/rocky/9/CRB/x86_64/os/Packages/l/libmemcached-awesome-1.1.0-12.el9.x86_64.rpm \
  && dnf --enablerepo=crb install libmemcached-awesome \
  && dnf install -y telnet \
  && dnf install -y jq \
  && dnf install -y vim \
  && dnf install -y sudo \
  && dnf install -y gnupg \
  && dnf install -y openssh-server \
  && dnf install -y openssh-clients \
  && dnf install -y procps-ng \
  && dnf install -y net-tools \
  && dnf install -y iputils \
  && dnf install -y iproute \
  && dnf install -y less \
  && dnf install -y diffutils \
  && dnf install -y watchdog \
  && dnf install -y https://download.postgresql.org/pub/repos/yum/reporpms/EL-9-x86_64/pgdg-redhat-repo-latest.noarch.rpm \
  && dnf -qy module disable postgresql \
  && dnf install -y postgresql17-server \
  && dnf install -y postgresql17-contrib \
  && dnf install -y epel-release \
  && dnf install -y libssh2 \
  && dnf install -y iputils \
  && dnf install -y pg_repack_17 \
  && dnf install -y pg_top \
  && dnf install -y pg_activity \
  && dnf install -y https://www.pgpool.net/yum/rpms/4.6/redhat/rhel-9-x86_64/pgpool-II-release-4.6-1.noarch.rpm \
  && dnf install -y pgpool-II-pg17 \
  && dnf install -y pgpool-II-pg17-extensions

RUN mkdir -p /pgdata/17/

RUN chown -R postgres:postgres /pgdata
RUN chmod 0700 /pgdata

RUN chown -R postgres:postgres /etc/pgpool-II

COPY pg_custom.conf /
COPY pg_hba.conf /
COPY pg_hba_md5.conf /
COPY pgsqlProfile /
COPY id_rsa /
COPY id_rsa.pub /
COPY authorized_keys /
COPY recovery_1st_stage /
COPY follow_primary.sh /
COPY pgpool_remote_start /
COPY failover.sh /

RUN chown postgres:postgres /recovery_1st_stage
RUN chown postgres:postgres /follow_primary.sh
RUN chown postgres:postgres /pgpool_remote_start
RUN chown postgres:postgres /failover.sh

EXPOSE 22 80 443 5432 9999 9898 

COPY entrypoint.sh /

RUN chmod +x /entrypoint.sh 

SHELL ["/bin/bash", "-c"]
ENTRYPOINT /entrypoint.sh

