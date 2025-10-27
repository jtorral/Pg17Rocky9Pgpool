#!/bin/bash

if [ ! -f "/pgdata/17/data/PG_VERSION" ]
then
        sudo -u postgres /usr/pgsql-17/bin/initdb -D /pgdata/17/data
        echo "include = 'pg_custom.conf'" >> /pgdata/17/data/postgresql.conf
        cp /pg_custom.conf /pgdata/17/data/
        cp /pg_hba.conf /pgdata/17/data/
        cp /pgsqlProfile /var/lib/pgsql/.pgsql_profile

        if [ -n "$MD5" ]
        then
           echo 
           echo "=========================================================="
           echo "env MD5 is set. Setting postgres to use md5 authentication"
           echo "=========================================================="
           echo 
           cp /pg_hba_md5.conf /pgdata/17/data/pg_hba.conf
           echo "password_encryption = md5 " >> /pgdata/17/data/pg_custom.conf
        fi

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

        if [ ! -z "$PGPASSWORD" ]
        then
           echo 
           echo "=========================================================="
           echo "env PGPASSWORD is set. Setting postgres password"
           echo "=========================================================="
           echo 
           sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD '$PGPASSWORD';"
        else
           echo 
           echo "=========================================================================="
           echo "env PGPASSWORD is not set. Setting default postgres password of \"postgres\""
           echo "=========================================================================="
           echo 
           sudo -u postgres psql -c "ALTER ROLE postgres PASSWORD 'postgres';"
        fi
           
        sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data stop

        if [ -n "$PGSTART" ]
        then
           echo
           echo "=========================================================================="
           echo "env PGSTART is set. Enabling auto starting of postgres on container starts"
           echo "=========================================================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        else
           echo
           echo "=========================================================="
           echo "env PGSTART is not set. Skipping auto starting of postgres"
           echo "=========================================================="
           echo
           echo "PGSTART not set. Skipping starting of postgres"
        fi

else

        if [ -n "$PGSTART" ]
        then
           echo
           echo "=========================================================================="
           echo "env PGSTART is set. Enabling auto starting of postgres on container starts"
           echo "=========================================================================="
           echo
           sudo -u postgres /usr/pgsql-17/bin/pg_ctl -D /pgdata/17/data restart
        else
           echo
           echo "=========================================================="
           echo "env PGSTART is not set. Skipping auto starting of postgres"
           echo "=========================================================="
           echo
           echo "PGSTART not set. Skipping starting of postgres"
        fi

fi


# -- Lets create preconfigure or not based on preset env variable

if [ -z "$DONTPRECONFIG" ]
then

   echo
   echo "==============================================================="
   echo "env DONTPRECONFIG is not set. Applying preconfig to some files "
   echo "==============================================================="
   echo

   # -- Setup sudoers
   echo "postgres ALL=NOPASSWD: /usr/sbin/ip  " >> /etc/sudoers
   echo "postgres ALL=NOPASSWD: /usr/sbin/arping " >> /etc/sudoers

   # -- Copy some preconfigures scripts
   cp -p /recovery_1st_stage /etc/pgpool-II/
   cp -p /follow_primary.sh /etc/pgpool-II/
   cp -p /pgpool_remote_start /etc/pgpool-II/
   cp -p /failover.sh /etc/pgpool-II/

else

   echo
   echo "================================================================================="
   echo "env DONTPRECONFIG is set. Not applying preconfigs so you have to manually do them"
   echo 
   echo "This includes making changes to :"
   echo "/etc/sudoers"
   echo "Modifying the recovery scripts for Pgpool"
   echo "================================================================================="
   echo

fi



# Setup some ssh stuff

echo
echo "======================================================================"
echo "Doing some ssh voodoo so you don't have to. Even if you dont preconfig"
echo "======================================================================"
echo 

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
