@isTest
private class ProTrader_FollowupControllerTest {
     
    @IsTest
    static void testInit(){
        
        Test.startTest();
        
        String recTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;       
         
        BoB__c bob0 = new BoB__c(Account_Manager__c=UserInfo.getUserId(),Managed_Type__c=ProTrader_HomeController.MANAGED_TYPE_PROTRADER,Status__c=ProTrader_HomeController.STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeLTTM);
        insert bob0;
       
        String soqlWhere = ' Where Id=:bobId ';
        String orderBy = ' order by Name ';
       
        String bobId = bob0.Id;

        Map<String,Object> result = ProTrader_FollowupController.apexInit(bobId,'ProTrader_Followup_TODO',soqlWhere,orderBy);
        List<Object> listHeader = (List<Object>)result.get('listColHeader');
        System.assertNotEquals(0, listHeader.size());

        Test.stopTest();
        
    }
}