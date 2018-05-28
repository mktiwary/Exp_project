#!/bin/bash

#######################################################################
# NOTES
#######################################################################
# Author: Salman Mir
# Description: This was created to be run in the jenkins pipiline (called by JenkinsFile) for the following purpose:
#              1) Add new test from Fitnesse into TestRail
#              2) Run selected Fitnesse test suites in the CI build
#              3) Update test results into TestRail
# Assumptions:
#              1) Script will be run from the Fitnesse home directory by Jenkins
#              2) curl with HTTPS / SSL support is installed (available by default on CentOS 7)
#              3) xmllint is installed (available by default on CentOS 7)
# Note: 
#              1) Only test suites should be specified in the branch tests input file (file naming convention = BRANCH_NAME.tests)
#              2) Junit output is only supported in results streamed from test suites
#
#######################################################################
# CONFIG
#######################################################################

# Read in external variables and environment properties
# Branch tests input file
BRANCH="$1"
GIT_USERNAME="$2"
GIT_PASSWORD="$3"

echo "Arguments = $1 + $2 + $3"

# Get file paths (relative from FitNesseRoot) for all fitnesse tests in each suite
# Set path for the input file.
BASEDIR=$(dirname "$0")
FITNESSE_HOME=`pwd`
BRANCH_TESTS_FILE="$BASEDIR/$BRANCH.tests"
CASE_ID_TEMP_FILE="$FITNESSE_HOME/$BASEDIR/case_ids.temp"

# Get Jenkins job name and build number for use as test results version
FORMATED_JOB_NAME=`echo $JOB_NAME | sed 's/%2F/\//'`

# Check if running via Jenkins or Locally then set conditions and confguration for each
if [[ -z $FORMATED_JOB_NAME ]]; then
  # Check expected input arguments for local run
  if [[ -z $1 ]]; then
    echo "WARNING:: Usage: $ runFitnesseTests.sh <BRANCH_NAME>.tests"
    echo "::::::::: Example: $ runFitnesseTests.sh feature.tests"
    exit 1
  # Set conditions for local run
  else
    echo "ALERT:: Jenkins env properties not found. Are you running this locally?"
    echo "::::::: Switching to local run configuration:"
    echo "::::::: Using UAT TestRail configuration. UAT URL: https://testrail.uat.uk.experian.local"
    echo "::::::: Changes will not be pushed to Git"
    TESTRAIL_ENV="uat"
    SKIP_GIT="true"
    VERSION="local-run"
  fi
else
  # Check expected input arguments for Jenkins run
  if [[ -z $1 ]] || [[ -z $2 ]] || [[ -z $3 ]];then
    echo "WARNING:: $ runFitnesseTests.sh <BRANCH_NAME>.tests <GIT_USERNAME> <GIT_PASSWORD>"
    echo "::::::::: $ runFitnesseTests.sh feature.tests c555555 password123"
    exit 1
  # Set conditions for Jenkins run
  else
    echo "ALERT:: Using Jenkins build configuration"
    echo "::::::: Using prod TestRail configuration. PROD URL: http://testrail-gsg.experian.local"
    echo "::::::: Changes will be pushed to Git"
    # Note: Set TESTRAIL_ENV to "uat" for testing purposes
    TESTRAIL_ENV="prod"
    VERSION="$FORMATED_JOB_NAME-$BUILD_NUMBER"
    SKIP_GIT="false"
  fi
fi

# TestRail configuration file
TESTRAIL_CONFIG="$FITNESSE_HOME/$BASEDIR/testRail-${TESTRAIL_ENV}.config"
source $TESTRAIL_CONFIG

# Create timestamp for use in test run name in TestRail
TIMESTAMP=`date "+%d%m%Y-%H%M%S"`

# Create directories and delete any old files
mkdir -p junitResults
rm -f $CASE_ID_TEMP_FILE

