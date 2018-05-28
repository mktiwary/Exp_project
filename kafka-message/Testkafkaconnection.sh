#!/bin/bash

myvar=`pwd`
#echo $myvar
dbname=$1

$myvar/kafka_2.11-0.11.0.0/bin/kafka-topics.sh --list  --zookeeper internal-zk20171114163310078100000009-822896325.us-east-1.elb.amazonaws.com:2181/zk > /home/jenkins/workspace/${dbname}/Kafkatopics.out


