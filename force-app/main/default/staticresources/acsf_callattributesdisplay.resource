/** Copyright 2017 Aria Solutions Inc.

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated
documentation files (the "Software"), to deal in the Software without restriction, including without limitation the
rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit
persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/

(function(ctx) {
  if (ctx.ACSFIntegration === undefined) {
    ctx.ACSFIntegration = {};
  }

  var _MAX_WIDTH_CONSOLE = 110;

  var _callAttributeConfigurationPromise;

  function clearCallAttributes() {
    var attributeList = document.getElementById('callAttributesList');
    while (attributeList.hasChildNodes()) {
      attributeList.removeChild(attributeList.lastChild);
    }
  }

  function createTruncatedDiv(text) {
    var div = document.createElement('div');
    div.classList.add('slds-truncate');
    div.setAttribute('title', text);
    div.style['max-width'] = _MAX_WIDTH_CONSOLE + 'px';

    var textElement = document.createTextNode(text);

    div.appendChild(textElement);
    return div;
  }

  function createTd(text) {
    var td = document.createElement('td');
    td.setAttribute('data-label', text);

    td.appendChild(createTruncatedDiv(text));
    return td;
  }

  function addTableRow(key, value) {
    var attributeList = document.getElementById('callAttributesList');
    var tr = document.createElement('tr');

    tr.appendChild(createTd(key));
    tr.appendChild(createTd(value));

    attributeList.appendChild(tr);
  }

  function showCallAttributes() {
    document.getElementById('callAttributesPopoverContainer').
              classList.remove('hidden');
  }

  function hideCallAttributes() {
    document.getElementById('callAttributesPopoverContainer').
          classList.add('hidden');
  }

  function showCallAttributeBadge() {
    document.getElementById('callAttributesBadge').
      classList.remove('hidden');
  }

  function isCallAttributeBadgeVisiable() {
      return document.getElementById('callAttributesBadge').
        classList.contains('hidden') === false;
    }

  function hideCallAttributeBadge() {
    document.getElementById('callAttributesBadge').
      classList.add('hidden');
  }

  function handleBadgeClicked() {
    document.getElementById('callAttributesPopoverContainer').
      classList.toggle('hidden');
  }

  function createCallAttributesForContactIfApplicable(contact) {
    if (!contact.isInbound()) {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:createCallAttributesForContactIfApplicable:call not inbound");
      return;
    }

    var attributes = contact.getAttributes();
    var numAttributes = Object.keys(attributes).length;

    connect.getLog().info("ACSFIntegration:CallAttributesDisplay:createCallAttributesForContactIfApplicable:numAttributes=%s", numAttributes);
    if (numAttributes === 0) {
      hideCallAttributeBadge();
      return;
    }

    _callAttributeConfigurationPromise.
      then(function (config) {
        var shouldShowBadge = false;
        for (var key in attributes) {
          attributeRecord = attributes[key];

          var attrConfig = config[attributeRecord.name];
          if (attrConfig) {
            addTableRow(attrConfig.label, attributeRecord.value);
            shouldShowBadge = true;
          }
        }

        if (shouldShowBadge) {
          showCallAttributeBadge();
        }
      }).
      catch(function () {
        hideCallAttributeBadge();
      });
  }

  ctx.ACSFIntegration.CallAttributesDisplay = {
    onAgentHandler: function () {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:onAgentHandler");
      document.getElementById('callAttributesBadge').onclick = function () {
        handleBadgeClicked();
      };

      _callAttributeConfigurationPromise = new Promise(function (resolve, reject) {
        var callAttributeSO = new SObjectModel.Call_Attributes_Configuration();
        callAttributeSO.retrieve({}, function(err, records, event) {
          if (err) {
            connect.getLog().
              error("ACSFIntegration:CallAttributesDisplay:retrieveCallAttributeConfiguration unable to retrieve Call Attribute Configuration statuses.").
              withObject(err);

            reject(err);
          }
          else {
            var callAttributeConfiguration = [];
            records.forEach(function(record) {
              var key = record.get("Attribute_Name");
              var label = record.get("CCP_Attribute_Label")
              callAttributeConfiguration[key] = {'label': label};
            });

            connect.getLog().info("ACSFIntegration:CallAttributesDisplay:retrieveCallAttributeConfiguration:callAttributeConfiguration retrieved: " + JSON.stringify(callAttributeConfiguration));

            resolve(callAttributeConfiguration);
          }

          connect.agent(function (agent) {
            if (agent.getContacts().length === 1) {
              var contact = agent.getContacts()[0];
              createCallAttributesForContactIfApplicable(contact);
            }
          });
        });
      });
    },

    onConnecting: function(contact) {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:onConnecting");
      createCallAttributesForContactIfApplicable(contact);
    },

    onExistingCall: function() {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:onExistingCall");
    },

    onAccepted: function(contact) {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:onAccepted");
      if (isCallAttributeBadgeVisiable()) {
        showCallAttributes();
      }
    },

    onEnded: function() {
      connect.getLog().info("ACSFIntegration:CallAttributesDisplay:onEnded");
      hideCallAttributes();
      clearCallAttributes();
      hideCallAttributeBadge();
    }
  };
})(this);
