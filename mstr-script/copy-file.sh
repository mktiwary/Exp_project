#!/bin/bash

env=$1
mstrServer=$2
filename=$3

echo "<<<Remove local files>>>"
rm -f TestFiles/$env/*_Dataset*.*
rm -f /home/jenkins/workspace/$env/*_Dataset*.*
echo "<<<Files in TestFiles/${env} >>>"
ls -l TestFiles/$env/
echo "<<<Files in /home/jenkins/workspace/${env} >>>"
ls -al /home/jenkins/workspace/$env/

echo "<<< copy file from mstr server >>>"
# Copy file from MSTR server to local directory
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/${filename} TestFiles/$env/
echo "<<< copy file to Jenkins workspace >>>"
#  From local directory to Jenkins workspace
cp TestFiles/$env/${filename} /home/jenkins/workspace/$env/${filename}

echo "<<< Files in /home/jenkins/workspace/$env/ directory>>>"
ls -al /home/jenkins/workspace/$env/
