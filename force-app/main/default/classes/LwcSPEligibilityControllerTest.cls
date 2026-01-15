/*********************************************************************************************************************************
@ Class:          LwcSPEligibilityControllerTest
@ Author:         Chetra Sarom (chetra.sarom@gaea-sys.com)
@ Purpose:        US-0012308 - Can't give sellers access to seller portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.08.2022 / Chetra Sarom / Created the method.
*********************************************************************************************************************************/
@isTest
public with sharing class LwcSPEligibilityControllerTest {
    static testMethod void getSPEligibility(){
        User admUsers = [Select Id,Name From User where Profile.Name='System Administrator' and IsActive=true Limit 1];
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        Account portalAccount;
        System.runAs(admUsers){
            portalAccount = new Account(
                    Name = 'AMT_TEST',
                    eBay_API_User_Id__c = 'test_test_test',
                    RecordTypeId = recSeller.Id,
                    SP_Deals__c = 'Full Access'
            );
            insert portalAccount;
        	Test.startTest();
            Map<String,Object> mapResult = LwcSPEligibilityController.getSPEligibility(portalAccount.Id);
            System.assert(mapResult != null && !mapResult.isEmpty(), ' Results return Admin profile type Boolean and Permission for Coupons and Deals type Boolean.');
        	Test.stopTest();
        }
    }
}