/** Copyright 2018 Aria Solutions Inc.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.
*/

public with sharing class ACT_PostCallUpdateTaskLookupsController {

  public ACT_PostCallUpdateTaskLookupsController(ApexPages.StandardController stdController) { }

  public List<SelectOption> getDispositionCodes() {
    List<SelectOption> dispositionCodes = new List<SelectOption>();
    for(ACT_Call_Disposition_Code__mdt dc: [SELECT DeveloperName, MasterLabel, Disposition_Code__c FROM ACT_Call_Disposition_Code__mdt WHERE Active__c = true ORDER BY DeveloperName ASC]) {
      dispositionCodes.add(new SelectOption(dc.Disposition_Code__c, dc.MasterLabel));
    }

    return dispositionCodes;
  }
}