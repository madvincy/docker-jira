#!/bin/bash
#
# Restore and rsync script to be used as restic post restore script
# assumes docker-compose.yml is available in /opt/composeproject
#

# enter docker-compose dir
cd /opt/composeproject

# source environment vars from .env 
echo Source environment from .env
export $(cat .env | xargs)

# stop jira
echo Stopping jira container to avoid access to the database. 
docker-compose stop jira

# move db file
echo Move data to volume location in container
mv /var/backup/pgsql/pgsql_jiradb.dump /data/postgresqldata/pgsql_jiradb.dump

# import db
echo Importing dumpfile
docker-compose exec postgresql pg_restore /var/lib/postgresql/data/pgsql_jiradb.dump -c -d ${POSTGRES_DB} -U ${POSTGRES_USER} 

# move db file back
echo Move data to original location
mv /data/postgresqldata/pgsql_jiradb.dump /var/backup/pgsql/pgsql_jiradb.dump

# rsync data from production  Add ssh key if needed
if ! grep "$(ssh-keyscan ${RSYNC_SOURCE} 2>/dev/null)" /root/.ssh/known_hosts > /dev/null; then
    ssh-keyscan ${RSYNC_SOURCE} >> /root/.ssh/known_hosts
fi

# touch log and set permissions
mkdir -p /var/log/jira
touch /var/log/jira/rsync_data.log

# rsync with --delete option, without compression. 
rsync -avh -e 'ssh -i .jirarsync.key' --no-owner --no-group --delete --log-file=/var/log/jirar/rsync_data.log jirarsync@${RSYNC_SOURCE}:/data/jira/data /data/jira/data

# start Jira
echo Starting Jira
docker-compose start jira

