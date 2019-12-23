#!/bin/bash
#
# Restore and rsync script to be used as restic post restore script
# assumes docker-compose.yml is available in /opt/composeproject
#
cd /opt/composeproject
echo Source environment from .env
export $(cat .env | xargs)
echo Stopping jira container to avoid access to the database. 
docker-compose stop jira
echo Importing dumpfile
docker-compose exec postgresql psql -f /var/backup/pgsql_jiradb.dump ${POSTGRES_DB} -U ${POSTGRES_USER} -P ${POSTGRES_PASSWORD} 
echo Starting Jira
docker-compose start jira



