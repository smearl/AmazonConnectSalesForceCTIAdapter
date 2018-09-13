@echo off
@echo Auth the org
//call sfdx force:auth:web:login -r https://whitewalker-dev-ed.my.salesforce.com -a whitewalker --setdefaultusername
@echo Open dev org...
call sfdx force:org:open -u whitewalker