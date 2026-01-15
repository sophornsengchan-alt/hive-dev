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
private class BoBTriggerHandlerTest {

    @isTest
    static void testSyncFieldsFromBoB2BoBSeller() {
        
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        String bobRecordTypeLTCC = ApexUtil.getRecordTypeByName('BOB__c','Light_Touch_Category_Cohort').Id;
        
         
        BoB__c bob0 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=bobRecordTypeLTCC, Managed_Segment__c = 'Growth Advisor');
        insert bob0;

        RecordType bobSellerRecordTypLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs0 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypLTTM.Id, Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Seller__c=sellers[0].Id,BoB__c = bob0.Id);
        insert bs0;  

        for (BoB_Seller__c bobSeller : [SELECT EBH_BOBSegment__c FROM BoB_Seller__c WHERE Id=:bs0.Id]) {
            System.assertEquals(bobSeller.EBH_BOBSegment__c, bob0.Managed_Segment__c, 'The value should be the same between BoB and BoB Seller.');
        }
        List<BoB_Seller__c> listBobSellers = new List<BoB_Seller__c>();
        for (BoB_Seller__c bobSeller : [SELECT EBH_BOBSegment__c FROM BoB_Seller__c WHERE Id=:bs0.Id]) {
            bobSeller.EBH_BOBSegment__c = null;
            listBobSellers.add(bobSeller);
        }
        update listBobSellers;  

        Test.startTest();

            bob0.Managed_Segment__c = 'Growth Account';
            update bob0;
        Test.stopTest();
        
        for (BoB_Seller__c bobSeller : [SELECT EBH_BOBSegment__c FROM BoB_Seller__c WHERE Id=:bs0.Id]) {
            System.assertEquals(bobSeller.EBH_BOBSegment__c, bob0.Managed_Segment__c, 'The value should be same between BoB and BoB Seller,if bobseller.EBH_BOBSegment__c = null.');
        }


        
            
        
    }
    
    /*static testMethod void testBoBActivation() {
        
        List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        String recTypeOLD = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id;
        Test.startTest();
         
            BoB__c bob0 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeOLD);
            insert bob0;
            RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','Managed');
            
            BoB_Seller__c bs0 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id, Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,Seller__c=sellers[0].Id,BoB__c = bob0.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs0;  
            
            //clone
         	BoB__c bob = new BoB__c(Source_BoB__c = bob0.Id,Status__c=EBH_ConstantsUtility.BOB_STATUS_SUBMITTED, EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeOLD);
            insert bob;
            
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id,Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs;  
            
            bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
            update bob;
        
        Test.stopTest();
            
            BoB__c bobToInActive = [Select Id,Status__c From BoB__c Where Id =:bob0.Id];
            System.assertEquals(EBH_ConstantsUtility.BOB_STATUS_INACTIVE,bobToInActive.Status__c,'other active bob with same vertical and country must go to inactive');
        
    }*/
    /*
    static testMethod void testOwnerChange(){
        Id sellerRecordType=[select id from RecordType where name like '%seller%' and sobjectType='Account'].id;
          List<Account> sellers = EBH_TestDataFactory.createAccounts(20, 'EBH_Seller');
        List<User> lusers=[select id from User where isactive=true and profile.userlicense.name='Salesforce' limit 20];
        Integer i=0;
        
         List<BoB_Seller__c> listBoBSellers = new List<BoB_Seller__c>();
//        BoB__c bob = new BoB__c(Status__c='Draft',BoB_Cohort__c='2018',EBH_BOBCNTRY__c='UK',EBH_BOBVertical__c='Fashion');
        BoB__c bob = new BoB__c(Status__c='Draft',EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion');
            insert bob;
        Account RemovedAccount = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller')[0];
        
            
            
        
        for (Account a : sellers){
            BoB_Seller__c bs = new BoB_Seller__c(Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_SUBMITTED,Seller__c=a.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            bs.Account_Manager__c=lusers[i++].ID;
            if (i>lusers.size())i=0;
            listBobSellers.add(bs);
        }
        BoB_Seller__c bs = new BoB_Seller__c(Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED,Seller__c=removedAccount.Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            listBobSellers.add(bs);
        insert listBobSellers;
        BOB.Status__c=ebh_constantsutility.BOB_STATUS_ACTIVE;
        update bob;
        
         
    }
    */
    static testMethod void testBoBCreationDuplicate() {
        //String recTypeOLD = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id;
        String recTypeLTTMId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE).Id;
        
        Test.startTest();
            /*BoB__c bob0 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeOLD);
            insert bob0;
            
            BoB__c bob1 = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion',RecordtypeId=recTypeOLD);*/
            
            BoB__c bobLTTM0 = new BoB__c(Campaign_Code__c='CMPCODE001',LTTM_Group__c='Test Test',Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Electronics',RecordtypeId=recTypeLTTMId);
            insert bobLTTM0;
            
            BoB__c bobLTTM1 = new BoB__c(Campaign_Code__c='CMPCODE001',LTTM_Group__c='Test Test',Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='77',EBH_BOBVertical__c='Electronics',RecordtypeId=recTypeLTTMId);
            String errMsg = 'Light Touch Category Cohort for same country DE ,vertical Electronics and Campaign Code CMPCODE001 already exists.';
        Test.stopTest();
            
            /*try{
            	insert bob1;
            }catch(Exception ex)
            {
            	System.assert(ex.getMessage().contains(System.Label.ErrorBoBDuplicate),'duplicate with UK and Fashion');
            }*/
            try{
            	insert bobLTTM1;
            }catch(Exception ex)
            {
            	System.assert(ex.getMessage().contains(errMsg),'Light Touch Category Cohort for same country DE ,vertical Electronics and Campaign Code CMPCODE001 already exists.');
            }
    }
    static testMethod void testvalidationLLTMbobBeforeActivated() {
    	RecordType bobRecordTypeLTTM = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_LTTM_RECORDTYPE);
    	RecordType bobSellerRecordTypeLTTM = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
    	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
    	BoB__c bob = new BoB__c(RecordTypeId = bobRecordTypeLTTM.Id ,Name='Bob 1');
        insert bob;
        BOB_Seller__c bobSeller = new BOB_Seller__c(RecordTypeId = bobSellerRecordTypeLTTM.Id ,BOB__c=bob.Id, Seller__c=sellers[0].Id);
        insert bobSeller;
    	Test.startTest();
    	try{
    		bob.Status__c = EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
    		update bob;
    	}catch(Exception ex){
    	System.assert(ex.getMessage().contains(System.Label.error_before_activate),'Please click "Category Selection" to select the category and click "Create Actions" to create recommended Actions for the sellers before activating the cohort');
    	}
    	
        Test.stopTest();
        
    }
}