/*********************************************************************************************************************************
@ Class:        ContractCategoryControllerTest
@ Version:      1.0
@ Author:       Sambath Seng
@ Purpose:      US-0015241 - Create new Contract Category object
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 30.05.2024 / Sambath Seng / Clone from CouponCategoryController
*********************************************************************************************************************************/
@isTest
private class ContractCategoryControllerTest {
    static testMethod void testCategorySelectionAndSave() {

        RecordType sellerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        RecordType contractRecordType = ApexUtil.getRecordTypeByName('Contract','VIP_Contracts');
         
        List<Account> legalEntity = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');

        RecordType manaulconRt = EBH_TestDataFactory.getRecordTypeByName('Contact','EBH_MANUAL');
        Contact contact = new Contact(EBH_Status__c='Active', LastName = 'testLastName', FirstName = 'testFirstName',Email='Test@test.com', AccountId = legalEntity[0].Id,recordTypeId = manaulconRt.Id, EBH_DataOrigin__c='test');             
        insert contact;

        Date startDate = System.today();
        Date endDate = System.today().addDays(31);

        Contract contr = new Contract(RecordTypeId = contractRecordType.Id, 
                                       Name = 'Test Contract 1', 
                                       accountId = legalEntity[0].id, 
                                       EBH_eBayLegalEntity__c = legalEntity[1].id,
                                       EBH_Site__c = 'DE',
                                       Status = 'Draft',
                                       StartDate = startDate,
                                       EndDate = endDate,
                                       Surcharge__c = true,
                                       Business_Contact__c = contact.id);

        insert contr;
        
     	Category_Tree__c ct0 = new Category_Tree__c(Name = 'l0',Active__c=true,Site__c='77', Level__c = 0);
     	insert ct0;
    	Category_Tree__c ct1 = new Category_Tree__c(Name = 'l1',Note_ID__c=ct0.Id,Active__c=true, Site__c='77',  Level__c = 1);
    	insert ct1;
		Category_Tree__c ct2 = new Category_Tree__c(Name = 'l2',Note_ID__c = ct1.Id,Active__c=true, Site__c='77',  Level__c = 2);
		insert ct2;
		Category_Tree__c ct3 = new Category_Tree__c(Name = 'l3',Note_ID__c = ct2.Id,Active__c=true, Site__c='77',  Level__c = 3);
    	insert ct3;
         	
        Test.startTest();
        	
            Map<String,Object> result = ContractCategoryController.apexQueryCat(null,contr.Id,null, null); // test init
            System.assertEquals(1,((List<Object>)result.get('listResult')).size());

            result = ContractCategoryController.apexQueryCat('77',contr.Id ,ct2.Id, null ); // test selected level 2
            System.assertEquals(1,((List<Object>)result.get('listResult')).size());

            // test save level 3
            List<Contract_Category__c> listContractCat = new List<Contract_Category__c>{new Contract_Category__c(Category__c = ct3.Id, Contract__c = contr.Id)};

         	Map<String,Object> resultSave = ContractCategoryController.apexSaveCat(listContractCat);
         	System.assertEquals('ok',resultSave.get('status'),'save success');
         	

        Test.stopTest();
        
    }
}