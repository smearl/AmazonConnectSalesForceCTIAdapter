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

@IsTest
private class ACSFCCP_CallLogging_ViewExtTest {

	@TestSetup
	static void setup()
	{
		Account a = new Account(Name='Test Acct 1');
		insert a;
		Contact c = new Contact(LastName='Test', FirstName='User', Phone='403-681-3632', AccountId = a.Id);
		insert c;
		Task t = new Task(Subject='Call', CallObject='bc9a4383-4497-4cca-82e6-04d040562d17', WhoId=c.Id, WhatId=a.Id);
		insert t;
	}

	@isTest
	static void testGetPhoneTasks() {
		Account a = [SELECT Id FROM Account WHERE Name='Test Acct 1'];
		Contact c = [SELECT Id FROM Contact WHERE LastName='Test'];
		PageReference pageRef = Page.ACSFCCP_CallLogging_View;
		Test.setCurrentPage(pageRef);
		pageRef.getParameters().put('Id', a.Id);
		ApexPages.StandardController sc = new ApexPages.StandardController(a);
		ACSFCCP_CallLogging_ViewExt callLogging = new ACSFCCP_CallLogging_ViewExt(sc);
		Test.startTest();
		List<ACSFCCP_CallLogging_ViewExt.TaskwithPhone> tasks = callLogging.getPhoneTasks();
		Test.stopTest();

		System.assertEquals(1, tasks.size());
		System.assertEquals(c.Id, tasks[0].task.WhoId);
	}
}