# Git config
BRANCH_LOWERCASE=`echo $BRANCH | tr '[:upper:]' '[:lower:]'`
BRANCH_GIT=`echo $FORMATED_JOB_NAME | sed -e "s/.*$BRANCH_LOWERCASE/$BRANCH_LOWERCASE/g"`
git config user.email "minervabiteam@experian.com"
git config user.name "$GIT_USERNAME"
git config --global http.sslVerify false
git config --global push.default simple

#######################################################################
# SCRIPT
#######################################################################

# Read test suites paths from file and run them in fitnesse.
while read -r SUITE
do
  # Skip commented out test suites.
  if [[ $SUITE == "#"* ]]; then
     echo "SKIPPED:: $SUITE"
  # Skip empty lines
  elif [[ -z $SUITE ]]; then
     echo "SKIPPED:: Blank lines"
  # Only read if line is not empty (i.e. ignore blank lines)
  elif [[ ! -z $SUITE ]]; then

    # Get the path of the suite under FitNesseRoot
    SUITE_REMOVE_ENV=`echo $SUITE | sed 's/Environments.*[0-9]\.//'`
    SUITE_PHYSICAL_PATH=`echo $SUITE_REMOVE_ENV | tr '.' '/'`

    # Get path of all tests under the suite
    find FitNesseRoot/$SUITE_PHYSICAL_PATH -type d |
    while read -r DIRS_UNDER_SUITE
    do
      cd $FITNESSE_HOME
      cd $DIRS_UNDER_SUITE
      # Get the test name / title
      TITLE=`echo $DIRS_UNDER_SUITE | sed 's/.*\///'`
      # Suites will be skipped and not added to TestRail
      if grep -q "<Suite>true</Suite>" properties.xml || grep -q "<Suite/>" properties.xml; then
        echo "ALERT:: Checking $DIRS_UNDER_SUITE for tests"
      
      # If a test already contains a case_id then store the case_id for later use
      elif grep -q "^@case_id=[0-9]" content.txt; then
        echo "ALERT:: case_id found in $DIRS_UNDER_SUITE"
        CASE_ID=`cat content.txt | grep '@case_id=' | cut -d "=" -f2`
        
        # Dump case_id for later use
        # If the test is maked as skip then add an additional identifier in the temp file
        if grep -q "<Prune>true</Prune>" properties.xml || grep -q "<Prune/>" properties.xml; then
          echo "$SUITE:$TITLE:$CASE_ID:skip" >> $FITNESSE_HOME/$BASEDIR/case_ids.temp
        # If the test is a static page then add an additional identifier in the temp file
        elif ! grep -q "<Suite>true</Suite>" properties.xml && ! grep -q "<Suite/>" properties.xml && ! grep -q "<Test>true</Test>" properties.xml && ! grep -q "<Test/>" properties.xml; then
          echo "$SUITE:$TITLE:$CASE_ID:static" >> $CASE_ID_TEMP_FILE
        else
          echo "$SUITE:$TITLE:$CASE_ID" >> $CASE_ID_TEMP_FILE
        fi

      # If a test does not contain a case_id then:
      else
        echo "ALERT:: case_id not found in $DIRS_UNDER_SUITE"
        # Get various references from the Fitnesse test to send to TestRail
        SECTION=`cat content.txt | grep -m 1 '@section=' | cut -d "=" -f2`
        PRIORITY=`cat content.txt | grep -m 1 '@priority=' | cut -d "=" -f2`
        REFERENCES=`cat content.txt | grep -m 1 '@reference=' | cut -d "=" -f2`
        TEST_TYPE=`cat content.txt | grep -m 1 '@test_type=' | cut -d "=" -f2`
        USE_CASE=`cat content.txt | grep -m 1 '@use_case=' | cut -d "=" -f2`
        EXECUTION_TYPE=`cat content.txt | grep -m 1 '@execution_type=' | cut -d "=" -f2`
        
        # Check if TestRail references exist in the test
        if [[ -z $SECTION ]] || [[ -z $PRIORITY ]] || [[ -z $REFERENCES ]] || [[ -z $TEST_TYPE ]] || [[ -z $EXECUTION_TYPE ]]; then
          echo "ALERT:: One or more fields @section @priority @reference @test_type @execution_type not found in $DIRS_UNDER_SUITE"
          echo "::::::: Test case will not be created in TestRail"
        # If TestRail references exist then continue with creating the test case in TestRail
        else
          # Delete any references from the contents and format the contents to handle spaces, tabs and line return. 
          cat content.txt | sed -e '/^@/ d' | sed -e "/\!3 '''Description:'''/ d" | sed -e "/\!img/ d" | sed -e "/\!lastmodified/ d" | sed -e "/\!path/ d" | sed -Ee ':a;N;$!ba;s/\r{0,1}\n/\\n/g' -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\\\n/\x99/g; s/\\\/\\\\\//g; s/\x99/\\\n/g" -e "s/\"/\\\\\"/g" -e 's/[[:blank:]]+/\\t/g' -e 's/[[:space:]]+/\\s/g' > $FITNESSE_HOME/$BASEDIR/post_content.temp
          BDD_SCENARIO=`cat $FITNESSE_HOME/$BASEDIR/post_content.temp`
          #-e "s/'''/\x99/g; s/'/'\/''/g; s/\x99/'''/g"

          # Format the summary to handle spaces and tabs. 
          cat content.txt | grep "\!3 '''Description:'''" | sed -Ee "s/\!3 '''Description:''' //g" -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/\\\/\\\\\//g" -e "s/\"/\\\\\"/g" -e 's/[[:blank:]]+/\\t/g' -e 's/[[:space:]]+/\\s/g' > $FITNESSE_HOME/$BASEDIR/post_summary.temp
          SUMMARY=`cat $FITNESSE_HOME/$BASEDIR/post_summary.temp`
          
          # Look up section ID mapping from the TestRail configuration file`
          SECTION_LOOKUP=`awk -v LOOKUPVAL=$SECTION -F ":" '$1 == LOOKUPVAL {print $2}' $TESTRAIL_CONFIG`
          # Look up priority ID mapping from the TestRail configuration file
          PRIORITY_LOOKUP=`awk -v LOOKUPVAL=$PRIORITY -F ":" '$1 == LOOKUPVAL {print $2}' $TESTRAIL_CONFIG`
          # Look up test_type ID mapping from the TestRail configuration file
          TEST_TYPE_LOOKUP=`awk -v LOOKUPVAL=$TEST_TYPE -F ":" '$1 == LOOKUPVAL {print $2}' $TESTRAIL_CONFIG`
          # Look up use_case ID mapping from the TestRail configuration file
          USE_CASE_LOOKUP=`awk -v LOOKUPVAL=$USE_CASE -F ":" '$1 == LOOKUPVAL {print $2}' $TESTRAIL_CONFIG`
          # Look up execution_type ID mapping from the TestRail configuration file
          EXECUTION_TYPE_LOOKUP=`awk -v LOOKUPVAL=$EXECUTION_TYPE -F ":" '$1 == LOOKUPVAL {print $2}' $TESTRAIL_CONFIG`
          
          # Check if mandatory fields are correctly specified in the test and can be looked up in the mapping
          # If no value is returned then no request is not sent to TestRail
          if [[ -z $SECTION_LOOKUP ]]; then
            echo "WARNING:: @section=$SECTION does not match mapping in configuration. Please check your test"
            SKIP_CURL="true"
          elif [[ -z $PRIORITY_LOOKUP ]]; then
            echo "WARNING:: @priority=$PRIORITY does not match mapping in configuration. Please check your test"
            SKIP_CURL="true"
          elif [[ -z $TEST_TYPE_LOOKUP ]]; then
            echo "WARNING:: @test_type=$TEST_TYPE does not match mapping in configuration. Please check your test"
            SKIP_CURL="true"
          elif [[ -z $EXECUTION_TYPE_LOOKUP ]]; then
            echo "WARNING:: @execution_type=$EXECUTION_TYPE does not match mapping in configuration. Please check your test"
            SKIP_CURL="true"
          else
            SKIP_CURL="false"
          fi

          # Post request to create test case in TestRail
          if [[ $SKIP_CURL == "true" ]]; then
            echo "WARNING:: Test case not created for $SUITE.$TITLE due to one or more issues with fields. See WARNING above"
          elif [[ $SKIP_CURL == "false" ]]; then
          REQUEST="add_case/$SECTION_LOOKUP"
          CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"title": "'$TITLE'","template_id": "'$TESTRAIL_TEMPLATE'","type_id": "'$TESTRAIL_TYPE'","priority_id": "'$PRIORITY_LOOKUP'","refs": "'$REFERENCES'","custom_executiontype":"'$EXECUTION_TYPE_LOOKUP'","custom_test_type":"'$TEST_TYPE_LOOKUP'","custom_use_case":"'$USE_CASE_LOOKUP'","custom_summary":"'$SUMMARY'","custom_bdd_feature":"'$BDD_FEATURE'","custom_bdd_scenario":"'$BDD_SCENARIO'"}' "$TESTRAIL_API_URL/$REQUEST"`
          # Capture the case_id from the response then:
          CASE_ID_RESPONSE=`echo $CURL | sed -e 's/.*"id":\(.*\),"title".*/\1/'`
           
            if [[ -z $CASE_ID_RESPONSE ]] || [[ $CASE_ID_RESPONSE =~ ^-?[0-9]+$ ]]; then
              
              # 1) Dump case_id for later use
              # If the test is maked as skip then add an additional identifier in the temp file
              if grep -q "<Prune>true</Prune>" properties.xml || grep -q "<Prune/>" properties.xml; then
                echo "$SUITE:$TITLE:$CASE_ID_RESPONSE:skip" >> $FITNESSE_HOME/$BASEDIR/case_ids.temp
              # If the test is a static page then add an additional identifier in the temp file
              elif ! grep -q "<Suite>true</Suite>" properties.xml && ! grep -q "<Suite/>" properties.xml && ! grep -q "<Test>true</Test>" properties.xml && ! grep -q "<Test/>" properties.xml;then
                echo "$SUITE:$TITLE:$CASE_ID_RESPONSE:static" >> $CASE_ID_TEMP_FILE
              else
                echo "$SUITE:$TITLE:$CASE_ID_RESPONSE" >> $CASE_ID_TEMP_FILE
              fi
            
              # 2) Add to fitnesse test
              sed -i "1s/^/@case_id=${CASE_ID_RESPONSE}\n/" content.txt
            else
              echo "WARNING:: case_id not returned from TestRail. $SUITE.$TITLE will not be updated"
              echo "::::::::: case_id returned as: $CASE_ID_RESPONSE"
            fi

          fi

        fi

      fi
    done

    # Run the all tests in Fitnesse and get results in junit format
    java -jar lib/fitnesse-standalone.jar -c "$SUITE?responder=suite&format=junit" > $FITNESSE_HOME/junitResults/TEST-$SUITE.xml
    # Remove unwanted first line from the results
    sed -i '1d' $FITNESSE_HOME/junitResults/TEST-$SUITE.xml
  fi
