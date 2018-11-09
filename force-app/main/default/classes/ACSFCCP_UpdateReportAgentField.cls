public class ACSFCCP_UpdateReportAgentField {

  public static void linkToSalesforceUser(List<ACSFCCP_HistoricalReportData__c> records) {

    Map<String, Id> connectUsers = getConnectUsers();

    for (ACSFCCP_HistoricalReportData__c rec : records) {
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