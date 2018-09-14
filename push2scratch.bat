@echo off
REM Deployment
REM The Toolkit for Amazon Connect is written as a Salesforce DX application,
REM and can be deployed using the Salesforce DX command line tool. See the Salesforce DX documentation for details.

REM Convert the source
REM To deploy to a Salesforce org, the source must first be converted
REM to metadata using sfdx.
REM
echo Converting to metadata...
del mdapioutput\*
call sfdx force:source:convert -r force-app -d mdapioutput/

REM Deploy the metadata
REM Once the source has been converted it can be deployed to an org using sfdx.
REM
echo Deploying metadata...
call sfdx force:mdapi:deploy -u AwsAdapterTest -d mdapioutput/ -w 100
