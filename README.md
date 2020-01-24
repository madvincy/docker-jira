docker-jira
====================

Docker compose file for running jira


Contents
-------------
docker-compose file, traefik and .env template for running Jira 

Remark:
SETENV_JVM_SUPPORT_RECOMMENDED_ARGS environment is used to be able to set the -XX:ReservedCodeCacheSize= parameter in Java. This should be possible using the SETENV_JVM_CODE_CACHE_ARGS but the entrypoint script which modifies the /opt/jira/bin/setenv.sh file does not seem to like space separated values. 


Instruction building image
-------------
No special instructions.

```

```

Instruction running docker-compose.yml
-------------

The repository is compatible with the puppet naturalis/puppet-docker_compose manifest and can be deployed using that manifests. 

#### preparation
- Copy env.template to .env and adjust variables. 


````
docker-compose up -d
````

Backup / Restore
-------------
For rsync / database backup from restic functionality a restore_and_sync.sh script is available in the custom folder. This can be run interactive and depends on: 
in general this will be configured as a post restore script in restic
on the receiving server. 
- database dump file in /var/backup/pgsql/pgsql_jiradb.dump
- docker-compose.yml should be in /opt/composeproject
- RSYNC_SOURCE variable in .env , the DNS name of the source/prod server
- SSH passwordless key pair with private key in /opt/composeproject/.jirarsync.key 
- logrotate for /var/log/jira/*.log
on the source/ prod server
- jirarsync user with public key in authorised_keys
- data of jira in directory /data/jira/data and owner:group should be ubuntu:jirarsync


Usage
-------------

If there is a valid traefik.toml with or without SSL then both services can be accessed through port 80/443. 
It is advised to setup firewall rules and only allow 80/443 to the server running the docker-compose project, use port 8080,9000 and 8081 using a SSH tunnel.

