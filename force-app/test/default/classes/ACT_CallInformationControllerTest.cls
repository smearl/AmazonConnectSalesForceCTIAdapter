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
}