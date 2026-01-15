/*********************************************************************************************************************************
@ Class:         ChannelTriggerHandler
@ Author:        Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0012674 - Colour coding for Channel /Influencer Account
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.10.2022 / Acmatac SEING / Created the class.
@ Change history: 22.11.2022 / Bora CHHORN / Created Methord / US-0012636 - Influencer (API Profile Picture)
*********************************************************************************************************************************/
public with sharing class ChannelTriggerHandler {

    /*********************************************************************************************************************************
	@ Method:         calculateInfluencerColourCoding
	@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
	@ Purpose:        US-0012674 - Colour coding for Channel /Influencer Account
	@ Parameter:      Map<Id, Channel__c> mOldChannel, List<Channel__c> newChannel
	@ Event:          after update
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 17.10.2022 / Acmatac SEING  / Created the method.
	*********************************************************************************************************************************/
	public static void calculateInfluencerColourCoding(Map<Id, Channel__c> mOldChannel, List<Channel__c> newChannel){
        Set<Id> influencerIds = new Set<Id>();
        for(Channel__c newChann : newChannel){
            Channel__c oldChann = mOldChannel.get(newChann.Id);
            if(newChann.Colour_Coding__c != oldChann.Colour_Coding__c && String.isNotBlank(newChann.Influencer__c)){
                influencerIds.add(newChann.Influencer__c);
            }
        }
        if(influencerIds.isEmpty()) return;

        List<Account> listCalculateInfluencer = new List<Account>();
        for(Account oAcc: [SELECT Id, Numeric_Status__c, (SELECT Id, Numeric_Status__c FROM Influencers__r Order by Numeric_Status__c DESC LIMIT 1) From Account WHERE Id IN: influencerIds]){
            if(oAcc.Influencers__r.size() > 0){
                // If the same value no update, to prevent wasted CPU
                if(oAcc.Numeric_Status__c == oAcc.Influencers__r.get(0).Numeric_Status__c){
                    continue;
                }
                oAcc.Numeric_Status__c = oAcc.Influencers__r.get(0).Numeric_Status__c;
                listCalculateInfluencer.add(oAcc);
            }
        }
        if(!listCalculateInfluencer.isEmpty()){
            EBH_AccountTriggerHandler.NO_TRIGGER_RUN = true;
            update listCalculateInfluencer;
        }
    }
    /*********************************************************************************************************************************
	@ Method:         populateProfilePicture
	@ Author:         Bora CHHORN (bora.chhorn@gaea-sys.com)
	@ Purpose:        US-0012636 - Influencer (API Profile Picture)
	@ Parameter:      Map<Id, Channel__c> mOldChannel, List<Channel__c> newChannel
	@ Event:          before update, before insert
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 22.11.2022 / Bora CHHORN / Created Methord / US-0012636 - Influencer (API Profile Picture)
	@ Change history: 15.07.2023 / Veenus Gollapalli / Removing the Method / US-0015223 - Uninstall Shortify from our org
	*********************************************************************************************************************************/
    /*
	Commenting the method - US-0015223 - Uninstall Shortify from our org
	public static void populateProfilePicture(Map<Id, Channel__c> mOldChannel, List<Channel__c> newChannel){

        List<cfsu__URL__c> listShortify = new List<cfsu__URL__c>();
        Map<String, Channel__c> mapChannelExtId = new Map<String, Channel__c>();
        for(Channel__c newChann : newChannel){
            if((String.isNotBlank(newChann.Profile_Picture_Source__c) && mOldChannel == null) || (mOldChannel != null && newChann.Profile_Picture_Source__c != mOldChannel.get(newChann.Id).Profile_Picture_Source__c)){
                cfsu__URL__c shortURL = new cfsu__URL__c();
                shortURL.cfsu__sObjectID__c = newChann.ExtId__c;
                shortURL.cfsu__RedirectURL__c = newChann.Profile_Picture_Source__c;
                shortURL.cfsu__StartDate__c = Datetime.now();
                shortURL.cfsu__Key__c = 'pf_' + newChann.ExtId__c.toLowerCase();
                shortURL.ExtId__c = shortURL.cfsu__Key__c;
                listShortify.add(shortURL);
                mapChannelExtId.put(newChann.ExtId__c, newChann);
            }
        }
        if(!listShortify.isEmpty()){
            upsert listShortify ExtId__c;

            for(cfsu__URL__c shortify : [SELECT Id, cfsu__ShortURL__c, cfsu__sObjectID__c FROM cfsu__URL__c WHERE Id IN: listShortify]){
                mapChannelExtId.get(shortify.cfsu__sObjectID__c).Profile_Picture_link__c = shortify.cfsu__ShortURL__c;
            }
        }
    }*/
    /*********************************************************************************************************************************
	@ Method:         populateExtId
	@ Author:         Bora CHHORN (bora.chhorn@gaea-sys.com)
	@ Purpose:        US-0012636 - Influencer (API Profile Picture)
	@ Parameter:      List<Channel__c> newChannel
	@ Event:          before insert
	----------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 22.11.2022 / Bora CHHORN / Created Methord / US-0012636 - Influencer (API Profile Picture)
	*********************************************************************************************************************************/
	public static void populateExtId(List<Channel__c> newChannel){
        for(Channel__c newChann : newChannel){
            newChann.ExtId__c = ApexUtil.genUniqueStringNoSymbol(18);
        }
    }
}