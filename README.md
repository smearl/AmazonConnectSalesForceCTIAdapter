# Whitewalker - AC/SFDC CTI Integration
## Dev, Build and Test
### Scratch Orgs
Example of creating a scratch org named "WW-Reporting"
```
sfdx force:org:create -s -f config/project-scratch-def.json -a "WW-Reporting"
```
### Push to salesforce
To push source to a scratch org for adding objects and non-code items, here is an example of pushing to a scratch org called WW-Reporting
```
sfdx force:source:push -u WW-Reporting
```
### Pull from salesforce
Example pull from a scratch org called WW-Reporting
```
sfdx force:source:pull -u WW-Reporting
```
### Convert to meta-data
Use the following command to convert the source to metadata. It is advised to delete the mdapioutput folder first especially if files have been added or removed.
```
sfdx force:source:convert -r force-app -d mdapioutput/
```
### Deploy to sandboxes
To deploy to the VF v2.5 sandbox.
```
sfdx force:mdapi:deploy -u WW25 -d mdapioutput/ -w 100
```
AWS has a dev edition org located at https://whitewalker-dev-ed.my.salesforce.com and to deploy there:
```
sfdx force:mdapi:deploy -u whitewalker -d mdapioutput/ -w 100
```


