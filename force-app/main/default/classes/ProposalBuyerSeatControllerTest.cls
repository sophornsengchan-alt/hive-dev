/*********************************************************************************************************************************
@ Class:          ProposalBuyerSeatControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test Class for ProposalBuyerSeatControllerTest
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  17.12.2021 / Sophal Noch / Create Class. US-0009971 - Buyer Seat on PG Opportunities 
*********************************************************************************************************************************/
@isTest
private class ProposalBuyerSeatControllerTest {
    static Opportunity opp;
    static Id adServerDartRTId = ApexUtil.getRecordTypeByName('AdServer_Login__c','DART6').Id;
    static AdServer_Login__c adServer;
    static String oppPgRecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','Programmatic').Id;
    static Account acc;

    private static void setUpData(){
        adServer = new AdServer_Login__c(
            Name = 'US',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuser@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='123456',
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx',
            RT_Waiting__c = true,
            RecordTypeId = adServerDartRTId,
            ExternalLineDescriptionId__c = '123456789'
        );
        insert adServer;

        acc = TST_DataGenerator.generateAccount();
        acc.Record_Type_Text__c = 'Advertiser';
        insert acc;

        Id accId = acc.Id;
        acc = [Select Id,Name, RecordType.Name From Account Where Id =: accId ];


        opp = TST_DataGenerator.generateOpp(acc.Id);
        opp.Name = 'Test test test test';
        opp.OwnerId = UserInfo.getUserId();

        Date startDate = Date.today().addDays(1);
        Date endDate = Date.today().addDays(2);

        opp.Start_Date__c = startDate;
        opp.End_Date__c = endDate;
        opp.RecordTypeId = oppPgRecordTypeId;

        insert opp;

    }

    @isTest
    private static void testGetBuyerFromGAM(){
        setUpData();

        Test.startTest();
            ProposalBuyerSeatController.apexInit();
            Map<String, Object> mapResult = ProposalBuyerSeatController.getBuyers('US', null);
            System.assertEquals(null, mapResult.get('error'));
            ProposalBuyerSeatController.apexSave(opp.Id, DARTMockUp.buyerAccountId);

            Opportunity oppAfterQuery = [Select Id, Buyer_Seat__c from Opportunity where Id =: opp.Id];

            System.assertEquals(DARTMockUp.buyerAccountId, oppAfterQuery.Buyer_Seat__c);

        Test.stopTest();
        

    }
}