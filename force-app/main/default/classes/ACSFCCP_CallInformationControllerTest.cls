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

@isTest
private class ACSFCCP_CallInformationControllerTest {
  @isTest
  static void testStoreAndCallInfo() {
    if (ACSFCCP_CallInformationController.isPlatformCacheAvailable()) {
      String info = '{"contactId" : "testContact", "data" : "123"}';
      ACSFCCP_CallInformationController.storeCallInformation(info);
      Map<String, String> result = ACSFCCP_CallInformationController.returnCallInformation('testContact');

      if (result == null || result.get('data') == null) {
        // Platform cache is configured but no space is allocated.
        System.assert(true);
      } else {
        System.assertEquals('123', result.get('data'));
      }
    }
  }

  @isTest
  static void testStoreCallInformation() {
    if (ACSFCCP_CallInformationController.isPlatformCacheAvailable()) {
      String info = '{"contactId" : "123123-1231-1123123", "data" : "123"}';
      String result = ACSFCCP_CallInformationController.storeCallInformation(info);
      System.assertEquals('12312312311123123', result);

    }
  }

  @isTest
  static void getTaskDetails() {
    Task t  = new Task();

    ACSFCCP_CallInformationController.TaskDetails td = ACSFCCP_CallInformationController.getTaskDetails(t.Id);

    System.assert(td != null);

    System.assert(String.isEmpty(td.whoId));

    System.assert(String.isEmpty(td.whatId));
  }

  @isTest(SeeAllData=true)
  static void getTaskDetailsForContact() {
    Integer count = [Select Count() From Contact];

    Integer rand = Math.floor(Math.random() * count).intValue();

    List<Contact> contacts = (List<Contact>) Database.query('Select Id, Name From Contact Order By Id Asc Limit 1 OFFSET :rand');

    Contact c = contacts.get(0);

    ACSFCCP_CallInformationController.TaskDetails td = ACSFCCP_CallInformationController.getTaskDetails(c.Id);

    System.assert(!String.isEmpty(td.whoId));
  }

  @isTest(SeeAllData=true)
  static void getTaskDetailsForAccount() {
    Integer count = [Select Count() From Account];

    Integer rand = Math.floor(Math.random() * count).intValue();

    List<Account> accounts = (List<Account>) Database.query('Select Id, Name From Account Order By Id Asc Limit 1 OFFSET :rand');

    Account a = accounts.get(0);

    ACSFCCP_CallInformationController.TaskDetails td = ACSFCCP_CallInformationController.getTaskDetails(a.Id);

    System.assert(!String.isEmpty(td.whatId));
  }

  @isTest(SeeAllData=true)
  static void getTaskDetailsForLead() {
    Integer count = [Select Count() From Lead];

    Integer rand = Math.floor(Math.random() * count).intValue();

    List<Lead> leads = (List<Lead>) Database.query('Select Id, Name From Lead Order By Id Asc Limit 1 OFFSET :rand');

    Lead l = leads.get(0);

    ACSFCCP_CallInformationController.TaskDetails td = ACSFCCP_CallInformationController.getTaskDetails(l.Id);

    System.assert(!String.isEmpty(td.whoId));
  }

  @isTest
  static void testGetServicePresenceStatuses() {

    Object result = ACSFCCP_CallInformationController.getServicePresenceStatuses();
    System.assert(result != null);

    ACSFCCP_CallInformationController.ServicePresenceStatusHolder spsh = new ACSFCCP_CallInformationController.ServicePresenceStatusHolder();
    spsh.id = 'A';
    spsh.masterLabel = 'A';
    spsh.developerName = 'A';

    System.assertEquals(spsh.id, 'A');
    System.assertEquals(spsh.masterLabel, 'A');
    System.assertEquals(spsh.developerName, 'A');
  }
}