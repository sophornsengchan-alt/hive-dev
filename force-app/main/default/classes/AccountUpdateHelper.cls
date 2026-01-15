/*********************************************************************************************************************************
@ Class:          AccountUpdateHelper
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.01.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public with sharing class AccountUpdateHelper {

    private final String SOQL_ACTIVE_VALIDATION_RULE = 'Select Id, All_Validation_Rules_Deactivated__c from ActiveValidationRules__c Where SetupOwnerId = {0} Limit 1';
    
    private String sellerId;
    private User currentUser;
    private ActiveValidationRules__c vldRuleToUpsert;
    private ActiveValidationRules__c currentUserVldRule;

    public AccountUpdateHelper(String sellerId){
        this.sellerId = sellerId;
        currentUser = ApexUtil.getCurrentUser();
    }

    private AccountUpdateHelper getCurrentUserActiveVldRule(){
        ApexSafe.SafeQuery safeQuery = ApexSafe.query().secCheck(false); // must set access level to system mode to get existing custom setting ActiveValidationRules__c record for current user
        List<ActiveValidationRules__c> listVldRule = safeQuery.doQuery(String.format(SOQL_ACTIVE_VALIDATION_RULE, new String[]{ApexUtil.closeSQoute(currentUser.Id)}));
        currentUserVldRule = !listVldRule.isEmpty() ? listVldRule[0] : null;
        return this;
    }

    private AccountUpdateHelper upsertActiveVldRule(){

        vldRuleToUpsert = new ActiveValidationRules__c( All_Validation_Rules_Deactivated__c = true, SetupOwnerId = currentUser.Id);
        ApexSafe.SafeDML safeDml = ApexSafe.dml().secCheck(false); // must set access level to system mode to update custom setting ActiveValidationRules__c so it can bypass validation rule
        if(currentUserVldRule != null){
            vldRuleToUpsert.Id = currentUserVldRule.Id;
        }
        safeDml.doUpsert(new List<ActiveValidationRules__c>{vldRuleToUpsert}, ActiveValidationRules__c.Id, true );
        return this;
    }

    private AccountUpdateHelper clearAccParentId(){
        Account seller = new Account(Id = sellerId, ParentId = null);
        ApexSafe.SafeDML safeDml = ApexSafe.dml();
        safeDml.doUpdate(new List<Account>{seller}, true);
        return this;
    }

    private AccountUpdateHelper resetUpsertActiveVldRule(){
        if(vldRuleToUpsert != null){
            ApexSafe.SafeDML safeDml = ApexSafe.dml().secCheck(false);
            if(currentUserVldRule != null){ // if user has existing custom setting ActiveValidationRules__c record, then update it back to orignal state
                vldRuleToUpsert.All_Validation_Rules_Deactivated__c = currentUserVldRule.All_Validation_Rules_Deactivated__c;
                safeDml.doUpdate(new List<ActiveValidationRules__c>{vldRuleToUpsert}, true );
            }else{ // if user does not has existing custom setting ActiveValidationRules__c record, then delete it.
                safeDml.doDelete(new List<ActiveValidationRules__c>{vldRuleToUpsert}, true );
            }
        }
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         unlinkParentLegalEntity
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.01.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void unlinkParentLegalEntity(String sellerId){
        new AccountUpdateHelper(sellerId).getCurrentUserActiveVldRule().upsertActiveVldRule().clearAccParentId().resetUpsertActiveVldRule();
    }

}