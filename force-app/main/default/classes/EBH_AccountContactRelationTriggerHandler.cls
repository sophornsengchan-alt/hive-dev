/*********************************************************************************************************************************
@ Class:          EBH_AccountContactRelationTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND
@ Purpose:        Handler Class for Account Trigger
                  EPH-5 : Customer Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 31.08.2017 / NEHA LUND / Created the class.
*********************************************************************************************************************************/
public with sharing class EBH_AccountContactRelationTriggerHandler {
	public static final String ACRTH_QUERY             
        = 'SELECT id, Account.EBH_Status__c, Contact.EBH_Status__c'
        + ' FROM AccountContactRelation WHERE (accountID IN :accountContactIds OR'
        + ' contactID IN :accountContactIds) AND '
        + '(Account.EBH_Status__c = \'Deleted\''
        + ' OR Account.EBH_Status__c = \'Pending Termination\')';

    /*****************************************************************************************************************************
    @ Method:         validateUpdates
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        EPH-3293 : validates/prevents account contact relation update/deletion if the parent account or contact is 
                      - Deleted
                      - Pending Termination
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      accountContacts:      account Contact relations from the trigger scope
                      accountContactsOldMap: accounts old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2017 / NEHA LUND / Created the  Method.
    @					03/05/2021 / Sovantheany Dim / Updated method : US-0008430 - Bug - User unable to create contact on account record - historic trigger
    @					Remove the Contact filter in EBH_ConstantsUtility.ACRTH_QUERY query.
	@					This should allow creation of new contacts on account regardless of status from other contacts on the same account.
	@					Note: Only when Account Status is Deleted or Pending Termination, then we should continue to block creation of new Contacts related to this account.
    *****************************************************************************************************************************/
    public static void validateUpdates(List<AccountContactRelation> accountContacts) {
        Set<ID> accountcontactIds = new Set<ID>();
        Map<ID,String> statusMap = new Map<ID,String>();
        
        Id userId = UserInfo.getUserId();
        //get the logged in user's profile name
        String userProfileName = ((List<User>)Database.query(EBH_ConstantsUtility.userProfileQuery))[0].Profile.Name;
        
        //parse through records and add the account Id and contact Id
        for(AccountContactRelation acr: accountContacts){
            accountcontactIds.add(acr.accountId);
           	accountcontactIds.add(acr.contactId);
        }
        //get the related account/contact status and store it in the map, filter only for Deleted/Pending Termination
        for(AccountContactRelation acr: Database.Query(ACRTH_QUERY)){
            statusMap.put(acr.accountId, acr.account.EBH_Status__c);
            statusMap.put(acr.contactId, acr.contact.EBH_Status__c);
        }
        for(AccountContactRelation acr: accountContacts){
            //if profile is not business admin and system administrator
            //then account contact relationship is updated, then throw an error message 
            if((statusMap.containsKey(acr.accountId) || statusMap.containsKey(acr.contactID)) && 
               (!userProfileName.equalsIgnoreCase(EBH_constantsUtility.sysAdmin) && 
                !userProfileName.equalsIgnoreCase(EBH_ConstantsUtility.businessAdmin))){
                acr.addError(Label.EBH_AccountContactUpdateError);
            }
        }
    }
}