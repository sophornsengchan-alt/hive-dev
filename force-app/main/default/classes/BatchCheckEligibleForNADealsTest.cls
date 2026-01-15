@isTest
private class BatchCheckEligibleForNADealsTest {
    @testSetup private static void setup() {
        Account acc1 = new Account( Name = 'TestAccount1', EBH_OracleID__c = '12345678912', NA_Seller_Portal_Eligible__c = true, EBH_RevRollup__c = 'CA', EBH_PredictedStandard__c = 'ETRS', EBH_PositiveFeedback__c = 98, EBH_VeROViolation__c = false, EBH_LastSellDate__c = (System.today()+100), EBH_FeedbackScore__c = 3000, EBH_StoreSubscription__c = 'Anchor', EBH_ActualStandard__c = 'Above Standard',EBH_GMVLast12Months__c = 70000);//NA Seller Portal Eligible = true, and Meet condition
    	Account acc2 = new Account( Name = 'TestAccount2', EBH_OracleID__c = '12345678913', NA_Seller_Portal_Eligible__c = false, EBH_RevRollup__c = 'CA', EBH_PredictedStandard__c = 'ETRS', EBH_PositiveFeedback__c = 98, EBH_VeROViolation__c = false, EBH_LastSellDate__c = (System.today()+100), EBH_FeedbackScore__c = 3000, EBH_StoreSubscription__c = 'Anchor', EBH_ActualStandard__c = 'Above Standard',EBH_GMVLast12Months__c = 70000);// NA Seller Portal Eligible = false, and Meet condition
        Account acc3 = new Account( Name = 'TestAccount3', EBH_OracleID__c = '12345678914', NA_Seller_Portal_Eligible__c = true, EBH_RevRollup__c = 'DE', EBH_PredictedStandard__c = 'ETRS', EBH_PositiveFeedback__c = 97, EBH_VeROViolation__c = true, EBH_LastSellDate__c = (System.today()+80), EBH_FeedbackScore__c = 3000, EBH_StoreSubscription__c = 'Anchor', EBH_ActualStandard__c = 'Above Standard',EBH_GMVLast12Months__c = 70000);// NA Seller Portal Eligible = true, and not Meet condition
        insert new List<Account>{acc1,acc2,acc3};
    }
    
    @isTest private static void testBatchCheckEligibleForNADeals() {
        Test.startTest();
            BatchCheckEligibleForNADeals bCheckEligible = new BatchCheckEligibleForNADeals();
            Database.executeBatch(bCheckEligible);
        Test.stopTest();
        Map<String,Boolean> mapAcc = new Map<String,Boolean>();
        for(Account acc : [select EBH_OracleID__c, NA_Seller_Portal_Eligible__c from Account]){
            mapAcc.put(acc.EBH_OracleID__c, acc.NA_Seller_Portal_Eligible__c);
        }
        System.assertEquals(true, mapAcc.get('12345678912'));
        System.assertEquals(true, mapAcc.get('12345678913'));
        System.assertEquals(false, mapAcc.get('12345678914'));
    }
}