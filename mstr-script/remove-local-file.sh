#!/bin/bash

env=$1
mstrServer=$2

rm -f TestFiles/$env/*_Dataset.*
rm -f /home/jenkins/workspace/$env/*_Dataset.*
echo "List files in TestFiles/${env}"
ls -al TestFiles/
ls -l TestFiles/$env/
echo "List files and folders in /home/jenkins/workspace/"
ls -al /home/jenkins/workspace/
echo "List files in jenkins/workspace/${env}"
ls -al /home/jenkins/workspace/$env/

pwd

#echo "scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no ${mstrServer}:/home/genesaas/efs-test/${env}/ADT_Dataset.csv TestFiles/${env}/"
# Copy ADT dataset file to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/ADT_Dataset.csv TestFiles/$env/

#Copy MDT dataset tfile to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/MDT_Dataset.csv TestFiles/$env/

#Copy Applications received data to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Applications_Received_Dataset.csv TestFiles/$env/

#Copy Application Approved/Declined data to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Approved_Declined_Dataset.csv TestFiles/$env/

#Copy Applications detail dataset-1 file to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Applications_Decision_Type_Detail_Dataset.csv TestFiles/$env/
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Applications_Status_Detail_Dataset.csv TestFiles/$env/

#Copy Fraudulent report two dataset CSV file to local
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Fraudulent_Applications_Dataset.csv TestFiles/$env/
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Fraudulent_Applications_Dataset_2.csv TestFiles/$env/

#Copy Applications Pending dataset file to local destination
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/Applications_Pending_Decisions_Dataset.csv TestFiles/$env/
scp -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no $mstrServer:/home/genesaas/efs-test/$env/ApplicationsPending_Decisions_Dataset2.csv TestFiles/$env/

#echo "File copied from server, List files in TestFiles/${env}"
ls -al TestFiles/$env/

#convert txt to csv - ADT
#cp TestFiles/ADT_Dataset.txt TestFiles/ADT_Dataset.csv
cp TestFiles/$env/ADT_Dataset.csv /home/jenkins/workspace/$env/ADT_Dataset.csv

#convert txt to csv - MDT
#cp TestFiles/MDT_Dataset.txt TestFiles/MDT_Dataset.csv
cp TestFiles/$env/MDT_Dataset.csv /home/jenkins/workspace/$env/MDT_Dataset.csv

#convert txt to csv - Apps Received
cp TestFiles/$env/Applications_Received_Dataset.csv /home/jenkins/workspace/$env/Applications_Received_Dataset.csv

#Copy file to testenv folder - Approved/Declined Applications 
cp TestFiles/$env/Approved_Declined_Dataset.csv /home/jenkins/workspace/$env/Approved_Declined_Dataset.csv

#convert txt to csv - Applications Detail
cp TestFiles/$env/Applications_Status_Detail_Dataset.csv /home/jenkins/workspace/$env/
cp TestFiles/$env/Applications_Decision_Type_Detail_Dataset.csv /home/jenkins/workspace/$env/

#Copy files to testenv folder - Fraudulent Report
cp TestFiles/$env/Fraudulent_Applications_Dataset.csv /home/jenkins/workspace/$env/Fraudulent_Applications_Dataset.csv
cp TestFiles/$env/Fraudulent_Applications_Dataset_2.csv /home/jenkins/workspace/$env/Fraudulent_Applications_Dataset_2.csv

#Copy files to testenv folder - Application Pending
cp TestFiles/$env/Applications_Pending_Decisions_Dataset.csv /home/jenkins/workspace/$env/Applications_Pending_Decisions_Dataset.csv
cp TestFiles/$env/ApplicationsPending_Decisions_Dataset2.csv /home/jenkins/workspace/$env/ApplicationsPending_Decisions_Dataset2.csv


echo "File copied List files in workspace/${env}"
ls -l /home/jenkins/workspace/$env/
