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

  if (sforce.console && !sforce.console.isInConsole()) {
    ctx.ACSFIntegration.PostCallTask = {
      onAgentHandler : function() {
        connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler not in console");
      }
    };

    return;
  }

  var _tabLabel;
  var _namespacePrefix;

  ctx.ACSFIntegration.PostCallTask = {
    onAgentHandler : function(namespacePrefix, tabLabel) {
      connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler invoked");
      _tabLabel = tabLabel;
      _namespacePrefix = namespacePrefix;

      connect.contact(function(contact) {
        var conns = contact.getConnections();
        var custConn = conns.find(
          c => c.getType() === connect.ConnectionType.INBOUND ||
          c.getType() === connect.ConnectionType.OUTBOUND
         );
        if (!custConn)
          return;

        setCallContextProperty('callType', contact.isInbound() ? 'Inbound' : 'Outbound');

        var phoneNumber = custConn.getEndpoint().phoneNumber;
        var containsAtSymbol = phoneNumber.indexOf('@') > -1;
        setCallContextProperty('callPhoneNumber', phoneNumber.substring(0, containsAtSymbol ? phoneNumber.indexOf('@') : phoneNumber.length).replace('sip:', ''));

        contact.onAccepted(function(contactOnAccepted) {
          connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler:ContactOnAcceptedHandler invoked");
          startActiveCall();
        });

        contact.onConnected(function(contactOnConnected) {
          connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler:ContactOnConnectedHandler invoked");
          if (!contactOnConnected.isInbound()) {
            startActiveCall();
          }
        });

        contact.onEnded(function(contactOnEnded) {
          connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler:ContactOnEndedHandler invoked");
          setCallContextProperty("callEndTime", new Date().getTime());
          setCallContextProperty("callQueue", contact.getQueue().name);

          var callContext = getCurrentCallContext();

          clearCallContext();
          if (callContext.callActive) {
            createTask(contactOnEnded, callContext);
          }
        });
      });
    }
  };

  function startActiveCall() {
    connect.getLog().info("ACSFIntegration:PostCallTask:onAgentHandler:startActiveCall invoked");
    setCallContextProperty("callActive", true);

    var callStartdate = new Date();

    setCallContextProperty("callStartTime", new Date().getTime());
    setCallContextProperty("callStartdate", callStartdate.toISOString());
    setCallContextProperty("callStartDateTime", callStartdate.toISOString().substr(0, 19).replace("T", " "));
  }

  function createTask(callContact, callContext) {
    connect.getLog().info("ACSFIntegration:PostCallTask:createTask invoked");
    var callDuration = Math.floor((callContext.callEndTime - callContext.callStartTime) / 1000);

    var taskStr = "CallDurationInSeconds=" + callDuration  +
      "&CallObject=" + callContact.getContactId() +
      "&CallType=" + callContext.callType +
      "&Type=" + "Call" +
      "&IsClosed=" + true +
      "&Status=" + "Completed" +
      "&ActivityDate=" + callContext.callStartdate +
      "&Subject=" + callContext.callType + " - "+ callContext.callQueue + " - "+ callContext.callPhoneNumber +
      "&TaskSubtype=" + "Task" +
      "&Phone=" + callContext.callPhoneNumber;

    var taskObj = {
      entityApiName: "Task",
      CallDurationInSeconds: callDuration,
      CallObject: callContact.getContactId(),
      CallType: callContext.callType,
      Type: "Call",
      IsClosed: true,
      Status: "Completed",
      ActivityDate: callContext.callStartdate,
      Subject: callContext.callType + " - " + callContext.callQueue + " - " + callContext.callPhoneNumber,
      TaskSubtype: "Task",
      Phone: callContext.callPhoneNumber
    }

    connect.getLog().info("ACSFIntegration:PostCallTask:createTask saving task with URL parameters: " + taskStr);

    function saveLogCallback(response) {
      if (response.success === false || response.result === null || response.returnValue === null) {
        connect.getLog().error("ACSFIntegration:PostCallTask:createTask failed to save task").withObject(response.error);
        return;
      }

      var taskId  = response.result || response.returnValue.recordId;

      connect.getLog().info("ACSFIntegration:PostCallTask:createTask task saved. Id=" + taskId);
      var taskURL = "/apex/" + _namespacePrefix + "ACSFCCP_PostCallUpdateTask?id=" + taskId;

      if (sforce.console) {
        // Classic Console
        sforce.console.getFocusedPrimaryTabId(function(result){
          var primaryTabId = result.id;
          if (primaryTabId !== "null"){
            sforce.console.openSubtab(primaryTabId , taskURL, true, _tabLabel, null, openWorkingTab);
          }
          else {
            sforce.console.openPrimaryTab(null, taskURL, true, _tabLabel, openWorkingTab);
          }
        });
      } else {
        // Lightning Console
        sforce.opencti && sforce.opencti.screenPop({
          type: sforce.opencti.SCREENPOP_TYPE.URL,
          params: {
            url: taskURL
          }
        });
      }
    }

    sforce.interaction && sforce.interaction.saveLog("Task", taskStr, saveLogCallback);
    sforce.opencti && sforce.opencti.saveLog({
      value: taskObj,
      callback: saveLogCallback
    });
  }

  function openWorkingTab(result) {
    connect.getLog().info("ACSFIntegration:PostCallTask:openWorkingTab invoked");
    if (result.success) {
      sforce.console && sforce.console.addEventListener(
        sforce.console.ConsoleEvent.CLOSE_TAB,
        onTabClose,
        { tabId : result.id }
      );
    }
    else {
      connect.getLog().error("ACSFIntegration:PostCallTask:openWorkingTab unable to open tab");
    }
  }

  function onTabClose(result) {
    connect.agent(function(agent) {
      connect.getLog().info("ACSFIntegration:PostCallTask:onTabClose invoked");
      var availableState = agent.getAgentStates().filter(function(state) {
        return state.name === "Available";
      })[0];
      agent.setState(availableState, {
        success : function() {
          connect.getLog().info("ACSFIntegration:PostCallTask:onTabClose agent state set to Available");
        },
        failure : function() {
          connect.getLog().error("ACSFIntegration:PostCallTask:onTabClose unable to set agent state to Available");
        }
      });
    });

    sforce.console && sforce.console.removeEventListener(
      sforce.console.ConsoleEvent.CLOSE_TAB,
      onTabClose,
      { tabId : result.id }
    );
  }

  function setCallContextProperty(name, value) {
    connect.getLog().info(
      "ACSFIntegration:PostCallTask:setCallContextProperty setting call context property " +
      name + " to " + value
    );
    sessionStorage.setItem("CCP-" + name, value);
  }

  function clearCallContext() {
    connect.getLog().info("ACSFIntegration:PostCallTask:clearCallContext clearing all call context");
    sessionStorage.removeItem("CCP-callActive");
    sessionStorage.removeItem("CCP-callQueue");
    sessionStorage.removeItem("CCP-callType");
    sessionStorage.removeItem("CCP-whoId");
    sessionStorage.removeItem("CCP-callStartTime");
    sessionStorage.removeItem("CCP-callEndTime");
    sessionStorage.removeItem("CCP-callStartdate");
    sessionStorage.removeItem("CCP-callStartDateTime");
    sessionStorage.removeItem("CCP-callPhoneNumber");
  }

  function getCurrentCallContext() {
    var result = {
      callActive: sessionStorage.getItem("CCP-callActive"),
      callQueue: sessionStorage.getItem("CCP-callQueue"),
      callType: sessionStorage.getItem("CCP-callType"),
      whoId: sessionStorage.getItem("CCP-whoId"),
      callStartTime: sessionStorage.getItem("CCP-callStartTime"),
      callEndTime: sessionStorage.getItem("CCP-callEndTime"),
      callStartdate: sessionStorage.getItem("CCP-callStartdate"),
      callStartDateTime: sessionStorage.getItem("CCP-callStartDateTime"),
      callPhoneNumber: sessionStorage.getItem("CCP-callPhoneNumber")
    };
    connect.getLog().info("ACSFIntegration:PostCallTask:getCurrentCallContext Current call context: ").withObject(result);
    return result;
  }
})(this);