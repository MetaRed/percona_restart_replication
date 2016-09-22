#!/bin/bash
# set -xv
# This is for Percona Slave Replication Check
# This will restart slave replication if stopped because of table locking
# Categorized by MSQL ERROR Number: 1205
# Daemon process re-started every hour to poll MySQL Slave for replication failure
# Written By : Richard Lopez
# Date : Oct 20th, 2015


# cron's path
PATH=$PATH:/bin:/usr/bin:/usr/local/bin:/sbin:/usr/sbin:/usr/local/sbin

# set the desired umask
umask 002

# declare variables
TIMESTAMP=$(date)
EMAIL=bigkahuna@meta.red
SERVER_NAME=$(hostname --fqdn)
MYSQL_USER=mysql_admin_user
MYSQL_USER_PASSWORD='mysql_admin_user_pass'
export MYSQL_USER_PASSWORD
LOG_DIR=/path/to/script/log/dir
LOG_FILE=${LOG_DIR}/percona_slave_replication_restart.log

# email function
notify_email(){
  mail -s "${0}: failed on ${SERVER_NAME}" $EMAIL
}

# make sure our log directory exists
if [ ! -d $LOG_DIR ]; then
  mkdir $LOG_DIR
  if [ ! $? -eq 0 ]; then
    echo "Unable to create log dir: $LOG_DIR" | notify_email
    exit 1
  fi
else
  touch $LOG_DIR/test
  rm $LOG_DIR/test
  if [ ! $? -eq 0 ]; then
    echo "Unable to write to log dir: $LOG_DIR" | notify_email
    exit 1
  fi
fi

# Log hourly start time of daemon
echo "Starting PT-SLAVE-RESTART ${TIMESTAMP}" >>${LOG_FILE}
# hide slave restart password from process list
printenv MYSQL_USER_PASSWORD | pt-slave-restart --verbose --user=$MYSQL_USER --ask-pass --monitor --stop --sentinel /tmp/pt-slave-cron --max-sleep 600 --daemonize --log ${LOG_FILE} --skip-count=0 --error-numbers=1205
if [ ! $? -eq 0 ]; then
    echo "Unable to run pt-slave-restart" | notify_email
    exit 1
fi
exit 0
