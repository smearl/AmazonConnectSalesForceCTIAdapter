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

  if (!sforce.console.isInConsole()) {
    ctx.ACSFIntegration.OmniPresenceSync = {
      onAgentHandler: function() {
        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler not in console");
      }
    };

    return;
  }

  var _namespacePrefix;
  var _ccSettings;

  ctx.ACSFIntegration.OmniPresenceSync = {
    onAgentHandler: function(namespacePrefix, ccSettings) {
      connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler invoked");

      _namespacePrefix = namespacePrefix;
      _ccSettings = ccSettings;

      var agentStateSyncEnabled = _ccSettings["/reqConnectSFCCPOptions/reqAgentStateSyncEnabled"] || 'false';

      if (agentStateSyncEnabled === 'true') {

        var servicePresenceStatusMap = new Map();

        Visualforce.remoting.Manager.invokeAction(
          _namespacePrefix + "ACSFCCP_CallInformationController.getServicePresenceStatuses",
          function (result, event) {
            if (event.status && result) {
              result.forEach(function (record) {
                var key = record.developerName;
                var value = record.id.substr(0, 15);
                servicePresenceStatusMap.set(key, value);
              });
            } else {
              console.log("ACSFIntegration:OmniPresenceSync: %s", JSON.stringify(event));
            }
          }
        );

        enablePresenceListeners();

        connect.agent(function (agent) {
          agent.onStateChange(function (stateChange) {
            connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler invoked; AC agent state changed to %s", stateChange.newState);
            var newStateName = stateChange.newState.replace(" ", "_");

            if (newStateName === "Offline") {
              sforce.console.presence.getServicePresenceStatusId(function (getStatusResult) {
                if (getStatusResult.success) {
                  disablePresenceListeners();
                  sforce.console.presence.logout(function (logoutResult) {
                    if (logoutResult.success) {
                      connect.getLog().info("ACSFIntegrationOmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler logged out of Omni");
                    } else {
                      connect.getLog().error("ACSFIntegrationOmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler unable to log out of Omni").withObject(logoutResult);
                    }
                  });
                }
              });
            } else if (servicePresenceStatusMap.has(newStateName)) {
              var statusId = servicePresenceStatusMap.get(newStateName);

              sforce.console.presence.getServicePresenceStatusId(function (getStatusResult) {
                var currentStatusId = getStatusResult.statusId;
                if (currentStatusId !== statusId) {
                  disablePresenceListeners();
                  sforce.console.presence.setServicePresenceStatus(
                    statusId,
                    function (setStatusResult) {
                      if (setStatusResult.success) {
                        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler Omni state set to %s", newStateName);
                      } else {
                        connect.getLog().error("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler unable to set Omni state to %s", newStateName).withObject(setStatusResult);
                      }
                    }
                  );
                }
              });
            }
            else {
              connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler Omnipresence / Agent State Sync is not enabled.");
            }
          });
        });
      }
    }
  };

  function setConnectAgentState(stateName) {
    connect.agent(function(agent) {
      var agentStates = agent.getAgentStates();
      var matchingStates = agentStates.filter(function(state) {
        return state.name.replace(" ", "_") === stateName;
      });

      if (matchingStates.length === 1 && matchingStates[0].name !== agent.getState().name) {
        agent.setState(matchingStates[0], {
          success: function() {
            connect.getLog().info("ACSFIntegration:OmniPresenceSync:setConnectAgentState AC agent state set to %s", matchingStates[0].name);
          },
          failure: function() {
            connect.getLog().error("ACSFIntegration:OmniPresenceSync:setConnectAgentState unable to set AC agent state to %s", matchingStates[0].name);
          }
        });
      }
    });
  }

  function enablePresenceListeners() {
    sforce.console.addEventListener(
      sforce.console.ConsoleEvent.PRESENCE.STATUS_CHANGED,
      function(result) {
        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:OmniStatusChangedHandler invoked; Omni status changed to %s", result.statusApiName);
        var omniStatus = result.statusApiName;
        setConnectAgentState(omniStatus);
      }
    );

    sforce.console.addEventListener(
      sforce.console.ConsoleEvent.PRESENCE.LOGOUT,
      function() {
        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:OmniLogoutHandler invoked; Logged out of Omni");
        setConnectAgentState("Offline");
      }
    );
  }

  function disablePresenceListeners() {
    sforce.console.removeEventListener(
      sforce.console.ConsoleEvent.PRESENCE.STATUS_CHANGED,
      function(result) {
      }
    );

    sforce.console.removeEventListener(
      sforce.console.ConsoleEvent.PRESENCE.LOGOUT,
      function() {
      }
    );

  }
})(this);
