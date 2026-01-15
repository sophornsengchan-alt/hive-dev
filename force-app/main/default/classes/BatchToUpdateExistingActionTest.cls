/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest
private class BatchToUpdateExistingActionTest {
	static testmethod void test() {
        
        User[] admins = [Select Id From User WHERE Profile.Name ='System Administrator' AND IsActive=TRUE LIMIT 1];
        
        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        
        Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id);
        insert acc1;    
        
        User stdUsr;

        System.runAs(admins[0])
        {

            stdUsr = EBH_TestDataFactory.createUser('Standard User Profile');
            stdUsr.FirstName = 'Test';
            Insert stdUsr;

        }
        
        Id recTypeLTTMId = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;
        BoB__c bobLTTM0 = new BoB__c(Campaign_Code__c='CMPCODE001',LTTM_Group__c='Test Test',Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Electronics',RecordtypeId=recTypeLTTMId);
        insert bobLTTM0;

        BoB_Seller__c bobSel = new BoB_Seller__c(BoB__c =bobLTTM0.Id, Seller__c = acc1.Id,Account_Manager__c=stdUsr.Id,Parent_Seller__c=acc1.Id,BoB_Subsegment__c='Focus');
        insert bobSel;
        
        Action__c act = new Action__c(Name='Test1',LTTM_Seller__c=bobSel.Id);
        insert act;
        
        Test.startTest();
            BatchToUpdateExistingAction c = new BatchToUpdateExistingAction();
            Database.executeBatch(c);
        Test.stopTest();
        
        // Verify Action updated
        Action__c actUpdatedList = [SELECT Id,Managed_Seller__c FROM Action__c];
        System.assertEquals(bobSel.Seller__c, actUpdatedList.Managed_Seller__c);
    }
}