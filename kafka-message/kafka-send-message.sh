#!/bin/bash

myvar=`pwd`
#topicenv=$2
#echo $myvar
while read x;
do
     echo "$x"
	$myvar/kafka_2.11-0.11.0.0/bin/kafka-console-producer.sh --broker-list kafka.kafka-non-prod.non-prod.eu-west-1.genesaas.io:9092 --topic testenv05-acf-v1
#$topicenv
	sleep 2
	echo "$x"
done < $myvar/kafka-message/$1

