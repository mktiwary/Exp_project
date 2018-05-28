#!/bin/bash
# Inserts a specified SQL file into the postgres test DB

SCRIPTDIR=$(dirname "$0")
dbname=$1
filename=$2
curr_dir=`pwd`

chmod 600 $curr_dir/dbConnection.properties/.pgpass

PGPASSFILE=$curr_dir/dbConnection.properties/.pgpass psql -h microstrategy-iserver-data-rds.cfdqqdekwu1i.us-east-1.rds.amazonaws.com -d $dbname -U test -p 5432 -f $SCRIPTDIR/$filename -q 2>&1

#psql -h microstrategy-iserver-data-rds.czo1yp4dmkzl.eu-west-1.rds.amazonaws.com -d $dbname -U test -p 5432 -f $SCRIPTDIR/$filename -q 2>&1

EXIT_CODE=`echo $?`

if [ "$EXIT_CODE" == "0" ];
then
        echo "Insert Successful"
fi

