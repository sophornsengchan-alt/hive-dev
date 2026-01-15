@isTest
public class changeDealOwnerTest {
    
    @testSetup static void testSetup() {
        Profile objProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' Limit 1];  
        User objUser = new User(Alias = 'JNgom1', 
                                Email = 'jacques.ngom-lea@maxappsltd.co.uk', 
                                EmailEncodingKey = 'UTF-8', 
                                LastName = 'Ngom-Lea',
                                LocaleSidKey = 'en_US', 
                                LanguageLocaleKey='en_US', 
                                ProfileId = objProfile.Id, 
                                TimeZoneSidKey = 'Europe/London', 
                                UserName = 'jngom@hive.project.com.jacquesdev');
        insert objUser;
        Account a = new Account(Name='TestDeal');
        a.recordtypeId =[SELECT id from recordType where sobjectType ='Account' and developerName ='EBH_Seller'].Id;
        insert a;
        EBH_Deal__c d=new EBH_Deal__c(EBH_DealPrice__c=10);
        d.EBH_BusinessName__c =a.id;
        d.OwnerId =objUser.Id;
        insert d;
            /*EBH_BusinessName__c ='DN_000001880',
            EBH_SellerPrice__c=40,EBH_DealPrice__c=5,EBH_SoldItems__c=2,EBH_Vertical__c='Tech',EBH_DealFormat__c='Primary',EBH_Category__c='Gold', EBH_ProductTitle__c='product 1',EBH_SellerEmail__c='sales@test.com',EBH_Quantity__c=1,
                        OwnerId =objUser.Id);*/       
    }
    
    private static testMethod void changeDealOwnerTestMethod() {
        Test.startTest(); 
        List<EBH_Deal__c> lstDeal = [SELECT OwnerId FROM EBH_Deal__c Limit 1];
        List<User> lstUser = [SELECT Id FROM User WHERE LastName = 'Ngom-Lea'];
        Test.setCurrentPage(Page.changeDealOwner);
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(lstDeal);
        stdSetController.setSelected(lstDeal);
        changeDealOwner objCLO = new changeDealOwner(stdSetController);
        objCLO.cancelAction();
        objCLO.objDeal = new EBH_Deal__c(OwnerId = lstUser[0].Id); 
        objCLO.updateDealOwnerAction();
        Test.stopTest();
    }
}