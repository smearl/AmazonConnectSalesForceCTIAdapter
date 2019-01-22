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

(function(ctx) {
  if (ctx.ACSFIntegration === undefined) {
    ctx.ACSFIntegration = {};
  }

  var _namespacePrefix;

  ctx.ACSFIntegration.CallInformation = {
    onAgentHandler : function(namespacePrefix) {
      connect.getLog().info("ACSFIntegration:CallInformation:onAgentHandler invoked");

      _namespacePrefix = namespacePrefix;

      if (sforce.console) {
        sforce.console.onFocusedSubtab(function (response) {
          connect.getLog().info("ACSFIntegration:CallInformation:onFocusedSubtab: %s", JSON.stringify(response));
          if (response && response.objectId) {
            var objectType = '';

            if (response.objectId.startsWith("003")) {
              objectType = 'Contact';
            } else if (response.objectId.startsWith("00Q")) {
              objectType = 'Lead';
            } else if (response.objectId.startsWith("001")) {
              objectType = 'Account';
            }

            handleObjectTypeRecordId(objectType, response.objectId);
          }
        });
      }

      if (sforce.opencti) {
        sforce.opencti.onNavigationChange({
          listener: function (response) {
            connect.getLog().info("ACSFIntegration:CallInformation:onNavigationChange: %s", JSON.stringify(response));
            if (response && response.objectType) {
              var objectType = response.objectType;

              handleObjectTypeRecordId(objectType, response.recordId);
            }
          }
        });
      }
    }
  };

  function handleObjectTypeRecordId(objectType, recordId) {
    if (objectType === 'Contact' || objectType === 'Lead' || objectType === 'Account') {
      Visualforce.remoting.Manager.invokeAction(
        _namespacePrefix + 'ACSFCCP_CallInformationController.getTaskDetails',
        recordId,
        function (result, event) {
          if (event.status && result) {
            if (result.whoId) {
              sessionStorage.setItem("CCP-whoId", result.whoId);
            } else {
              sessionStorage.removeItem("CCP-whoId");
            }

            if (result.whatId) {
              sessionStorage.setItem("CCP-whatId", result.whatId);
            } else {
              sessionStorage.removeItem("CCP-whatId");
            }
          }
        }
      );
    }
  }
})(this);