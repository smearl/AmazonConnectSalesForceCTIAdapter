/**

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

global with sharing class ACSFCCP_CallInformationController {
  public ACSFCCP_CallInformationController(ACSFCCP_NamespaceController controller) { }

  @RemoteAction
  public static TaskDetails getTaskDetails(Id id) {
    TaskDetails td = new TaskDetails();

    if (id != null) {
      Schema.SObjectType sobjectType = id.getSObjectType();
      String sobjectName = sobjectType.getDescribe().getName();

      if (sobjectName.equalsIgnoreCase('Account')) {
        // We only have the account to work with
        td.whoId = null;
        td.whatId = id;
      } else if (sobjectname.equalsIgnoreCase('Lead')) {
        // We only have the lead to work with
        td.whoId = id;
        td.whatId = null;
      } else if (sobjectName.equalsIgnoreCase('Contact')) {
        // We need to lookup the account associated with the contact
        SObject so = Database.query('Select Id, AccountId From Contact Where Id = :id');

        if (so != null) {
          Contact contact = (Contact) so;
          if (!String.isEmpty(contact.AccountId)) {
            td.whatId = contact.AccountId;
          } else {
            td.whatId = null;
          }
          td.whoId = contact.Id;
        }
      }
    }

    return td;
  }

  public class TaskDetails {
    public Id whoId {get;set;}
    public Id whatId {get;set;}

    public TaskDetails() {
    }
  }

  @RemoteAction
  public static List<ServicePresenceStatusHolder> getServicePresenceStatuses() {
    List<ServicePresenceStatusHolder> statuses = new List<ServicePresenceStatusHolder>();

    try {
      List<SObject> results = Database.query('Select Id, DeveloperName, MasterLabel FROM ServicePresenceStatus');

      ServicePresenceStatusHolder sph = null;
      for (SObject so : results) {
        sph = new ServicePresenceStatusHolder();
        sph.id = so.Id;
        sph.developerName = so.get('DeveloperName').toString();
        sph.masterLabel = so.get('MasterLabel').toString();

        statuses.add(sph);
      }
    }
    catch(Exception e) {
      System.debug('Omnichannel could not be configured: ' + e.getMessage());
    }

    return statuses;
  }

  public class ServicePresenceStatusHolder {
    public String id {get; set;}
    public String developerName {get; set;}
    public String masterLabel {get; set;}

    public ServicePresenceStatusHolder() {
    }
  }
}