@isTest
private class RelatedRecordsControllerTest {
     
    @IsTest
    static void testInit()
    {
      
        Test.startTest();
        String recTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;       
         
        BoB__c bob0 = new BoB__c(Account_Manager__c=UserInfo.getUserId(),Managed_Type__c=ProTrader_HomeController.MANAGED_TYPE_PROTRADER,Status__c=ProTrader_HomeController.STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeLTTM);
        insert bob0;

        String soql = 'Select Name from BOB__c ';
        String soqlWhere = ' Where Id=:recordId ';
        String orderBy = ' order by Name ';
        String sobjectName = 'BOB__c';
        String recordId = bob0.Id;

        
            Map<String,Object> result = RelatedRecordsController.apexInit(soql, soqlWhere, recordId, orderBy, sobjectName);
            List<SObject> listRows = (List<SObject>)result.get('listRows');
            System.assertEquals(1, listRows.size());
        Test.stopTest();
        
    }
}