/*********************************************************************************************************************************
@ Class:         BatchTargetingEngineDeletionTest
@ Version:       1.0
@ Author:        Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       Test class for: BatchTargetingEngineDeletion
@				 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.01.2019 / Vadhanak Voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
@isTest
private class BatchTargetingEngineDeletionTest {

    // static testMethod void testDeleteTE_batch() {
    //     RecordType te_Manual = ApexUtil.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
    //     EBH_Filter__c te_m1 = new EBH_Filter__c(Name='TE1',EBH_TE_Expiration_Date__c=System.Today().addDays(5),RecordtypeId=te_Manual.Id);
    //     EBH_Filter__c te_m2 = new EBH_Filter__c(Name='TE2',EBH_TE_Expiration_Date__c=System.Today().addDays(5),RecordtypeId=te_Manual.Id);
    //     EBH_Filter__c te_m3 = new EBH_Filter__c(Name='TE3',EBH_TE_Expiration_Date__c=System.Today().addDays(-2),RecordtypeId=te_Manual.Id);
        
    //     insert new List<EBH_Filter__c>{te_m1,te_m2,te_m3};
        
    //     Test.startTest();
    //     	BatchTargetingEngineDeletion bTE = new BatchTargetingEngineDeletion();
    //     	bTE.execute(null);
    //     Test.stopTest();
        
    //     List<EBH_Filter__c> listTESel = [Select Id From EBH_Filter__c];
    //     System.assertEquals(2,listTESel.size(),'1 expired date already deleted. 2 remains in the system.');
        
    // }

    @isTest
    static void testDeleteTE_batch() {
        // 17.03.2023 / Sophal Noch / US-0011770 :
        
        RecordType te_Manual = ApexUtil.getRecordTypeByName('EBH_Filter__c','EBH_ManualSellerList');
        EBH_Filter__c te1 = new EBH_Filter__c(Name='TE1',EBH_TE_Expiration_Date__c=System.Today().addDays(5),RecordtypeId=te_Manual.Id);
        EBH_Filter__c te2 = new EBH_Filter__c(Name='TE2',EBH_TE_Expiration_Date__c=System.Today().addDays(5),RecordtypeId=te_Manual.Id);
        EBH_Filter__c te3 = new EBH_Filter__c(Name='TE3',EBH_TE_Expiration_Date__c=System.Today().addDays(-2),RecordtypeId=te_Manual.Id);
        
        insert new List<EBH_Filter__c>{te1,te2,te3};

        Account acc1 = new Account( Name = 'TestAccount1');
        Account acc2 = new Account( Name = 'TestAccount2');
        Account acc3 = new Account( Name = 'TestAccount3');
        insert new List<Account>{acc1,acc2,acc3};

        EBH_TargetedSeller__c te1_ts1 = new EBH_TargetedSeller__c(EBH_SellerList__c = te1.Id, EBH_Seller__c	 = acc1.Id);
        EBH_TargetedSeller__c te2_ts1 = new EBH_TargetedSeller__c(EBH_SellerList__c = te2.Id, EBH_Seller__c	 = acc2.Id);
        EBH_TargetedSeller__c te3_ts1 = new EBH_TargetedSeller__c(EBH_SellerList__c = te3.Id, EBH_Seller__c	 = acc3.Id);

        insert new List<EBH_TargetedSeller__c>{te1_ts1,te2_ts1,te3_ts1};
        
        Test.startTest();
            BatchTargetingEngineDeletion bTE = new BatchTargetingEngineDeletion();
            bTE.execute(null);
        Test.stopTest();

        List<EBH_TargetedSeller__c> listTS = [Select Id From EBH_TargetedSeller__c];
        System.assertEquals(2,listTS.size(),'1 expired date already deleted. 2 remains in the system.');

        List<EBH_Filter__c> listTE = [Select Id From EBH_Filter__c];
        System.assertEquals(2,listTE.size(),'1 expired date already deleted. 2 remains in the system.');
        
    }

}