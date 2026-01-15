/*********************************************************************************************************************************
@ Class:          EBH_CSVUploaderControllerTest
@ Version:        1.0
@ Author:         NEHA LUND (nalund@deloitte.co.uk)
@ Purpose:        Test class for EBH_AccountTriggerHandler class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 17.07.2017 / NEHA LUND / Created the test class.
@ Change history:  14.12.2023 / Vimean Heng / Fix lock row.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_CSVUploaderControllerTest{
    private static User currentUser = [ select Id, Name from User where Id = :UserInfo.getUserId() ];
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    @ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row. currentUser is admin
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        //System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testUpdateCustomRollUp(); }  
        System.runAs(currentUser) { testUpdateCustomRollUp(); }          
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    @ Change history:  14.12.2023 / Vimean Heng / US-0014423 / Fix lock row.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        //ignore flow assign role by create chatter free user
        User su = EBH_TestDataFactory.createUser('Chatter Free User');
		User stu = EBH_TestDataFactory.createUser('Standard User');
		insert su;
		su.ProfileId = stu.ProfileId;
		update su;
        System.runAs(su) { testUpdateCustomRollUp(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testUpdateCustomRollUp
    @ Version:        1.0
    @ Author:         NEHA LUND (nalund@deloitte.co.uk)
    @ Purpose:        TEST CASE (*) System should be able to rollup the following fields in sellers to its legal entity 
                                    (which is a one to many relationship of one level of depth) 
                                    on insert and update and reparenting:
                                     - GMV
                                     - Revenue 
                                     - Sold Items
                      COVERAGES (*) updateCustomRollUp(): Updates custom roll ups on legal entity from child sellers 
                                        |___hasRollupChanged(): Checks field change in seller
                                        |___hasParentChanged(): Checks parent change in seller
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.07.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testUpdateCustomRollUp() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();     
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            Id sellerID = [SELECT id from Account limit 1].ID;
            EBH_CSVUploaderController controllerInstance = new EBH_CSVUploaderController (null);
            
            /*Excecute test*/
            EBH_CSVUploaderController.fetchSellers(new String[]{'12334'});
            EBH_CSVUploaderController.createTargetedSellers(new String[]{sellerID}, 
                                                            [SELECT id from EBH_Filter__c limit 1].Id);
            /*Validate test*/
            System.assertEquals( 2, [SELECT id from EBH_TargetedSeller__C ].size());
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            
            /*Excecute test*/
            RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            Account acc1 = new Account(Name='Test Abc123',RecordTypeID = sellerRecordType.Id);
            Account acc2 = new Account(Name='Test Abc',RecordTypeID = sellerRecordType.Id);
            List<Account> sellers = new List<Account>{acc1,acc2};
            Insert sellers;
            //List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
            EBH_CSVUploaderController.fetchSellers(new String[]{sellerID,'3e'});

            // EBH_CSVUploaderController.createTargetedSellers2(new String[]{sellerID,sellers[0].Id,sellers[1].Id}, [SELECT id from EBH_Filter__c limit 1].Id,JSON.serialize(new Map<String,String>{sellerID=>'2'}));
            // 20.05.2022 / Sophal Noch / US-0011717
            EBH_CSVUploaderController.createTargetedSellers2(new String[]{sellerID,sellers[0].Id,sellers[1].Id}, [SELECT id from EBH_Filter__c limit 1].Id,JSON.serialize(new Map<String, EBH_TargetedSeller__c>{sellerID=>new EBH_TargetedSeller__c(Priority__c = 2, Campaign_Related_Seller_Details__c = 'test details' )}));

            /*Validate test*/
            System.assertEquals( 4, [SELECT id from EBH_TargetedSeller__C].size()); //3 insert, 2 New:OK, 1:duplicate: total all existing 2+2:4
            
             Map<String, String> mapResult  = EBH_CSVUploaderController.createAttachment('id,name',sellerID);
            
            PageReference myPage = Page.EBH_CSVUploader;
            myPage.getParameters().put('attId',mapResult.get('attId'));
            Test.setCurrentPage(myPage);
            
            controllerInstance = new EBH_CSVUploaderController (null);
            
            controllerInstance.deleteAttachment();
            
            /*Validate test*/
             /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            /*Modify data for test*/             
           
            /*Excecute test*/
           
            
            /*Validate test*/
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}