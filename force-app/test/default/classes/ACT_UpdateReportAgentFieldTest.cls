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
private class ACSFCCP_UpdateReportAgentFieldTest {

  private static final Profile STANDARD_USER;

  static {
    STANDARD_USER = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
  }

  private static User ConnectUser {
    get {
      if (ConnectUser == null) {
        ConnectUser = [SELECT Id, FirstName, LastName, Username FROM User WHERE LastName = 'ConnectUser'];
      }
      return ConnectUser;
    }
  }

  private static User PureSalesforceUser {
    get {
      if (PureSalesforceUser == null) {
        PureSalesforceUser = [SELECT Id, FirstName, LastName, Username FROM User WHERE LastName = 'PureSalesforceUser'];
      }
      return PureSalesforceUser;
    }
  }

  @TestSetup static void setup() {
    createUser('ConnectUser', 'john.smith');
    createUser('PureSalesforceUser', '');
  }

  @isTest static void testUserAssignment() {
    List<ACSFCCP_HistoricalReportData__c> newRecords = new List<ACSFCCP_HistoricalReportData__c> {
      new ACSFCCP_HistoricalReportData__c( Type__c = 'Queue', AC_Object_Name__c = 'Queue ABC'),
      new ACSFCCP_HistoricalReportData__c( Type__c = 'Agent', AC_Object_Name__c = 'john.smith')
    };

    System.assertEquals(0, [SELECT Type__c, AC_Object_Name__c, Agent__c FROM ACSFCCP_HistoricalReportData__c].size());

    Test.startTest();
    insert newRecords;
    Test.stopTest();

    System.assertEquals(2, [SELECT Type__c, AC_Object_Name__c, Agent__c FROM ACSFCCP_HistoricalReportData__c].size());

    ACSFCCP_HistoricalReportData__c agentRecord = [SELECT Type__c, AC_Object_Name__c, Agent__c FROM ACSFCCP_HistoricalReportData__c WHERE Type__c = 'Agent'];
    System.assertEquals(ConnectUser.Id, agentRecord.Agent__c);

    ACSFCCP_HistoricalReportData__c queueRecord = [SELECT Type__c, AC_Object_Name__c, Agent__c FROM ACSFCCP_HistoricalReportData__c WHERE Type__c = 'Queue'];
    System.assert(String.isBlank(queueRecord.Agent__c));
  }

  private static void createUser(String lastName, String connectUserName) {
    User u = new User(
      FirstName = 'John',
      LastName = lastName,
      Alias = 'foo',
      Username = lastName.toLowerCase() + '@test.com',
      Email = lastName.toLowerCase() + '@testcompany.com',
      ProfileId = STANDARD_USER.Id,
      EmailEncodingKey='UTF-8',
      LanguageLocaleKey='en_US',
      LocaleSidKey='en_US',
      TimeZoneSidKey='America/Los_Angeles',
      Amazon_Connect_Username__c = connectUserName
    );

    insert u;
  }
}