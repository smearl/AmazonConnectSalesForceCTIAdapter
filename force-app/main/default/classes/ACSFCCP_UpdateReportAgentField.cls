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

public class ACT_UpdateReportAgentField {

  public static void linkToSalesforceUser(List<ACT_HistoricalReportData__c> records) {

    Map<String, Id> connectUsers = getConnectUsers();

    for (ACT_HistoricalReportData__c rec : records) {
      if (rec.Type__c == 'Agent' && connectUsers.containsKey(rec.AC_Object_Name__c)) {
        rec.Agent__c = connectUsers.get(rec.AC_Object_Name__c);
      }
    }
  }

  private static Map<String, Id> getConnectUsers() {
    List<User> connectUsers = [SELECT Amazon_Connect_Username__c FROM User WHERE Amazon_Connect_Username__c <> ''];

    Map<String, Id> result = new Map<String, Id>();
    for (User u : connectUsers) {
      result.put(u.Amazon_Connect_Username__c, u.Id);
    }
    return result;
  }
}