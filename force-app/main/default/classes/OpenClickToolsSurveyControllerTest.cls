@isTest
private class OpenClickToolsSurveyControllerTest {
    @testSetup 
    static void setupData(){
        insert new EBH_OutboundLink__c (Name='EBH_OutboundLink__c',Clicktools_Inbound_Survey__c='ThisIsAtest',
                                        EBH_URL__c='http://www.ebay.com',
                                        EBH_TicketURL__c ='http://www.ebay.de',
                                        NPS_Survey_URL__c ='http://www.ebay.co.uk',
                                        HUB_Search__c ='http://www.hub.de',
                                        EBH_ExternalCampaignRecordTypeId__c ='IdTest',
                                        //EBH_DriverTreeBaseURL__c ='http://www.ebay.com',
                                        Clicktools_Outbound_Survey__c ='213434334',
                                        
                                        Clicktools_Epilogue_Survey__c ='23434343'
                                       );
        
    }
    @isTest
    static void testmethod1(){
        EBH_TestDataFactory.setUpCustomSettings(); 
        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller') ;
        RecordType contactManaul = ApexUtil.getRecordTypeByName('Contact','EBH_MANUAL');
        List<Contact> listContact = new List<Contact>{
            new Contact(EBH_Status__c='Active', LastName = 'last1', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test'),
                new Contact(EBH_Status__c='Inactive', LastName = 'last2', AccountId = sellers[0].Id,recordTypeId = contactManaul.Id, EBH_DataOrigin__c='test')
                };
                    
                    insert listContact;
        List<Campaign> campaigns = EBH_TestDataFactory.createCampaigns(1, 'Request', 'UK', 'EBH_AMOutreach');   
        campaigns[0].survey_id__c='1t6nqa0iq6nmy';  
        
        update campaigns;
        
        List<CampaignMember> campmembers= EBH_TestDataFactory.createCampaignMembers(1, campaigns[0].id, listContact[0].id, false);
        //insert campmembers;
        
        Test.startTest();
            Task t1 = new Task( WhatId=sellers[0].Id,WhoId=listContact[0].Id,Subject=EBH_ConstantsUtility.TTH_URGENCYTASK);
            t1.ebh_campaignmemberid__c=campmembers[0].id;
            insert t1;
            
            
            Map<String,Object> mapResult = OpenClickToolsSurveyController.apexInitClicTool(t1.Id);
        
         
        Test.stopTest();
        
    }
    
}