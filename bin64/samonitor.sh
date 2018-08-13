#!/bin/sh
# ***************************************************************************
# Copyright (c) 2013 SAP AG or an SAP affiliate company. All rights reserved.
# ***************************************************************************

. "/opt/sqlanywhere16/bin64/sa_config.sh" >/dev/null 2>&1

SAM_FILES=$SQLANY16

if [ -z ${HOSTNAME:-} ]; then
    HOSTNAME=`hostname`
fi
SAM_NAME=SAMonitor_$HOSTNAME
SERVICE_NAME=SAMonitor160
DBSRV_OPTIONS="-sb 0 -xd -qi -n $SAM_NAME -xs \"http{port=4950;MaxRequestSize=4m}\" -ch 25p \"$SAM_FILES/samonitor.db\""


check_status()
{
    RC=$?
    if [ $RC != 0 ]; then
	echo "Error $1 SQL Anywhere Monitor: $RC."
	exit $RC
    fi
}

start()
{
    dbspawn -f dbsrv16 $DBSRV_OPTIONS
    check_status starting
}

stop()
{
    dbstop -y @"`dirname "$0"`/smstop.dat" $SAM_NAME
    check_status stopping
}

launch()
{
    samonitor -d "$SAM_FILES/samonitor.db" $SAM_NAME
    check_status launching
}

usage()
{
    echo "Usage: $0 {start|stop|launch}"
}

case "$1" in
start )
    start
    ;;
stop )
    stop
    ;;
launch )
    launch
    ;;
* )
    usage
    ;;
esac

exit 0