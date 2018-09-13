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

(function(ctx) {
  if (ctx.ACSFIntegration === undefined) {
    ctx.ACSFIntegration = {};
  }

  var _namespacePrefix;

  function showCallTransferBtn() {
    document.getElementById("transferBtn").
      classList.remove("hidden");
  }

  function hideCallTransferBtn() {
    document.getElementById("transferBtn").
      classList.add("hidden");
  }

  function handleBtnClick(contact){
    function getLightningAppView() {
      connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:getLightningAppView");
      sforce.opencti && sforce.opencti.getAppViewInfo({
        callback: function(response) {
          try {
            if (response.success) {
              connect.getLog().info("ACSFIntegration:CallInformation:getLightningAppView:Result");
              console.log(JSON.stringify(response.returnValue));
              saveTabLink({
                tabLink: response.returnValue.url
              });
            } else {
              connect.getLog().info("ACSFIntegration:CallInformation:getLightningAppView:Error:" + JSON.stringify(response.errors));
            }
          } catch (ex) {
           connect.getLog().error("ACSFIntegration:CallInformation:getLightningAppView:Error:" + JSON.stringify(ex));
          }
        }
      });
    }

    function getFocusedPrimaryTabId() {
      connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:getFocusedPrimaryTabId");
      sforce.console && sforce.console.getFocusedPrimaryTabId(getTabLink);
    }

    function getTabLink(result) {
      connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:getTabLink");
      sforce.console && sforce.console.getTabLink(sforce.console.TabLink.PARENT_AND_CHILDREN, result.id, saveTabLink);
    }

    function saveTabLink(result) {
      var properties = JSON.stringify({contactId: contact.getContactId(), url: result.tabLink});
      Visualforce.remoting.Manager.invokeAction(
        _namespacePrefix + 'ACSFCCP_CallInformationController.storeCallInformation',
        properties,
        function(result, event){
          connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:RemoteJavascript:Send invoked");
          if(event.status){
            connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:RemoteJavascript cache updated");
          }
          else if(event.type === 'exception'){
            connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick:RemoteJavascript:Error "+ event.message);
          }
        }
      );
    };

    connect.getLog().info("ACSFIntegration:CallInformation:handleBtnClick button clicked");
    getFocusedPrimaryTabId();
  }

  function showTransferBtnOnRefreshApplicable(agent, contact){
    if(!contact.isInbound()){
      connect.getLog().info("ACSFIntegration:CallInformation:showTransferBtnOnRefreshApplicable:call not inbound");
      return;
    }
    showCallTransferBtn();
  }

  ctx.ACSFIntegration.CallInformation = {
    onAgentHandler : function(namespacePrefix) {
      connect.getLog().info("ACSFIntegration:CallInformation:onAgentHandler invoked");

      _namespacePrefix = namespacePrefix;

      Visualforce.remoting.Manager.invokeAction(
        _namespacePrefix + 'ACSFCCP_CallInformationController.isPlatformCacheAvailable',
        function(result, event) {
          if (!(event.status && result)) {
            connect.getLog().warn("ACSFIntegration:CallInformation:onAgentHandler cache not configured; button disabled");
            document.getElementById("transferBtn").style.display = 'none';
          }
        }
      );

      document.getElementById("transferBtn").onclick = function(){
        connect.agent(function(agent){
          var contact = agent.getContacts()[0];
          connect.getLog().warn("ACSFIntegration:CallInformation:transferBtnClicked");
          handleBtnClick(contact);
        });
      };

      connect.agent(function (agent) {
        agent.onAfterCallWork(function(){
          hideCallTransferBtn();
        });
        if (agent.getContacts().length === 1) {
          var contact = agent.getContacts()[0];
          showTransferBtnOnRefreshApplicable(agent, contact);
        }
      });
    },

    onAccepted: function(contact) {
      connect.getLog().info("ACSFIntegration:CallInformation:onAccepted");
      showCallTransferBtn();
    },

    onEnded: function() {
      connect.getLog().info("ACSFIntegration:CallInformation:onEnded");
      hideCallTransferBtn();
    },

    getWorkspaceUrl: function (contact, onSuccess, onError) {
      if (sforce.console && !sforce.console.isInConsole()) {
        onError('WorkspaceUrl not supported outside of classic console.');
        return;
      }

      Visualforce.remoting.Manager.invokeAction(
        _namespacePrefix + 'ACSFCCP_CallInformationController.returnCallInformation',
        contact.getOriginalContactId(),
        function(result, event){
          connect.getLog().info("ACSFIntegration:CallInformation:getWorkspaceUrl:RemoteJavascript:Return invoked");
          if(event.status){
            onSuccess(result);
          }
          else if(event.type === 'exception'){
            connect.getLog().info("ACSFIntegration:CallInformation:getWorkspaceUrl:RemoteJavascript:Error " + event.message);
            onError(event.message);
          }
        }
      );
    }
  };
})(this);