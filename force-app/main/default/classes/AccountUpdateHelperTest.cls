/*********************************************************************************************************************************
@ Class:          AccountUpdateHelperTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.01.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private class AccountUpdateHelperTest {

    /*********************************************************************************************************************************
    @ Method:         unlinkParentLegalEntity
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.01.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @isTest
    private static void unlinkParentLegalEntity() {

        List<ActiveValidationRules__c> listRule = [Select Id, All_Validation_Rules_Deactivated__c From ActiveValidationRules__c Where SetupOwnerId = :UserInfo.getUserId() Limit 1];
        ActiveValidationRules__c bp = new ActiveValidationRules__c(SetupOwnerId = UserInfo.getUserId(), All_Validation_Rules_Deactivated__c = false);
        if(listRule.isEmpty()){
            insert bp;
        }else{
            bp.All_Validation_Rules_Deactivated__c = listRule[0].All_Validation_Rules_Deactivated__c;
            bp.Id = listRule[0].Id;
        }
        

        List<Account> sellers = EBH_TestDataFactory.createAccounts(1, 'EBH_Seller');
        List<Account> legalEntities = EBH_TestDataFactory.createAccounts(1, 'EBH_LegalEntity') ;

        sellers[0].ParentId = legalEntities[0].Id;
        update sellers;

        AccountUpdateHelper.unlinkParentLegalEntity(sellers[0].Id);
        
        System.assertEquals(bp.All_Validation_Rules_Deactivated__c, [Select Id, All_Validation_Rules_Deactivated__c From ActiveValidationRules__c Where SetupOwnerId = :UserInfo.getUserId() Limit 1][0].All_Validation_Rules_Deactivated__c);
        System.assertEquals(null, [Select Id, ParentId From Account Where Id =: sellers[0].Id Limit 1][0].ParentId);

        delete bp;
        AccountUpdateHelper.unlinkParentLegalEntity(sellers[0].Id);
        System.assertEquals(true, [Select Id From ActiveValidationRules__c Where SetupOwnerId = :UserInfo.getUserId() Limit 1].isEmpty());
    }
}