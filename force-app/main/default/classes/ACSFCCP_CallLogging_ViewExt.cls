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

public with sharing class ACT_CallLogging_ViewExt {

	private FINAL String acctId;

	public ACT_CallLogging_ViewExt(ApexPages.StandardController ctrl){
		acctId = ctrl.getId();
	}

	public List<TaskwithPhone> getPhoneTasks(){
		List<TaskwithPhone> phoneTasks = new List<TaskwithPhone>();
		Map<Id, String> contactNum = new Map<Id, String>();
		List<Contact> contacts = [SELECT Id, Phone FROM Contact where AccountId =: acctId];
		For(Contact contact : contacts)
		{
			contactNum.put(contact.Id, contact.Phone);
		}
		List<Task> tasks = [SELECT Id, CallDurationInSeconds, WhoId, CallObject, CreatedDate, CallType
									FROM Task
									WHERE WhatId =: acctId AND CallObject != null
									ORDER BY CreatedDate DESC];
		for(Task task : tasks)
		{
			phoneTasks.add(new TaskwithPhone(contactNum.get(task.WhoId), task));
		}
		return phoneTasks;
	}

	public class TaskwithPhone
	{
		public String phoneNumber {get;set;}
		public Task task {get;set;}

		public TaskWithPhone(String phoneNumber, Task task)
		{
			this.phoneNumber = phoneNumber;
			this.task = task;
		}
	}

}