trigger ACSFCCP_HistoricalReportDataTrigger on ACSFCCP_HistoricalReportData__c (before insert) {
    ACSFCCP_UpdateReportAgentField.linkToSalesforceUser(Trigger.new);
}