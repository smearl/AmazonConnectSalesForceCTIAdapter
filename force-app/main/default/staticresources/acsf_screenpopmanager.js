// acsf_screenpopmanager
// MD - this is meant for classic
(function (ctx) {

    var ACSF_SCREEN_POP_RECORD_ATTRIBUTE_KEY = 'acsf-screenpop-record';
    var ACSF_SCREEN_POP_SEARCH_ATTRIBUTE_KEY = 'acsf-screenpop-search';

    if (ctx.ACSFIntegration === undefined) {
        ctx.ACSFIntegration = {};
    }

    connect.getLog().info("ACSFIntegration:ScreenpopManager:initializing");

    function setSoftphoneVisible() {
        sforce.interaction && sforce.interaction.setVisible(true);
        sforce.opencti && sforce.opencti.setSoftphonePanelVisibility({ visible: true });
    }

    function ctiSearchAndPop(searchParams, queryParams, callType) {
        function callback(response) {
            connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiSearchAndPop:Response");
            try {
                if (response.success || response.result) {
                    connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiSearchAndPop:Result");
                    console.log(JSON.stringify(response.returnValue || response.result));
                } else {
                    connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiSearchAndPop:Error:" + (response.error || JSON.stringify(response.errors)));
                }
            } catch (ex) {
                connect.getLog().error("ACSFIntegration:ScreenpopManager:ctiSearchAndPop:Error:" + JSON.stringify(ex));
            }
        }

        sforce.interaction && sforce.interaction.searchAndScreenPop(searchParams, queryParams, callType, callback);
        sforce.opencti && sforce.opencti.searchAndScreenPop({
            searchParams: searchParams,
            queryParams: queryParams,
            callType: callType,
            deferred: false,
            callback: callback
        });
    }

    function popCtiUrl(url) {
        function callback(response) {
            connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiPop:Response:" + JSON.stringify(response));
            try {
                if (response.success || response.result) {
                    connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiPop:Result:" + JSON.stringify(response.returnValue || response.result));
                } else {
                    connect.getLog().info("ACSFIntegration:ScreenpopManager:ctiPop:Error:" + (response.error || JSON.stringify(response.errors)));
                }
            } catch (ex) {
                connect.getLog().error("ACSFIntegration:ScreenpopManager:ctiPop:Error:" + JSON.stringify(ex));
            }
        }

        sforce.interaction && sforce.interaction.screenPop(url, true, callback);
        sforce.opencti && sforce.opencti.screenPop({
            type: sforce.opencti.SCREENPOP_TYPE.URL,
            params: {
                url: url
            },
            callback: callback
        });
    }

    function cbGetPageInfo(response) {
        if (response.result) {
            connect.getLog().info("ACSFIntegration:cbGetPageInfo:" + response.result);
        } else {
            connect.getLog().error("ACSFIntegration:cbGetPageInfo:Error:" + response.error);
        }
    };

    function searchAndPopAni(contact, connectPhoneFormat) {
        connect.getLog().info("ACSFIntegration:ScreenpopManager:searchAndPopAni:InboundPhone:Invoked");
        var phoneNumber = contact.getInitialConnection().getAddress().phoneNumber;
        connect.getLog().info("ACSFIntegration:ScreenpopManager:searchAndPopAni:InboundPhone:PN:" + phoneNumber);
        var phoneParsed = libphonenumber.parse(phoneNumber, { country: { default: connectPhoneFormat.Country } });
        connect.getLog().info("ACSFIntegration:ScreenpopManager:searchAndPopAni:InboundPhone:Parsed:" + phoneParsed.country + "|" + phoneParsed.phone);

        connect.getLog().info("ACSFIntegration:ScreenpopManager:searchAndPopAni:GPICall");
        sforce.interaction && sforce.interaction.getPageInfo(cbGetPageInfo);
        connect.getLog().info("ACSFIntegration:ScreenpopManager:searchAndPopAni:ScreenPopSrch");
        ctiSearchAndPop(phoneParsed.phone, '', 'inbound');
    }

    function popRecordOrSearch(contact, connectPhoneFormat) {
        var attributes = contact.getAttributes();
        connect.getLog().info("ACSFIntegration:ScreenpopManager:popRecordOrSearch:attributes:" + JSON.stringify(attributes));

        var screenPopRecordAttribute = attributes[ACSF_SCREEN_POP_RECORD_ATTRIBUTE_KEY];
        if (screenPopRecordAttribute && screenPopRecordAttribute.value) {
            connect.getLog().info("ACSFIntegration:ScreenpopManager:popRecordOrSearch:popRecordFound:" + screenPopRecordAttribute.value);
            popCtiUrl("/" + screenPopRecordAttribute.value);
            return;
        }

        var screenPopSearchAttribute = attributes[ACSF_SCREEN_POP_SEARCH_ATTRIBUTE_KEY];
        if (screenPopSearchAttribute && screenPopSearchAttribute.value) {
            connect.getLog().info("ACSFIntegration:ScreenpopManager:popRecordOrSearch:popSearchFound:" + screenPopSearchAttribute.value);
            ctiSearchAndPop(screenPopSearchAttribute.value, '', 'inbound');
            return;
        }

        searchAndPopAni(contact, connectPhoneFormat);
    }


    //entrypoint
    ctx.ACSFIntegration.ScreenpopManager = {
        onConnecting: function (contact, connectPhoneFormat) {
            connect.getLog().info("ACSFIntegration:ScreenpopManager:onConnecting");
            setSoftphoneVisible();

            if (sforce.console && !sforce.console.isInConsole()) {

                connect.getLog().warn("ACSFIntegration:ScreenpopManager:onConnecting Screen pops not recommended outside of Console");
                //return;

            }

            if (!contact.isInbound()) {
                connect.getLog().warn("ACSFIntegration:ScreenpopManager:onConnecting Outbound call detected, no screen pop will be performed");
                return;
            }

            popRecordOrSearch(contact, connectPhoneFormat);
        }
    };



})(this);