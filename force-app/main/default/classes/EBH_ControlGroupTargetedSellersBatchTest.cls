/*****************************************************************************************************************************
@ Class:       EBH_ControlGroupTargetedSellersBatch
@ Author:      Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:     US-0008402 test class for EBH_ControlGroupTargetedSellersBatch
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.11.2021 / Mony Nou / Created the method.
@*****************************************************************************************************************************/
@IsTest 
private class EBH_ControlGroupTargetedSellersBatchTest {
    
    @isTest 
    static void test_method() {

        Test.startTest();

            EBH_TestDataFactory.setUpCustomSettings();     
        
            List<Campaign>  listCam = EBH_TestDataFactory.setUpStrategicCampaignData();
            
            EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();
            
            List<EBH_Filter__c> lstFilter = [SELECT Id FROM EBH_Filter__c];
            List<EBH_TargetedSeller__c> lstTS = [SELECT EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c];

            for (EBH_TargetedSeller__c ts : lstTS) ts.EBH_ExitCode__c = '9';
            update lstTS;

            lstTS = [SELECT EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c];

            EBH_ControlGroupTargetedSellersBatch batch = new EBH_ControlGroupTargetedSellersBatch(lstTS[0].EBH_SellerList__c, 100);

            DataBase.executeBatch(batch); 

        Test.stopTest();

        lstTS = [SELECT EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c];
        
        System.assert(lstTS[0].EBH_ExitCode__c == '09', 'The exit code should be "09".');
    }

}