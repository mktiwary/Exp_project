#!/bin/bash

# /home/centos/kafka_2.11-0.11.0.0/bin/kafka-console-producer.sh --broker-list kafka.kafka-non-prod.genesaas.io:9092 --topic testenv02-acf-v1

while read x;
do
#     echo "$x"
        /home/centos/kafka_2.11-0.11.0.0/bin/kafka-console-producer.sh --broker-list kafka.kafka-non-prod.genesaas.io:9092 --topic testenv01-acf-v1
        sleep 5
        echo "$x"
done < /var/lib/fitnesse/TestFiles/consumertest.json

#Perfprmance_Test_data.json
