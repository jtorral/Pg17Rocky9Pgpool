#!/bin/bash

if [ ! -f "/pgdata/17/data/PG_VERSION" ]
then
        sudo -u postgres /usr/pgsql-17/bin/initdb -D /pgdata/17/data
        echo "include = 'pg_custom.conf'" >> /pgdata/17/data/postgresql.conf
        cp /pg_custom.conf /pgdata/17/data/
        cp /pg_hba.conf /pgdata/17/data/
        cp /pgsqlProfile /var/lib/pgsql/.pgsql_profile


	# add ssh keys
	mkdir -p /var/lib/pgsql/.ssh
        cp /id_rsa /var/lib/pgsql/.ssh
        cp /id_rsa.pub /var/lib/pgsql/.ssh
        cp /authorized_keys /var/lib/pgsql/.ssh
        chown -R postgres:postgres /var/lib/pgsql/.ssh
        chmod 0700 /var/lib/pgsql/.ssh
        chmod 0600 /var/lib/pgsql/.ssh/*

        chown postgres:postgres /var/lib/pgsql/.pgsql_profile
        chown postgres:postgres /pgdata/17/data/pg_custom.conf
        chown postgres:postgres /pgdata/17/data/pg_hba.conf
        sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data start
        sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD 'postgres';"

        sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data stop

        if [ -z "$PGSTART" ]
        then
           echo
           echo "=========================================================="
           echo "env PGSTART is not set. Skipping auto starting of postgres"
           echo "=========================================================="
           echo
        else
           echo
           echo "=========================================================================="
           echo "env PGSTART is set. Enabling auto starting of postgres on container starts"
           echo "=========================================================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        fi
else
        if [ -z "$PGSTART" ]
        then
           echo
           echo "====================================================="
           echo "env PGSTART is not set. Skipping starting of postgres"
           echo "====================================================="
           echo
           echo "PGSTART not set. Skipping starting of postgres"
        else
           echo
           echo "====================================="
           echo "env PGSTART is set. Starting postgres "
           echo "====================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data start
        fi
fi


# Setup some ssh stuff

if [ ! -f "/etc/ssh/ssh_host_rsa_key" ]
then
   ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''
   ssh-keygen -t dsa -f /etc/ssh/ssh_host_ecdsa_key -N ''
   ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N ''
fi


echo "StrictHostKeyChecking no" >> /etc/ssh/ssh_config

/usr/sbin/sshd

rm -f /run/nologin

# /bin/bash better option than the tail -f especially without a supervisor
# consider using dumb_init in the future as a supervisor https://github.com/Yelp/dumb-init
 
/bin/bash
