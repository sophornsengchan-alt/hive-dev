/*********************************************************************************************************************************
 @ Class:          APObjectiveMeasureTriggerHandlerTest
 @ Version:        1.0
 @ Author:         Davy SORN
 @ Purpose:        Test Class for APObjectiveMeasureTriggerHandler
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.03.2025 / Davy SORN / Created the test class (US-0016888).
 *********************************************************************************************************************************/
@isTest
public class APObjectiveMeasureTriggerHandlerTest {
    
    @testSetup static void makeData() {
        EBH_TestDataFactory.setUpCustomSettings();
        EBH_ActiveTriggers__c cusettingTrigger = EBH_ActiveTriggers__c.getInstance('EBH Trigger Controller');
		cusettingTrigger.AccountPlanObjectiveMeasureTrigger__c = true;
		update cusettingTrigger;

        //Account
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account sellerAccount = new Account(Name='Test Seller Account', RecordTypeId=sellerRecordType.Id);
        insert sellerAccount;

        //AccountPlan
        AccountPlan accPlan = new AccountPlan();
        accPlan.AccountId = sellerAccount.Id;
        accPlan.Name = 'Test Account Plan';
        accPlan.Status = 'Active';
        accPlan.StartDate = Date.today();
        insert accPlan;

        //AccountPlanObjective
        User user = EBH_TestDataFactory.createUser('Standard User Profile');
        AccountPlanObjective accPlanObjective = new AccountPlanObjective();
        accPlanObjective.AccountPlanId = accPlan.Id;
        accPlanObjective.Name = 'Test Account Plan Objective';
        accPlanObjective.StartDate = Date.today();
        accPlanObjective.EndDate = Date.today().addDays(5);
        accPlanObjective.ObjectiveOwnerId = user.Id;
        insert accPlanObjective;

        //AccountPlanObjectiveMeasure
        AccountPlanObjectiveMeasure apom = new AccountPlanObjectiveMeasure();
        apom.AccountPlanObjectiveId = accPlanObjective.Id;
        apom.Name = 'Test Account Plan Objective Measure Number';
        apom.CurrentValue = '10';
        apom.Start_Actual__c = '';
        apom.TargetValue = '100';
        apom.ValueType = 'Number';
        insert apom;
    }

    /*****************************************************************************************************************************
    @ Method:         testInsertAccountPlantObjectiveMeasure
    @ Version:        1.0
    @ Author:         Davy SORN
    @ Purpose:        Test Prepopulate value when creating record
    --------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.03.2025 / Davy SORN / Created testInsertAccountPlantObjectiveMeasure method (US-0016888).
    *****************************************************************************************************************************/  
    @isTest
    static void testInsertAccountPlantObjectiveMeasure() {
        AccountPlanObjectiveMeasure apom = [SELECT CurrentValue, Start_Actual__c FROM AccountPlanObjectiveMeasure WHERE Name = 'Test Account Plan Objective Measure Number' limit 1];
        System.assertEquals(apom.CurrentValue, apom.Start_Actual__c);
    }

    /*****************************************************************************************************************************
    @ Method:         testUpdateAccountPlantObjectiveMeasure
    @ Version:        1.0
    @ Author:         Davy SORN
    @ Purpose:        Test Prepopulate value when updating record
    --------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.03.2025 / Davy SORN / Created testUpdateAccountPlantObjectiveMeasure method (US-0016888).
    *****************************************************************************************************************************/
    @isTest
    static void testUpdateAccountPlantObjectiveMeasure() {
        AccountPlanObjectiveMeasure apom = [SELECT CurrentValue, Start_Actual__c FROM AccountPlanObjectiveMeasure WHERE Name = 'Test Account Plan Objective Measure Number' limit 1];
        apom.CurrentValue = '20';
        apom.Start_Actual__c = '';
        update apom;

        apom = [SELECT CurrentValue, Start_Actual__c FROM AccountPlanObjectiveMeasure WHERE Name = 'Test Account Plan Objective Measure Number' limit 1];
        System.assertEquals(apom.CurrentValue, apom.Start_Actual__c);
    }

}