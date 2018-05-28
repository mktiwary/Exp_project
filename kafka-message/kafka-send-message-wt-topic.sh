#!/bin/bash

myvar=`pwd`
topicenv=$1
kafka_msg_file=$2
#echo $myvar
while read x;
do
     echo "$x"
	$myvar/kafka_2.11-0.11.0.0/bin/kafka-console-producer.sh --broker-list kafka.kafka-non-prod.non-prod.us-east-1.genesaas.io:9092 --topic $topicenv
#$topicenv
	sleep 2
	echo "$x"
done < $myvar/kafka-message/$kafka_msg_file