done < $BRANCH_TESTS_FILE

# Stage, commit and push any changes to Git
if [[ $SKIP_GIT == "false" ]]; then
  git add $FITNESSE_HOME/FitNesseRoot/\*content.txt
  git commit -m "Jenkins job: $VERSION - TestRail sync script: test(s) updated with case_id"
  git push https://$GIT_USERNAME:$GIT_PASSWORD@bitbucketglobal.experian.local/scm/dasa/test-int-dbfit.git HEAD:$BRANCH_GIT
elif [[ $SKIP_GIT == "true" ]]; then
  echo "ALERT:: Git skipped"
fi

# Check the case_id temp file was written to. File will exist if something was written to it.
if [ -f $CASE_ID_TEMP_FILE ]; then
  # Create a test run n TestRail for all the test cases
  # Get all case_ids in comma separated format
  ALL_CASE_IDS=`cat $FITNESSE_HOME/$BASEDIR/case_ids.temp | cut -d ':' -f3 | sed -e :a -e '$!N; s/\n/,/; ta'`
  if [[ $ALL_CASE_IDS =~ [0-9] ]];then
    REQUEST="add_run/$TESTRAIL_PROJECT_ID"
    CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"suite_id": "'$TESTRAIL_SUITE_ID'","name": "SaaS BI build - '$BRANCH' '$TIMESTAMP'","assignedto_id": "'$TESTRAIL_ASSIGNEDTO_ID'","include_all": false,"case_ids": ['$ALL_CASE_IDS']}' "$TESTRAIL_API_URL/$REQUEST"`
    # Capture the run_id from the response:
    RUN_ID_RESPONSE=`echo $CURL | sed -e 's/.*"id":\(.*\),"suite_id".*/\1/'`
 
    # Read test status from junit results and update as appropriate in TestRail
    while IFS=':' read -r SUITE TITLE CASE_ID SKIP_STATUS
    do
      # Only read if line is not empty
      if [[ -z $SUITE ]] || [[ -z $TITLE ]] || [[ -z $CASE_ID ]];then
        echo "SKIPPED:: Blank line found or no Suite/Title/CaseID found in case ID temp file"
      # If the test is set to skip then update TestRail with status "Skipped"
      elif [[ $SKIP_STATUS = "skip" ]];then
        echo "ALERT:: $SUITE.$TITLE test status = skip"
        REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
        CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 7,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
      # If the Fitnesse page is static (i.e. manual test) then update TestRail with status "Untested"
      elif [[ $SKIP_STATUS = "static" ]];then
        echo "ALERT:: $SUITE.$TITLE test status = untested"
        REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
        CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 3,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
      # Read results from the junit results files
      else
      READ_RESULTS=`xmllint --xpath '//testcase[@name="'$SUITE'.'$TITLE'"]' $FITNESSE_HOME/junitResults/TEST-$SUITE.xml`

        # If results contain "failure" then update the test for the run with status "Failed"
        if [[ $READ_RESULTS = *"failure"* ]];then
          echo "ALERT:: $SUITE.$TITLE test status = failure"
          REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
          CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 5,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
        # If results contain "error" then update the test for the run with status "Retest"
        elif [[ $READ_RESULTS = *"error"* ]];then
          echo "ALERT:: $SUITE.$TITLE test status = retest"
          REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
          CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 4,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
        else
        READ_RESULTS=`xmllint --xpath 'string(//testcase[@name="'$SUITE'.'$TITLE'"]/@assertions)' $FITNESSE_HOME/junitResults/TEST-$SUITE.xml`
            
          # If results contains >=1 "assertions" then update the test for the run with status "Passed"
          if  [[ $READ_RESULTS -ge "1" ]];then
          echo "ALERT:: $SUITE.$TITLE test status = passed"
          REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
          CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 1,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
          # If results contains >=1 "assertions" then update the test for the run with status "Untested"
          elif [[ $READ_RESULTS -eq "0" ]];then
          echo "ALERT:: $SUITE.$TITLE test status = untested"
          REQUEST="add_result_for_case/$RUN_ID_RESPONSE/$CASE_ID"
          CURL=`curl -k -H "Content-Type: application/json" -u "$TESTRAIL_USER:$TESTRAIL_API_KEY" -d '{"status_id": 3,"comment": "","elapsed": "","defects": "","version": "'$VERSION'"}' "$TESTRAIL_API_URL/$REQUEST"`
          fi

        fi

      fi

    done < $CASE_ID_TEMP_FILE

  else
    echo "ALERT:: No test run created in TestRail as no test case IDs found"
  fi

else
  echo "ALERT:: No case IDs found or created"
  echo "::::::: No test run created and no test results sent to TestRail"
fi
exit 0

