#!/bin/bash

curdir=`pwd`
echo $curdir
dbname=$1
filename=$2

psql -h microstrategy-iserver-data-rds.czo1yp4dmkzl.eu-west-1.rds.amazonaws.com -d $dbname -U test -p 5432 -f $curdir/$filename
