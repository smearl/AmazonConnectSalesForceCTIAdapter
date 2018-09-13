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

  if (!sforce.console.isInConsole()) {
    ctx.ACSFIntegration.OmniPresenceSync = {
      onAgentHandler : function() {
        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler not in console");
      }
    };

    return;
  }

  function setConnectAgentState(stateName) {
    connect.agent(function(agent) {
      var matchingStates = agent.getAgentStates().filter(function(state) {
        return state.name.replace(" ", "_") === stateName;
      });
      if (matchingStates.length === 1 && matchingStates[0].name !== agent.getState().name) {
        agent.setState(matchingStates[0], {
          success: function() {
            connect.getLog().info("ACSFIntegration:OmniPresenceSync:setConnectAgentState " +
                                  "AC agent state set to " + matchingStates[0].name);
          },
          failure: function() {
            connect.getLog().error("ACSFIntegration:OmniPresenceSync:setConnectAgentState " +
                                  "unable to set AC agent state to " + matchingStates[0].name);
          }
        });
      }
    });
  }

  ctx.ACSFIntegration.OmniPresenceSync = {
    onAgentHandler : function() {
      connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler invoked");

      sforce.console.addEventListener(
        sforce.console.ConsoleEvent.PRESENCE.STATUS_CHANGED,
        function(result) {
          connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:OmniStatusChangedHandler invoked; " +
                                "Omni status changed to " + result.statusApiName);
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

      var sps = new SObjectModel.ServicePresenceStatus();
      var servicePresenceStatusMap = new Map();
      sps.retrieve({}, function(err, records, event) {
        if (err) {
          connect.getLog().error("ACSFIntegration:OmniPresenceSync:onAgentHandler " +
                                 "unable to retrieve Omni Presence statuses.")
                          .withObject(err);
        }
        else {
          records.forEach(function(record) {
            var key = record.get("DeveloperName");
            var value = record.get("Id").substr(0, 15);
            servicePresenceStatusMap.set(key, value);
          });
        }
      });

      connect.agent(function(agent) {
        agent.onStateChange(function(stateChange) {
          connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler invoked; " +
                                "AC agent state changed to " + stateChange.newState);
          var newStateName = stateChange.newState.replace(" ", "_");

          if (newStateName === "Offline") {
            sforce.console.presence.getServicePresenceStatusId(function(getStatusResult) {
              if (getStatusResult.success) {
                sforce.console.presence.logout(function(logoutResult) {
                  if (logoutResult.success) {
                    connect.getLog().info("ACSFIntegrationOmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler logged out of Omni");
                  }
                  else {
                    connect.getLog().error("ACSFIntegrationOmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler unable to log out of Omni")
                                    .withObject(logoutResult);
                  }
                });
              }
            });
          }
          else if (servicePresenceStatusMap.has(newStateName)) {
            var statusId = servicePresenceStatusMap.get(newStateName);

            sforce.console.presence.getServicePresenceStatusId(
              function(getStatusResult) {
                var currentStatusId = getStatusResult.statusId;
                if (currentStatusId !== statusId) {
                  sforce.console.presence.setServicePresenceStatus(
                    statusId,
                    function(setStatusResult) {
                      if (setStatusResult.success) {
                        connect.getLog().info("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler " +
                                              "Omni state set to " + newStateName);
                      }
                      else {
                        connect.getLog().error("ACSFIntegration:OmniPresenceSync:onAgentHandler:AgentOnStateChangeHandler " +
                                               "unable to set Omni state to " + newStateName)
                                        .withObject(setStatusResult);
                      }
                    }
                  );
                }
              }
            );
          }
        });
      });
    }
  };
})(this);
