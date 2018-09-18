rem add our sandbox to the org list
sfdx force:auth:web:login -r https://vfsfdev--testone.my.salesforce.com -a TestOne --setdefaultusername

echo Converting to metadata...
del mdapioutput\*
call sfdx force:source:convert -r force-app -d mdapioutput/

REM Deploy the metadata
REM Once the source has been converted it can be deployed to an org using sfdx.
REM
echo Deploying metadata...
call sfdx force:mdapi:deploy -u TestOne -d mdapioutput/ -w 100
