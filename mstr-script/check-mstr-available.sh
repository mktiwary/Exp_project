#!/bin/bash 
# Logs into the MSTR server and execute reports

TEMP_DIR=/home/jenkins/workspace
ENVIRONMENT="$1"
MSTR_SERVER="$2"

#===========================================================================================================================================
#Delete file if exists
if [ -r /home/jenkins/workspace/mstr_status_check_*.tmp ];
then
rm -f ${TEMP_DIR}/mstr_status_check_*.tmp 
#ls -l /home/jenkins/workspace/
fi
#===========================================================================================================================================
#Copy execution log from remote server to local dbfit server. '>' will write all logs to a file

ssh -i /home/jenkins/workspace/bastion.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ${MSTR_SERVER} << EOF > ${TEMP_DIR}/mstr_status_check_$$.tmp 2>&1

sudo /opt/MicroStrategy/bin/mstrsysmgr -w /home/genesaas/runTest.smw -p user=administrator password= project=${ENVIRONMENT}
EXIT_CODE=\$?
echo "MstrExitCode=\$EXIT_CODE"

EOF
#===========================================================================================================================================

CHECK_EXIT_CODE=`grep "MstrExitCode" ${TEMP_DIR}/mstr_status_check_$$.tmp 2>&1`

if [[ $CHECK_EXIT_CODE == "MstrExitCode=0" ]];
	then echo "Successful"
else
	echo "Unsuccessful"
	cat ${TEMP_DIR}/mstr_status_check_$$.tmp
	rm ${TEMP_DIR}/mstr_status_check_$$.tmp
fi
