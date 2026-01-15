/*********************************************************************************************************************************
@ Class:          EBH_TargetingCockpitControllerTest
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        Test class for EBH_TargetingCockpitController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.05.2017 / JOY MONDOL / Created the test class.
@               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_TargetingCockpitControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { testCreateSnapshot(); }        
    }
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Business Admin')) { testCreateSnapshot(); }
    }
    
    /*****************************************************************************************************************************
    @ Method:         testCreateSnapshot
    @ Version:        1.0
    @ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
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
    @ Change history: 05.05.2017 / JOY MONDOL / Created the test Method.
    @               : 10/05/2024/ vadhanak voun/ US-0015118 - 4. Deletion of custom objects
    *****************************************************************************************************************************/
    static testMethod void testCreateSnapshot() {
                    
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
        EBH_TestDataFactory.setUpCustomSettings();     
        List<EBH_TargetedSeller__c> testDataMap = EBH_TestDataFactory.setUpTargetedSellerTriggerHandlerData();     
       /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

       // Test.startTest();
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            /*Modify data for test*/             
            EBH_Filter__c filter =  [SELECT id, owner.email from EBH_Filter__c LIMIT 1][0];
            RecordType recCamp = ApexUtil.getRecordTypeByName('Campaign','EBH_Campaign');
            Campaign camp0 = new  Campaign(Name='Camp0',EBH_SellerList__c =filter.Id, RecordTypeId=recCamp.Id,Status='Completed');
            insert camp0;

            EBH_TargetingCockpitController2 tController  = new EBH_TargetingCockpitController2(new ApexPages.standardController( filter ));
            ApexPages.currentPage().getParameters().put('Id' , filter.id);
          
            EBH_TargetingCockpitController2.fetchOptions('Account','Name');
          
            EBH_TargetingCockpitController2.fetchHelpText('Name','Account');

            EBH_TargetingCockpitController2.fetchSellers('SELECT owner.Email, id from Account');
            EBH_TargetingCockpitController2.fetchFilter(filter.id);
            Test.startTest();
            EBH_TargetingCockpitController2.updateFilter(filter.Id, 'SELECT COUNT() FROM Account');//'Name=%a%');
            tController.cloneFilter();

            EBH_TargetingCockpitController2.fetchAccountFieldValues('SELECT owner.Email, name from account', 'name', 'Account');

            EBH_Action__c ac1 = new EBH_Action__c(EBH_ActionID__c='11223344556677');
            insert ac1;
            EBH_NBA__c nba1  = new EBH_NBA__c(EBH_ActionID__c=ac1.Id);
            insert nba1;
            
         

            EBH_TargetingCockpitController2.fetchAccountFieldValues('SELECT owner.Email, name From EBH_NBA__c', 'name', 'EBH_NBA__C');
            EBH_TargetingCockpitController2.fetchAccountFieldValues('SELECT owner.Email, name,(Select Id,Name from EBH_NBAs__r limit 1) From EBH_Action__c', 'name', 'EBH_Action__c');
            
            EBH_TargetingCockpitController2.fetchAccountFieldValues('SELECT Id,LastName From Contact', 'LastName', 'Contact');

            try{
	            EBH_TargetingCockpitController2.generateTargetedSellers(filter.Id, 'SELECT Id from Account');
	            
	            //EBH_TargetingCockpitController2.fetchSellersCount(' SELECT id, owner.Email from EBH_Filter__c ');
	            EBH_TargetingCockpitController2.fetchSellersCount(' SELECT count() from EBH_Filter__c ');
	            
	            Account a1 = new Account(Id=testDataMap[0].EBH_Seller__c);
	            a1.Marketing_Blacklist__c = true;
	            
	            update a1;
	             
	            Map<String,Object> mapResult = EBH_TargetingCockpitController2.fetchSellersCount3(filter.Id+'','  SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = \'EBH_Seller\' ','');
	            
	            Map<String,String> mapResult2 =  EBH_TargetingCockpitController2.fetchSellersNotAvailable(filter.Id+'','  SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = \'EBH_Seller\' ','');
	            
	            System.assertEquals('1',mapResult.get('sellerBlacklist'),'1 blacklist');
	            System.assertEquals('2',mapResult2.get('numSellerNotAvailable'),'2 seller Not Available');
	            
	            Map<String,String> mapResult3 =  EBH_TargetingCockpitController2.fetchNumContactAvailable(filter.Id+'','  SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = \'EBH_Seller\' ','');
	            System.assertEquals('4',mapResult3.get('numContactAvailable'),'4  Contacts Email Opt-Out');
	             
	            //NK:06/06/2018----
	            Map<String,String> mapResult4 =  EBH_TargetingCockpitController2.fetchNumSellerPhoneOptOut(filter.Id+'','  SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = \'EBH_Seller\' ','');
	             
	            Map<String,String> mapResult5 =  EBH_TargetingCockpitController2.fetchNumContactPhoneOptOut(filter.Id+'','  SELECT COUNT() FROM Account WHERE RecordType.DeveloperName = \'EBH_Seller\' ','');
	            //---------------
	             
	            
                RecordType recSeller = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
                Account acc2 = new Account(Name='test 1234223483738 938ss ', RecordTypeId=recSeller.Id);
                insert acc2;
                                
                EBH_TargetingCockpitController2.fetchAccountFieldValues('SELECT Id From EBH_Action__c', 'Id', 'EBH_Action__c');
                              
            }
            catch(Exception e){system.debug('error: '+e+'\n'+e.getStackTraceString());
            }
            
            filter.EBH_TE_Expiration_Date__c =  System.Today().addYears(3);
            EBH_TargetingCockpitController2.validateTE(8600,filter);
            

            filter.EBH_TE_Expiration_Date__c =  System.Today().addYears(1).addMonths(2);
            EBH_TargetingCockpitController2.validateTE(51000,filter);

            filter.EBH_TE_Expiration_Date__c =  System.Today().addMonths(7);
            EBH_TargetingCockpitController2.validateTE(110000,filter);

            filter.EBH_TE_Expiration_Date__c =  System.Today().addMonths(1);            
            EBH_TargetingCockpitController2.validateTE(310000,filter);
            
            filter.EBH_TE_Expiration_Date__c =  System.Today().addYears(1).addMonths(2);
            update filter;
            EBH_TargetingCockpitController2.updateFilter(filter.Id, 'SELECT COUNT() FROM Account');
            

            
        Test.stopTest();
    }
    
}