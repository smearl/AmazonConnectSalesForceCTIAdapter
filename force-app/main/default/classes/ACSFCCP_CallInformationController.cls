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
  public static final String CACHE_PARTITION_PREFIX = 'ACSFCCP';
  public static final String CACHE_TEST_KEY = 'TESTKEY';
  public static final String CACHE_TEST_VALUE = 'TEST-VALUE';

  public ACSFCCP_CallInformationController(ACSFCCP_NamespaceController controller) { }

  @RemoteAction
  global static Boolean isPlatformCacheAvailable() {
    try {
      Cache.Org.put(CACHE_PARTITION_PREFIX + CACHE_TEST_KEY, CACHE_TEST_VALUE, 301);
      String cacheVal = (String) Cache.Org.get(CACHE_PARTITION_PREFIX + CACHE_TEST_KEY);
      return cacheVal == CACHE_TEST_VALUE;
    }
    catch (Exception e) {
      return false;
    }
  }

  @RemoteAction
  global static String storeCallInformation(string properties) {
    Map<String, String> callInformation = (Map<String, String>) JSON.deserialize(properties, Map<String, String>.class);
    String cid = callInformation.get('contactId').replace('-', '');
    Cache.Org.put(CACHE_PARTITION_PREFIX + cid, properties, 7200);
    return cid;
  }

  @RemoteAction
  global static Map<String, String> returnCallInformation(string contactId) {
    Map<String, String> callInformation = new Map<String, String>();

    if (!String.isBlank(contactId)) {
      String cid = contactId.replace('-', '');
      String information = (String) Cache.Org.get(CACHE_PARTITION_PREFIX + cid);
      if (information != null) {
        callInformation = (Map<String, String>) JSON.deserialize(information, Map<String, String>.class);
      }
    }

    return callInformation;
  }

  @RemoteAction
  global static List<ServicePresenceStatusHolder> getServicePresenceStatuses() {
    List<ServicePresenceStatusHolder> statuses = new List<ServicePresenceStatusHolder>();

    try {
      System.Type t = Type.forName('ServicePresenceStatus');

      List<SObject> results = Database.query('Select Id, DeveloperName, MasterLabel FROM ServicePresenceStatus');

      for (SObject so : results) {
        statuses.add(new ServicePresenceStatusHolder(so.Id, so.get('DeveloperName').toString(), so.get('MasterLabel').toString()));
      }
    }
    catch(Exception e) {
      System.debug('********** ' + e.getMessage());
    }

    return statuses;
  }

  global class ServicePresenceStatusHolder {
    public String id {get; set;}
    public String developerName {get; set;}
    public String masterLabel {get; set;}

    public ServicePresenceStatusHolder() {
    }

    public ServicePresenceStatusHolder(String id, String developerName, String masterLabel) {
      this.id = id;
      this.developerName = developerName;
      this.masterLabel = masterLabel;
    }
  }
}