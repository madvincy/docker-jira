#!/bin/bash
#
# Restore and rsync script to be used as restic post restore script
# assumes docker-compose.yml is available in /opt/composeproject
#

echo "$(date '+%Y-%m-%d %H:%M:%S') -- Starting restore_and_sync.sh script"

# enter docker-compose dir
cd /opt/composeproject

# source environment vars from .env 
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Source environment from .env"
export $(cat .env | xargs)

# stop jira
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Stopping jira container to avoid access to the database."
/usr/local/bin/docker-compose stop jira

# move db file
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Move data to volume location in container"
mv /var/backup/pgsql/pgsql_jiradb.dump /data/postgresqldata/pgsql_jiradb.dump

# import db
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Importing dumpfile"
/usr/local/bin/docker-compose exec postgresql pg_restore /var/lib/postgresql/data/pgsql_jiradb.dump -c -d ${POSTGRES_DB} -U ${POSTGRES_USER} 

# move db file back
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Move data to original location"
mv /data/postgresqldata/pgsql_jiradb.dump /var/backup/pgsql/pgsql_jiradb.dump

# rsync data from production  Add ssh key if needed
echo "$(date '+%Y-%m-%d %H:%M:%S') -- prepare rsync, run ssh-keyscan if needed"
if ! grep "$(ssh-keyscan ${RSYNC_SOURCE} 2>/dev/null)" /root/.ssh/known_hosts > /dev/null; then
    /usr/bin/ssh-keyscan ${RSYNC_SOURCE} >> /root/.ssh/known_hosts
fi

# rsync with --delete option, without compression. 
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Rsync data folder"
/usr/bin/rsync -avh -e 'ssh -i .jirarsync.key' --no-owner --no-group --delete jirarsync@${RSYNC_SOURCE}:/data/jira/data /data/jira

# start Jira
echo "$(date '+%Y-%m-%d %H:%M:%S') -- Starting Jira"
/usr/local/bin/docker-compose start jira

# report ok when restore_and_sync is succesful
  if [ $? = "0" ] ; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') -- Restore_and_sync succeeded"
  else
    echo "$(date '+%Y-%m-%d %H:%M:%S') -- Restore_and_sync ended with error"
  fi

