@isTest
private   class WithoutSharingTest {
     
    @IsTest
    static void testAllmethods(){
        Account acc = new Account( Name = 'TestAccount11111', EBH_StoreSubscription__c = 'Anchor');
        Account acc2 = new Account( Name = 'TestAccount222222', EBH_StoreSubscription__c = 'Anchor');
        Test.startTest();
            WithoutSharing.doInsert(new Account[]{acc});
            WithoutSharing.doInsert(new Account[]{acc},false);
            WithoutSharing.doUpdate(new Account[]{acc});
            WithoutSharing.doUpsert(new Account[]{acc});
            WithoutSharing.doUpdate(new Account[]{acc},true);
            WithoutSharing.doDelete(new Account[]{acc});
            WithoutSharing.doQuery('Select Id,Name From Account ', ' WHERE Name=\'TestAccount11111\'', ' Limit 1');
            
            try {
                WithoutSharing.doUpsert(new List<FMRS__c>{new FMRS__c()});
            }catch(Exception ex){}
            try {
                WithoutSharing.doUpsert(new List<Revenue_Schedules_Monthly__c>{new Revenue_Schedules_Monthly__c()});
            }catch(Exception ex){}
            try {
                WithoutSharing.doUpsert(new List<FDRS__c>{new FDRS__c()});
            }catch(Exception ex){}
            try {
                WithoutSharing.doUpsert(new List<RS_Daily__c>{new RS_Daily__c()});
            }catch(Exception ex){}
            try { // 25.09.2023 / Sophal Noch / US-0014118
                WithoutSharing.doUpsert(new List<BoB_Seller__c>{new BoB_Seller__c()}, Schema.getGlobalDescribe().get('BoB_Seller__c').getDescribe().fields.getMap().get('Unique_Id__c'), false);
            }catch(Exception ex){}
          

        Test.stopTest();
        
    }
}