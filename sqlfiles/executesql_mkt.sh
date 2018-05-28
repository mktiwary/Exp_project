#!/bin/bash

psql -h microstrategy-iserver-data-rds.czo1yp4dmkzl.eu-west-1.rds.amazonaws.com -d testenv07 -U test -p 5432 -f /home/jenkins/workspace/fitnesse/sqlfiles/f_application_decision_1.sql -q
