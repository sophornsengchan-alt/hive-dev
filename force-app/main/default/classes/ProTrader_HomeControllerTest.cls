@isTest
private class ProTrader_HomeControllerTest {
     
    @IsTest
    static void testApexInitHome(){
        
         
        String recTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;
         
         
        BoB__c bob0 = new BoB__c(Account_Manager__c=UserInfo.getUserId(),Managed_Type__c=ProTrader_HomeController.MANAGED_TYPE_PROTRADER,Status__c=ProTrader_HomeController.STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeLTTM);
        insert bob0;
         
        Test.startTest();
        Map<String,Object>  result = ProTrader_HomeController.apexInit(' WHERE Id=\''+bob0.Id+'\'',' ORDER By Name');
        List<SObject> listBob = (List<SObject>)result.get('listBob');
        System.assertEquals(1, listBob.size());

        result =  ProTrader_HomeController.apexInitActionList(bob0.Id);


        result = ProTrader_HomeController.apexSaveActionList(new List<SObject>{bob0});

        result = ProTrader_HomeController.apexDeleteActionList(new List<SObject>{bob0});

        //Error delete
        result = ProTrader_HomeController.apexDeleteActionList(new List<SObject>{new BoB__c(Account_Manager__c=UserInfo.getUserId(),Managed_Type__c=ProTrader_HomeController.MANAGED_TYPE_PROTRADER,Status__c=ProTrader_HomeController.STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeLTTM)});

        Test.stopTest();
        
    }


}