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
    ctx.ACSFIntegration.CallTask = {
      onAgentHandler : function() {
        connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler not in console");
      }
    };

    return;
  }

  var _tabLabel;
  var _namespacePrefix;
  var _ccSettings;

  ctx.ACSFIntegration.CallTask = {
    onAgentHandler : function(namespacePrefix, tabLabel, ccSettings) {
      connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler invoked");

      _tabLabel = tabLabel;
      _namespacePrefix = namespacePrefix;
      _ccSettings = ccSettings;

      connect.contact(function(contact) {
        var conns = contact.getConnections();
        var custConn = conns.find(
          c => c.getType() === connect.ConnectionType.INBOUND || c.getType() === connect.ConnectionType.OUTBOUND
        )

        if (!custConn)
          return;

        var taskAction = _ccSettings["/reqConnectSFCCPOptions/reqTaskAction"] || 'none';

        setCallContextProperty('callType', contact.isInbound() ? 'Inbound' : 'Outbound');

        var phoneNumber = custConn.getEndpoint().phoneNumber;
        var containsAtSymbol = phoneNumber.indexOf('@') > -1;
        setCallContextProperty('callPhoneNumber', phoneNumber.substring(0, containsAtSymbol ? phoneNumber.indexOf('@') : phoneNumber.length).replace('sip:', ''));

        var taskAutoCreate = _ccSettings["/reqConnectSFCCPOptions/reqTaskAutoCreate"] || 'false';

        contact.onAccepted(function(contactAccepted) {
          connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler:ContactOnAcceptedHandler invoked");
          startActiveCall();
        });

        contact.onConnected(function(contactConnected) {
          connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler:ContactOnConnectedHandler invoked");

          connect.agent(function(agent) {
            setCallContextProperty('callAgentUserName', agent.getConfiguration().username);
            setCallContextProperty('callAgentFriendlyName', agent.getName());
          });

          if (contactConnected.isInbound()) {
            setCallContextProperty("callQueue", contactConnected.getQueue().name || '');
            startActiveCall();

            if (taskAutoCreate === 'true') {
              saveInitialTask(contactConnected, getCurrentCallContext());
            }
          }
        });

        contact.onEnded(function(contactEnded) {
          connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler:ContactOnEndedHandler invoked");

          connect.agent(function(agent) {
            setCallContextProperty('callAgentUserName', agent.getConfiguration().username);
            setCallContextProperty('callAgentFriendlyName', agent.getName());
          });

          setCallContextProperty("callEndTime", new Date().getTime());
          setCallContextProperty("callQueue", contactEnded.getQueue().name || '');

          if (taskAutoCreate === 'true') {
            updateTask(contactEnded, getCurrentCallContext());
          }
        });
      });
    }
  };

  function startActiveCall() {
    connect.getLog().info("ACSFIntegration:CallTask:onAgentHandler:startActiveCall invoked");
    setCallContextProperty("callActive", true);

    var callStartDate = new Date();

    setCallContextProperty("callStartTime", callStartDate.getTime());
    setCallContextProperty("callStartDate", callStartDate.toISOString());
    setCallContextProperty("callStartDateTime", callStartDate.toISOString().substr(0, 19).replace("T", " "));
  }

  function saveInitialTask(contact, context) {
    if (sforce.interaction) {
      var initialTaskString = getInitialTaskString(contact, context);

      connect.getLog().info("ACSFIntegration:CallTask:saveInitialTask saving task with URL parameters: " + initialTaskString);

      sforce.interaction.saveLog("Task", initialTaskString, saveInitialTaskCallback);
    }

    if (sforce.opencti) {
      var initialTaskObject = getInitialTaskObject(contact, context);

      connect.getLog().info("ACSFIntegration:CallTask:saveInitialTask saving task with object: " + JSON.stringify(initialTaskObject));

      sforce.opencti.saveLog({
        value: initialTaskObject,
        callback: saveInitialTaskCallback
      });
    }
  }

  function saveInitialTaskCallback(response) {
      if (response.success === false || response.result === null || response.returnValue === null) {
        connect.getLog().error("ACSFIntegration:CallTask:saveInitialTask failed to save task").withObject(response.error);
        return;
      }

      var taskId  = response.result || response.returnValue.recordId;

      connect.getLog().info("ACSFIntegration:CallTask:saveInitialTask task saved. Id=" + taskId);

      setCallContextProperty('callTaskId', taskId);

      var taskAction = _ccSettings["/reqConnectSFCCPOptions/reqTaskAction"] || 'none';

      if (taskAction === 'start') {
          popTask(getCurrentCallContext());
      }
  }

  function updateTask(contact, context) {
    if (context.callActive) {
      if (sforce.interaction) {
        var updateTaskString = getUpdateTaskString(contact, context);

        connect.getLog().info("ACSFIntegration:CallTask:updateTask updating task with URL parameters: " + updateTaskString);

        sforce.interaction && sforce.interaction.saveLog("Task", updateTaskString, updateTaskCallback);
      }

      if (sforce.opencti) {
        var updateTaskObject = getUpdateTaskObject(contact, context);

        connect.getLog().info("ACSFIntegration:CallTask:updateTask updating task with object: " + JSON.stringify(updateTaskObject));

        sforce.opencti && sforce.opencti.saveLog({
          value: updateTaskObject,
          callback: updateTaskCallback
        });
      }
    }
    else {
      clearCallContext();
    }
  }

  function updateTaskCallback(response) {
    if (response.success === false || response.result === null || response.returnValue === null) {
      connect.getLog().error("ACSFIntegration:CallTask:updateTask failed to update task").withObject(response.error);
      return;
    }

    var taskId  = response.result || response.returnValue.recordId;

    connect.getLog().info("ACSFIntegration:CallTask:updateTask task updated. Id=" + taskId);

    var taskAction = _ccSettings["/reqConnectSFCCPOptions/reqTaskAction"] || 'none';

    if (taskAction === 'end') {
      popTask(getCurrentCallContext());
      clearCallContext();
    }
  }

  function popTask(callContext) {
    var taskPage = _ccSettings["/reqConnectSFCCPOptions/reqTaskPage"] || 'ACSFCCP_CallTask';

    var taskURL = "/apex/" + taskPage + "?id=" + callContext.callTaskId + "&ani=" + callContext.callPhoneNumber;

    if (sforce.console) {
      // Classic Console
      sforce.console.getFocusedPrimaryTabId(function (result) {
        var primaryTabId = result.id;
        if (primaryTabId !== "null") {
          sforce.console.openSubtab(primaryTabId, taskURL, true, _tabLabel, null, popTaskCallback);
        } else {
          sforce.console.openPrimaryTab(null, taskURL, true, _tabLabel, popTaskCallback);
        }
      });
    } else {
      // Lightning Console
      sforce.opencti && sforce.opencti.screenPop({
        type: sforce.opencti.SCREENPOP_TYPE.URL,
        params: {
          url: taskURL
        },
        callback: popTaskCallback
      });
    }
  }

  function popTaskCallback(result) {
    connect.getLog().info("ACSFIntegration:CallTask:openWorkingTab invoked");
    if (result.success) {
      sforce.console && sforce.console.addEventListener(
          sforce.console.ConsoleEvent.CLOSE_TAB,
          onTabClose,
          { tabId : result.id }
      );
    }
    else {
      connect.getLog().error("ACSFIntegration:CallTask:openWorkingTab unable to open tab");
    }
  }

  function onTabClose(result) {
    connect.agent(function(agent) {
      connect.getLog().info("ACSFIntegration:CallTask:onTabClose invoked");
      var availableState = agent.getAgentStates().filter(function(state) {
        return state.name === "Available";
      })[0];
      agent.setState(availableState, {
        success : function() {
          connect.getLog().info("ACSFIntegration:CallTask:onTabClose agent state set to Available");
        },
        failure : function() {
          connect.getLog().error("ACSFIntegration:CallTask:onTabClose unable to set agent state to Available");
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
    connect.getLog().info("ACSFIntegration:CallTask:setCallContextProperty setting call context property " + name + " to " + value);
    sessionStorage.setItem("CCP-" + name, value);
  }

  function clearCallContext() {
    connect.getLog().info("ACSFIntegration:CallTask:clearCallContext clearing all call context");
    sessionStorage.removeItem("CCP-callActive");
    sessionStorage.removeItem("CCP-callQueue");
    sessionStorage.removeItem("CCP-callType");
    sessionStorage.removeItem("CCP-callStartTime");
    sessionStorage.removeItem("CCP-callEndTime");
    sessionStorage.removeItem("CCP-callStartDate");
    sessionStorage.removeItem("CCP-callStartDateTime");
    sessionStorage.removeItem("CCP-callPhoneNumber");
    sessionStorage.removeItem("CCP-callAgentUserName");
    sessionStorage.removeItem("CCP-callAgentFriendlyName");
    sessionStorage.removeItem("CCP-callTaskId");
    sessionStorage.removeItem("CCP-whoId");
    sessionStorage.removeItem("CCP-whatId");
  }

  function getCurrentCallContext() {
    var result = {
      callActive: sessionStorage.getItem("CCP-callActive"),
      callQueue: sessionStorage.getItem("CCP-callQueue"),
      callType: sessionStorage.getItem("CCP-callType"),
      callStartTime: sessionStorage.getItem("CCP-callStartTime"),
      callEndTime: sessionStorage.getItem("CCP-callEndTime"),
      callStartDate: sessionStorage.getItem("CCP-callStartDate"),
      callStartDateTime: sessionStorage.getItem("CCP-callStartDateTime"),
      callPhoneNumber: sessionStorage.getItem("CCP-callPhoneNumber"),
      callAgentUserName: sessionStorage.getItem("CCP-callAgentUserName"),
      callAgentFriendlyName: sessionStorage.getItem("CCP-callAgentFriendlyName"),
      callTaskId: sessionStorage.getItem("CCP-callTaskId"),
      whoId: sessionStorage.getItem("CCP-whoId"),
      whatId: sessionStorage.getItem("CCP-whatId")
    };

    connect.getLog().info("ACSFIntegration:CallTask:getCurrentCallContext Current call context: ").withObject(result);
    return result;
  }

  function getInitialTaskString(callContact, callContext) {
    var queueName = getQueueName(callContext);

    var taskString = "CallObject=" + callContact.getContactId() +
        "&CallType=" + callContext.callType +
        "&Type=" + "Call" +
        "&IsClosed=" + true +
        "&Status=" + "Completed" +
        "&ActivityDate=" + callContext.callStartDate +
        "&Subject=" + callContext.callType + " - " + queueName + " - "+ callContext.callPhoneNumber +
        "&TaskSubtype=" + "Call" +
        "&Phone=" + callContext.callPhoneNumber;

    taskString = encodeURI(taskString);

    return taskString;
  }

  function getInitialTaskObject(callContact, callContext) {
    var queueName = getQueueName(callContext);

    var taskObject = {
      entityApiName: "Task",
      CallObject: callContact.getContactId(),
      CallType: callContext.callType,
      Type: "Call",
      IsClosed: true,
      Status: "Completed",
      ActivityDate: callContext.callStartDate,
      Subject: callContext.callType + " - " + queueName + " - " + callContext.callPhoneNumber,
      TaskSubtype: "Call",
      Phone: callContext.callPhoneNumber
    };

    return taskObject;
  }

  function getUpdateTaskString(callContact, callContext) {
    var taskDuration = getTaskDuration(callContact, callContext);

    var taskString = "Id=" + callContext.callTaskId +
        "&CallDurationInSeconds=" + taskDuration  +
        "&WhatId=" + callContext.whatId +
        "&WhoId=" + callContext.whoId;

    taskString = encodeURI(taskString);

    return taskString;
  }

  function getUpdateTaskObject(callContact, callContext) {
    var taskDuration = getTaskDuration(callContact, callContext);

    var taskObject = {
      Id: callContext.callTaskId,
      CallDurationInSeconds: taskDuration,
      WhatId: callContext.whatId,
      WhoId: callContext.whoId
    };

    return taskObject;
  }

  function getQueueName(callContext) {
    if (callContext.callQueue && callContext.callQueue !== '') {
      return callContext.callQueue;
    }
    else {
      var includeAgentFriendlyName = _ccSettings["/reqConnectSFCCPOptions/reqTaskIncludeAgentFriendlyName"] || 'false';

      var queueName = callContext.callAgentUserName;
      queueName += includeAgentFriendlyName === 'true' ? ' (' + callContext.callAgentFriendlyName + ')' : '';

      return queueName;
    }
  }

  function getTaskDuration(callContact, callContext) {
    if (callContext.callEndTime) {
      return Math.floor((callContext.callEndTime - callContext.callStartTime) / 1000);
    }

    return 0;
  }
})(this);