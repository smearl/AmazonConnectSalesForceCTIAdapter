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

global with sharing class ACT_CallInformationController {
  public static final String CACHE_PARTITION_PREFIX = 'ACTCallInfo';
  public static final String CACHE_TEST_KEY = 'TESTKEY';
  public static final String CACHE_TEST_VALUE = 'TEST-VALUE';

  public ACT_CallInformationController(ACT_NamespaceController controller) { }

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
  global static void storeCallInformation(string properties) {
    Map<String, String> callInformation = (Map<String, String>) JSON.deserialize(properties, Map<String, String>.class);
    String cid = callInformation.get('contactId').replace('-', '');
    Cache.Org.put(CACHE_PARTITION_PREFIX + cid, properties, 7200);
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
}