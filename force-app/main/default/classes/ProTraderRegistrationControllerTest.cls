@isTest
private class ProTraderRegistrationControllerTest {
    @testSetup static void setUp() {
        RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
        BoB__c bob = new BoB__c(Status__c= 'BoB Active',EBH_BOBCNTRY__c='Spain',EBH_BOBVertical__c='Fashion',RecordTypeId = bobRecordTypeLTTM.Id,Account_Manager__c = UserInfo.getUserId());
        insert bob;
        
        RecordType bobSellerRecordTypeLttm = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        
        BoB_Seller__c bs = new BoB_Seller__c(Status__c= 'Inactive', RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        BoB_Seller__c bs1 = new BoB_Seller__c(Status__c= 'Inactive', RecordTypeId = bobSellerRecordTypeLttm.Id,Account_Manager__c=UserInfo.getUserId(),Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        List<BoB_Seller__c> lstBs = new List<BoB_Seller__c>{bs,bs1}; 
        insert lstBs;    
    }
    
    @isTest
    private static void initData(){
        List<BoB_Seller__c> lstBs = [select id from BoB_Seller__c];
        Test.startTest();
            Map<String,Object> funcInitData = ProTraderRegistrationController.initData(lstBs.get(0).Id);
        Test.stopTest();
    }

    @isTest
    private static void getProTraderProgramEligibility(){
        List<BoB_Seller__c> lstBs = [select id,Seller__c from BoB_Seller__c];
        Test.startTest();
            Map<String,Object> funcInitData = ProTraderRegistrationController.getProTraderProgramEligibility(lstBs.get(0).Seller__c);
        Test.stopTest();
    }
}