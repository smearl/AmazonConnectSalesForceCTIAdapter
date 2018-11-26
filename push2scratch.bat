@echo off
: commands to push and pull to & from the scratch org
: change the name to match your scratch org
: scratch orgs only last a week and used creating custom objects
: and othe SF-stuff that can't be created in code
: push to salesforce
call sfdx force:source:push -u wwreports
: pull from salesforce
call sfdx force:source:pull -u wwreports