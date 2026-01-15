/*********************************************************************************************************************************
@ Class:          EBH_ContractApprovalControllerTest
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Test class for EBH_ContractApprovalController class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2017 / NEHA LUND / Created the test class.
*********************************************************************************************************************************/

@isTest(seeAllData = False)
public class EBH_ContractApprovalControllerTest {
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SA
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for System Administrator
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    /*static testMethod void testProfile_SA() {       
        System.runAs(EBH_TestDataFactory.createUser('System Administrator')) { setupData();testSubmitForApproval(); }        
    }*/
    
    /*****************************************************************************************************************************
    @ Method:         testProfile_SU
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        Profile testing for Standard User
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    /*static testMethod void testProfile_SU() {
        System.runAs(EBH_TestDataFactory.createUser('Standard User Profile')) { setupData();testSubmitForApproval(); }
    }*/
    
    static testmethod void setupData(){
        //EBH_TestDataFactory.setUpCustomSettings();   
        ActiveValidationRules__c avr = new ActiveValidationRules__c();
		avr.All_Validation_Rules_Deactivated__c = true;
		insert avr;
    }

    /*****************************************************************************************************************************
    @ Method:         testSubmitForApproval
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        TEST CASE (*) System should be able to automatically submit the Campaign request for an approval
                                    For every site- we have dedicated group of users to approve the request and covert it into
                                    Campaign
                      COVERAGES (*) testSubmitForApproval(): 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 29.05.2017 / NEHA LUND / Created the test Method.
    *****************************************************************************************************************************/
    static testMethod void testSubmitForApproval() {
        setupData();           
        /*TEST DATA ------------------------------------------------------------------------------------------ BEGIN -----------*/
      
        EBH_TestDataFactory.setUpCustomSettings();   
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(2, 'EBH_LegalEntity');
        LegalEntities[0].EBH_BillingCountry__c = 'CA';
        update legalEntities;
        List<Contract> contracts = EBH_TestDataFactory.createContracts (3, 'Listing Agreement', 
                                                                        LegalEntities[0].id, LegalEntities[1].id);

        for (Contract con : contracts) {
            con.PricingVersion__c = 'P1.0';
            con.EBH_FinanceAgreesinPrincipal__c = false;
            con.EBH_FinancePostCheckDone__c = false;
        }

        update contracts;
        
        /*TEST DATA ------------------------------------------------------------------------------------------ END -------------*/

        Test.startTest();

            byPass__c settings = byPass__c.getOrgDefaults();
            settings.ByPass_Validation__c = true;
            upsert settings byPass__c.Id;
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            List<EBH_Pricing__c> pricings = EBH_TestDataFactory.createPricing (10, 'EBH_ListingPricing', 
                                                    contracts[0].id, 15, 900.00, 800.00, 2000000, 800, 'UK');

            /*Modify data for test*/             
            contracts[0].Status = 'Sent for Finance Pre-check';
            update contracts[0];
            EBH_ContractApprovalController.validateBUApprover( contracts[0].id );
            System.assertEquals( Label.EBH_RecordInApprovalProcess ,EBH_ContractApprovalController.validateBUApprover( contracts[0].id ));
            

            contracts[0].EBH_BUApprover__c =UserInfo.getUSerID();
            contracts[0].EBH_FinanceAgreesinPrincipal__c = true;
            contracts[0].Status = EBH_ConstantsUtility.CONTRACT_PENDINGSTATUS;
            contracts[0].StartDate = Date.today();
            //update contracts[0];
           	EBH_ContractApprovalController.validateBUApprover( contracts[0].id );
            //System.assertEquals( Label.EBH_RecordInApprovalProcess ,EBH_ContractApprovalController.validateBUApprover( contracts[0].id ));
           
            /*Excecute test*/
            contracts[1].EBH_BUApprover__c = null;
            contracts[1].EBH_FinanceAgreesinPrincipal__c = true;
            contracts[1].ebh_contractvalue__c = 600000;
            contracts[1].Status = 'Approved';
            try{
                update contracts[1];
            } catch(Exception e){
                System.assert(e.getMessage().length() > 0);
            }
           
            /*Validate test*/
            // System.assertEquals( Label.EBH_BUApproverValidationMessage,EBH_ContractApprovalController.validateBUApprover( contracts[1].id ));        
            
            /*NEGETIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            /*POSITIVE TESTING ------------------------------------------------------------------------------- BEGIN -----------*/
            contracts[0].Status = EBH_ConstantsUtility.CONTRACT_NEGOTIATIONSTATUS;
            try{
                update contracts[0];
            } catch(Exception e){
                System.assert(e.getMessage().length() > 0);
            }
            /*Execute & Validate test*/
            //System.assertEquals(2, contracts.size());
            //System.assertEquals( '' ,EBH_ContractApprovalController.validateBUApprover( contracts[0].id ));
            
           // EBH_ContractApprovalController.submitApprovalRequest( contracts[0].id, 'Submit comments');
          
             
            
            /*POSITIVE TESTING ------------------------------------------------------------------------------- END -------------*/
            
            
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ BEGIN -----------*/
            
            /*Excecute test*/
            EBH_ContractApprovalController.submitApprovalRequest( null, 'Submit comments');
			EBH_ContractApprovalController.validateBUApprover( contracts[0].id );
			
        	
            /*Validate test*/
           	System.assertEquals( 1, [SELECT id from EBH_ApexLog__c].size() );
            /*EXCEPTION TESTING ------------------------------------------------------------------------------ END -------------*/
        Test.stopTest();
    }
}