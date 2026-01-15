/*********************************************************************************************************************************
@ Class:          EBH_ConstantsUtility
@ Version:        1.0
@ Author:         JOY MONDOL (jmondol@deloitte.co.uk)
@ Purpose:        General utility class for Constants and SOQLs accross all apex
                  EPH-5, EPH-6, EPH-21 : Utility class for global constants
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 08.05.2017 / JOY MONDOL / Created the class.
                  14.09.2017 / Vadhanak Voun / added: UserCreation parts
*********************************************************************************************************************************/
public with sharing class EBH_ConstantsUtility {
    /*** EBH_DocuSignStatusTriggerHandler - BEGIN *******************************************************************************/
    public static final String DSTH_SENT        = 'Sent';
    public static final String DSTH_SENTFORSIGN = 'Sent for eBay Signature';
    public static final String DSTH_COMPLETED   = 'Completed';
    public static final String DSTH_EXECUTED    = 'Executed';
    public static final String DSTH_CLASSNAME   = 'EBH_DocuSignStatusTriggerHandler';
    public static final String DSTH_METHODNAME  = 'updateContractStatus';
    public static final String DSTH_CONTRACTQUERY 
        = 'SELECT Id, CompanySignedId From Contract WHERE Id IN:contractIds';
    /*** EBH_DocuSignStatusTriggerHandler - END *********************************************************************************/
    /*** EBH_AttachmentTriggerHandler - BEGIN ***********************************************************************************/
    public static final String  ATCH_CLASS      = 'EBH_AttachmentTriggerHandler';
    public static final String  ATCH_METHOD     = 'createTargetedSellers';
    public static final String  ATCH_COMMA      = ',';
    public static final Integer ATCH_MINUSONE   = -1;
    public static final String  ATCH_INDEXOF    = 'EBH_Seller__c,';
    public static final String  ATCH_CONTRACT   = 'Contract';
    public static final String  ATCH_METHODNAME = 'updateContractAttachmentCheck'; 
    public static final String ATCH_CONTRACTQUERY 
        = 'SELECT Id, EBH_AttachmentCheck__c From Contract WHERE Id IN:contractIds';    
    /*** EBH_AttachmentTriggerHandler - END *************************************************************************************/
    /*** EBH_RelatedSellersController - BEGIN ***********************************************************************************/
    public static final String RSC_SELLERCOUNTQUERY 
        = 'SELECT COUNT() FROM Account WHERE ParentId =: parentId AND RecordType.DeveloperName = \'EBH_Seller\''; // LIMIT 2000
    public static final String RSC_SELLERQUERY 
        = 'SELECT Id[PLACEHOLDER] FROM Account WHERE ParentId =: parentId AND RecordType.DeveloperName = \'EBH_Seller\' '
        + 'ORDER BY LastModifiedDate DESC LIMIT :PageSize OFFSET :PageNumber';
    /*** EBH_RelatedSellersController - END *************************************************************************************/
    /*** EBH_DistinctCampaignSellersController - BEGIN **************************************************************************/
    public static final String DCS_COMMA = ',';
    public static final String DCS_BLANK = '';
    public static final String DCS_PLACEH = '[PLACEHOLDER]';
    public static final String DCS_SELLERQUERY 
        = 'SELECT Id[PLACEHOLDER] FROM Account WHERE Id IN :accountIds';
    public static final String DCS_CAMPQUERY 
        = 'SELECT (SELECT Id FROM ChildCampaigns) FROM Campaign WHERE Id IN :campaignIds';
    //pagination query
    public static final String DCS_ACRQUERY 
        = 'SELECT Id FROM Account WHERE ID IN (SELECT AccountId FROM AccountContactRelation '
        + 'WHERE ContactId IN :contactIds AND Account.RecordType.DeveloperName=\'EBH_Seller\')' 
        + 'ORDER BY Id DESC LIMIT :PageSize OFFSET :PageNumber';    
    //count query
    public static final String DCS_ACCOUNTCOUNTQUERY 
        = 'SELECT COUNT() FROM Account WHERE ID IN (SELECT AccountId FROM AccountContactRelation '
        + 'WHERE ContactId IN :contactIds AND Account.RecordType.DeveloperName=\'EBH_Seller\') LIMIT 2000';
    /*
    public static final String DCS_ACCOUNTCOUNTQUERY 
        = 'SELECT COUNT() FROM AccountContactRelation '
        + 'WHERE ContactId IN :contactIds AND Account.RecordType.DeveloperName=\'EBH_Seller\'';
    */
    //count query
    public static final String DCS_CMCOUNTQUERY 
        = 'SELECT COUNT() FROM CampaignMember WHERE CampaignId IN :campaignIds LIMIT 2000';
    public static final String DCS_CMQUERY 
        = 'SELECT EBH_SerialF__c, ContactId FROM CampaignMember '
        + 'WHERE CampaignId IN :campaignIds AND EBH_SerialF__c > :iOffSet LIMIT 50000';
    /*** EBH_DistinctCampaignSellersController - END ****************************************************************************/
    /*** EBH_TargetingCockpitController - BEGIN *********************************************************************************/
    public static final Integer TCC_MINUSONE     = -1;
    public static final Integer TCC_ZERO         = 0;
    public static final Integer TCC_ONE          = 1;
    public static final Integer TCC_TWO          = 2;
    public static final Integer TCC_THREE        = 3;
    public static final Integer TCC_FIVE         = 5;
    public static final Integer TCC_TEN          = 10;
    public static final Integer TCC_TWENTY       = 20;
    public static final String TCC_ZEROPOINT     = '0.';
    public static final String TCC_ESCSTR        = '\'';
    public static final String TCC_SLASH         = '/';
    public static final String TCC_COLON         = ':';
    public static final String TCC_HIPHEN        = '-';
    public static final String TCC_CLS           = 'EBH_TargetingCockpitController2';
    public static final String TCC_METHODSF      = 'saveFilter';
    public static final String TCC_METHODCF      = 'cloneFilter';
    public static final String TCC_METHODRF      = 'refreshFilter';
    public static final String TCC_METHODUF      = 'updateFilter';
    public static final String TCC_METHODGTS     = 'generateTargetedSellers';
    public static final String TCC_WAVEDSNAME    = 'Seller_Name';
    public static final String TCC_c             = '__c';
    public static final String TCC_AND           = ' AND ';
    public static final String TCC_EQ            = '=';
    public static final String TCC_LIKE          = ' LIKE ';
    public static final String TCC_GT            = '>';
    public static final String TCC_GT2           = ' > ';
    public static final String TCC_LT            = '<';
    public static final String TCC_LT2           = ' < ';
    public static final String TCC_DELIMCOMMA    = '<2>';
    public static final String TCC_DELIMCOMMA2   = ' <2> ';
    public static final String TCC_DELIMEQUAL    = '<3>';
    public static final String TCC_DELIMPIPE     = '<4>';
    public static final String TCC_ACCOUNTFILTER = 'Account';
    public static final String TCC_NEWFILTER     = 'New filter';
    public static final String TCC_BLANK         = '';
    public static final String TCC_SPACE         = ' ';
    public static final String TCC_SELECTFIELD   = 'Select';
    public static final String TCC_NAMEINACCOUNT = 'Name IN :dwhAccountIds';
    public static final String TCC_WHERE         = 'WHERE ';
    public static final String TCC_SELACC        = 'SELECT Id FROM Account ';
    public static final String TCC_SELACCWHERE   = 'SELECT Id FROM Account WHERE ';
    public static final String TCC_LIMIT2000     = ' LIMIT 2000';
    public static final String TCC_LIMIT1000     = ' LIMIT 1000';
    public static final List<SelectOption> TCC_OPERATORS = new List<SelectOption> { new SelectOption('=',  'Equals'),
                                                                                    new SelectOption('<>', 'Not equals'),
                                                                                    new SelectOption('%',  'Contains'),
                                                                                    new SelectOption('>',  'Greater than'),
                                                                                    new SelectOption('<',  'Less than') };
    public static final Map <String, Integer> TCC_MONTHS = new Map <String, Integer> 
        { 'Jan' => 1, 'Feb' => 2, 'Mar' => 3, 'Apr' => 4, 'May' => 5, 'Jun' => 6, 
          'Jul' => 7, 'Aug' => 8, 'Sep' => 9, 'Oct' => 10, 'Nov' => 11, 'Dec' => 12 };
    public static final String TCC_WAVEAPICSQUERY 
        = 'SELECT EBH_ContainerId__c, EBH_DatasetId__c FROM EBH_WaveAPI__c WHERE Name = \'EBH_WAVEDWH\'';       
    public static final String TCC_FILTERQUERY 
        = 'SELECT Id, Name, EBH_RefreshUntil__c, EBH_Filter__c, OwnerId, Owner.Email, EBH_Refreshing__c,'
        + '(SELECT Id FROM EBH_TargetedSellers__r) '
        + 'FROM EBH_Filter__c WHERE Id =: filterId';
    public static final String TCC_FILTERSELLERLISTQUERY 
        = 'SELECT Id,EBH_TE_Expiration_Date__c, Name, EBH_Filter__c, EBH_Refreshing__c, Owner.Email FROM EBH_Filter__c WHERE Id =: sellerListId';
    /*** EBH_TargetingCockpitController - END ***********************************************************************************/
    /*** EBH_ContractApprovalSettingsController - BEGIN *************************************************************************/
    public static final Integer CAS_ZERO        = 0;
    public static final String  CAS_CLASSNAME   = 'EBH_ContractApprovalSettingsController';
    public static final String  CAS_M1          = 'getDefaultUser';
    public static final String  CAS_M2          = 'save';
    public static final String  CAS_M3          = 'createNewMatrices';
    public static final String  CAS_M4          = 'initiate';    
    public static final String  CAS_FINANCE     = 'EBH_Finance';
    public static final String  CAS_BURECORD    = 'EBH_BUApprover';
    public static final String  CAS_CONTROLLING = 'EBH_Controlling';
    public static final String  CAS_FIN         = 'Finance';
    public static final String  CAS_CON         = 'Controlling';
    public static final String  CAS_BU          = 'BU';
    public static final String CAS_RECTYPQUERY 
        = 'SELECT Id,DeveloperName FROM RecordType WHERE SobjectType = \'EBH_ContractApprovalHierarchy__c\'';
    public static final String CAS_MTRXPQUERY 
        = 'SELECT (SELECT RecordType.DeveloperName, EBH_ParentSite__c, EBH_BUApproverGroup__c ,Id,Name,EBH_Approver__c,'
        + 'EBH_Threshold__c,EBH_ContractApprovalMatrix__c '
        + 'FROM EBH_ContractApprovalHierarchies__r ORDER BY EBH_Threshold__c ASC),'
        + 'Id,Name,EBH_Site__c,EBH_LegalApprover__c,EBH_FinancePrecheckApprover__c FROM EBH_ContractApprovalMatrix__c';
    public static final String CAS_REMHRQUERY
        = 'SELECT Id FROM EBH_ContractApprovalHierarchy__c WHERE Id IN :RemoveIds';
    public static final String CAS_REMBUQUERY
        = 'SELECT Id FROM EBH_BUApproverGroup__c WHERE Id IN :RemoveIds';
    public static final String CAS_PROFQUERY
        = 'SELECT Id FROM PROFILE WHERE Name = \'System Administrator\'';
    public static final String CAS_ADMUSRQUERY
        = 'SELECT Id FROM User WHERE ProfileId = :pId AND isActive = true LIMIT 1';
    /*** EBH_ContractApprovalSettingsController - END ***************************************************************************/
    /*** EBH_CampaignTriggerHandler - BEGIN *************************************************************************************/
    public static final String CTH_CLASS             = 'EBH_CampaignTriggerHandler';
    public static final String CTH_CKPIMETHOD        = 'createCampaignKPIRecords';
    public static final String CTH_UPDATEFIELDMETHOD = 'updateFieldCustomRollUp';
    public static final String CTH_CCMMETHOD         = 'createCampaignMemberRecords';
    public static final String CTH_UPICC             = 'updatePrioritiesInChildCampaign'; 
    public static final String CTH_UCC               = 'updateChildCampaigns';   
    public static final String CAMP_SUBMITTED        = 'Submitted';
    public static final String CAMP_FEASIBILITY      = 'Feasibility';
    public static final String CAMP_PREPARATION      = 'Preparation';
    public static final String CTH_INSERT            = 'insert';    
    public static final Id StrategicPriorityRTId 
        = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Strategic Priority').getRecordTypeId();
    public static final Id CampaignProgrammeRTId 
        = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Campaign Programme').getRecordTypeId();
    public static final String CTH_PARENTCHILDQUERY 
        = 'SELECT Id,'
        + '( SELECT Id, EBH_Actual__c, EBH_Target__c, EBH_Campaign__c , EBH_KPI__c FROM EBH_CampaignKPIs__r )'
        + 'FROM Campaign WHERE Id IN: parentIds ';
    public static final String CTH_CAMPAIGNFIELDROLLUPQUERY 
        = 'SELECT Id, EBH_Targeted__c, EBH_Sent__c, EBH_Blocked__c, EBH_HardBounces__c, EBH_SoftBounces__c,'
        + 'EBH_OpenedUnique__c,EBH_ClickedUnique__c, EBH_CommittoAct__c, EBH_NotInterested__c, EBH_Unsubscribed__c, '
        + '(SELECT Id, EBH_Targeted__c, EBH_Sent__c, EBH_Blocked__c, EBH_HardBounces__c, EBH_SoftBounces__c '
        + ', EBH_OpenedUnique__c, EBH_ClickedUnique__c, EBH_CommittoAct__c, EBH_NotInterested__c, EBH_Unsubscribed__c '
        + ' FROM ChildCampaigns ) '
        + 'FROM Campaign WHERE Id IN: parentIds ';
    public static final String CTH_CHILDCAMPAIGNQUERY 
        = 'SELECT Id, EBH_Targeted__c, EBH_Sent__c, EBH_Reached__c, (SELECT Id, EBH_Targeted__c, EBH_Sent__c, EBH_Reached__c '
        + 'FROM ChildCampaigns) FROM Campaign Where Id IN :parentIds ';
    public static final String CTH_CAMPAIGNMEMBERTODELETERQUERY 
        = 'SELECT Id FROM CampaignMember WHERE CampaignId in : campaignIds ';    
    public static final String CTH_TARGETEDSELLERQUERY 
        = 'SELECT Id,Priority__c, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c in: sellerMapId ';    
    public static final String CTH_ACRQUERY 
        = 'SELECT ContactId, Account.Name FROM AccountContactRelation WHERE accountId in: accountIds ';    
    //public static final String CTH_PARENTCAMPPRIORITYQUERY 
    //    = 'SELECT Id, Name,RecordTypeId,Parent.EBH_StrategicPriority__c, Parent.Name,EBH_StrategicPriority__c '
    //    + 'FROM Campaign Where ParentId IN :parentIds ';
    public static final String CTH_CAMPPRIORITYACRQUERY     
        = 'SELECT Id,Name, EBH_Priorities__c, ParentId FROM Campaign Where Id IN :campaignIds ';
    //public static final String CTH_CCRQUERY     
    //    = 'SELECT Name,EBH_StrategicPriority__c from Campaign where Id IN :parents';
    /*** EBH_CampaignTriggerHandler - END ***************************************************************************************/
    /*** EHH_CampaignMemberTriggerHandler - BEGIN *******************************************************************************/
    public static final String CTH_CampaignMemberFIELDROLLUPQUERY 
        = 'SELECT EBH_Targeted__c, EBH_Sent__c, EBH_Blocked__c, EBH_HardBounces__c, EBH_SoftBounces__c,'
        + 'EBH_OpenedUnique__c,EBH_ClickedUnique__c, EBH_CommittoAct__c, EBH_NotInterested__c, EBH_Unsubscribed__c, '
        + '(SELECT Id,EBH_Results__c from CampaignMembers )'
        + ' FROM CAMPAIGN Where Id IN :parentIds AND '
        + ' RecordTypeId IN (SELECT Id FROM RecordType WHERE DeveloperName=\'EBH_SubCampaign\')';
    public static final String CTH_OUTCOMECODE      = '1000';  
    public static final String CTH_NONE_STATUS      = 'None';
    public static final String CTH_SENT_STATUS      = 'Sent';
    public static final String CTH_RESPONDED_STATUS = 'Responded';
    public static final String CTH_UNKNOWN_RESULT   = 'Unknown Result';
    public static final String CTH_REACHED_COMM     = 'Reached - Committed';
    public static final String CTH_REACHED_INT      = 'Reached - Interested';
    public static final String CTH_REACHED_UNS      = 'Reached - Unsubscribe';
    public static final String CTH_REACHED_NOTIN    = 'Reached - Not Interested';
    public static final String CTH_REACHED_INQ      = 'In Queue';
    public static final String CTH_FAILED_B         = 'Failed (Blocked)';
    public static final String CTH_FAILED_W         = 'Failed (Wrong Details)';
    public static final String CTH_FAILED_T         = 'Failed (Timeout)';
    public static final String CTH_REACHED_NOT      = 'Not Reached';
    public static final String CTH_REACHED_NOAC     = 'Reached - No Action';
    public static final String CTH_DEFAULTVALUE     = 'DEFAULT VALUE';
    public static final String CTH_CAMPAIGNQUERY    = 'SELECT Campaign_Type__c,Id,RecordTypeId, EBH_Channel__c, EBH_ChannelMp__c from Campaign where Id IN :campaignIds';
    /*** EHH_CampaignMemberTriggerHandler - END *********************************************************************************/
    /*** EBH_AccountTriggerHandler - BEGIN **************************************************************************************/
    public static final Integer ATH_RESET = 0;
    public static final String  ATH_CLASS = 'EBH_AccountTriggerHandler';
    public static final String  ATH_OBJECTNAME = 'Account';
    public static final String  CTH_OBJECTNAME = 'Contact';
    public static final String  ATH_METHOD = 'updateCustomRollUp';
    public static final String ATH_ACTIVEUSERQUERY = 'SELECT id, name from User where Name IN :names and isActive = true '
                                                   + 'LIMIT 50000';
    public static final String ATH_PARENTCHILDQUERY 
        = 'SELECT Id,EBH_SoldItems__c,EBH_GMVLast12Months__c,EBH_RevenueLast12Months__c,'
        + '(SELECT Id,EBH_SoldItems__c,EBH_GMVLast12Months__c,EBH_RevenueLast12Months__c FROM ChildAccounts'
        + ' WHERE RecordTypeId IN'
        + ' (SELECT Id FROM RecordType WHERE DeveloperName=\'EBH_Seller\' OR DeveloperName=\'EBH_LegalEntity\')) '
        + 'FROM Account WHERE Id IN: parentIds AND '
        + ' RecordTypeId IN (SELECT Id FROM RecordType WHERE DeveloperName=\'EBH_LegalEntity\')';
    public static final String ATH_ACCOUNTCONTACTQUERY 
        = 'SELECT EBH_DoNotContact__c,Incorrect_Phone_Number__c,Id, EBH_PhoneOptOut__c,Account.EBH_PhoneOut__c,EBH_Status__c, Account.EBH_Status__c,Primary_Contact__c,RecordtypeId,Name,AccountId from Contact'
        + ' WHERE AccountId IN :accountIds AND EBH_GDPRRemoved__c = false';
    public static final String ATH_URGENCYEMAILBODY 
        ='Dear <OWNER_NAME>,\n\n'
        +' An Urgency flag has been created for seller <ACCOUNT_NAME>.\n'
        + 'Urgency Reason: <URGENCY_REASON>\n'
        +' Urgency Action: <DEFECT_REASON>\n'
        +'Training on urgency flags can be found at '+Label.EBH_HiveUrgencyTaskTrainingURL+'\n\n'
        +'Thanks,\n'
        +'Hive';
    public static final String ATH_OWNERNAME      = '<OWNER_NAME>';
    public static final String ATH_ACCOUNTNAME    = '<ACCOUNT_NAME>';
    public static final String ATH_URGENCYREASON  = '<URGENCY_REASON>';
    public static final String ATH_DEFECTREASON   = '<DEFECT_REASON>';
    /*** EBH_AccountTriggerHandler - END ****************************************************************************************/    
    /*** EBH_KPIResultTriggerHandler - BEGIN ************************************************************************************/
    public static final String TYPE_SUM = 'Sum';
    public static final String TYPE_MAXIMUM = 'Max';
    public static final String TYPE_COUNT = 'Count';
    public static final String TYPE_Average = 'Average';
    public static final String TYPE_MINIMUM = 'Min';
    public static final String KTH_CLASS = 'EBH_KPIResultTriggerHandler';
    public static final String KTH_METHOD = 'updateCampaignKPIRecords';    
    public static final String KTH_PARENTCHILDQUERY 
        = 'SELECT Id, EBH_Actual__c,  '
        + '(SELECT Id,EBH_CampaignKPI__c,EBH_Actual__c, EBH_CampaignKPI__r.EBH_KPI__r.EBH_Type__c '
        + ' FROM EBH_KPIResults__r '
        + ' ORDER BY EBH_Actual__c DESC) '
        + 'FROM EBH_CAMPAIGNKPI__C WHERE EBH_CAMPAIGN__c IN: parentIds ';    
    /*** EBH_KPIResultTriggerHandler - END **************************************************************************************/
    /*** EBH_FilterResource - BEGIN *********************************************************************************************/    
    public static final String FR_BLANK = '';
    public static final String FR_FILTERQUERYCLAUSE = 'WHERE Id=:fId';
    public static final String FR_FILTERQUERY 
        = 'SELECT Id,Name,EBH_Field__c,EBH_Value__c,EBH_LensId__c,OwnerId FROM EBH_Filter__c ';
    /*** EBH_FilterResource - END ***********************************************************************************************/    
    /*** EBH_ContractTriggerHandler - BEGIN *************************************************************************************/    
    public static final String CONTRACT_CONTAPINAME             = 'Contract';
    public static final String CONTRACT_CONTSTATUSAPINAME       = 'Status';
    public static final String CONTRACT_READYFOREBAYSIGNATURE   = 'Ready for eBay Signature';
    public static final String CONTRACT_DRAFTSTATUS             = 'Draft';
    public static final String CONTRACT_VOIDEDSTATUS            = 'Voided';
    public static final String CONTRACT_NEGOTIATIONSTATUS       = 'In Negotiation';
    public static final String CONTRACT_PENDINGSTATUS           = 'Pending Approval';
    public static final String CONTRACT_FINANCESENTSTATUS       = 'Sent for Finance Pre-check';    
    public static final String HYPHEN_KEY                       = '-';
    public static final String CONTRACT_AGREEMENTRECORDTYPE     = 'Accession Agreement';
    public static final String CONTRACT_SITE_DE                 = 'DE';
    public static final String CONTRACT_SITE_IT                 = 'IT';
    public static final String CONTRACT_LANGUAGE_DE             = 'German';
    public static final String CONTRACT_LANGUAGE_IT             = 'Italian';
    public static final String HIERARCHY_CONTROLLING            = 'EBH_Controlling';
    public static final String HIERARCHY_FINANCE                = 'EBH_Finance';
    public static final String HIERARCHY_BUAPPROVER             = 'EBH_BUApprover';
    public static final String CONTRACT_LISTINGRECORDTYPE       = 'EBH_ListingAgreement';
    public static final String CONTRACT_ACPRECORDTYPE           = 'EBH_ACP';
    public static final String CONTRACT_RSRECORDTYPE            = 'EBH_RevenueShare';    
    public static final String CONTRACT_SentFinancePreChecked   = 'Sent for Finance Pre-check';
    public static final String CONTRACT_FinancePreChecked       = 'Finance Pre-checked';
    public static final String CONTRACT_InNegotiation           = 'In Negotiation';
    public static final String CONTRACT_PendingApproval         = 'Pending Approval';
    public static final String CONTRACT_Approved                = 'Approved';
    public static final String CONTRACT_SellerSignature         = 'Sent for Seller Signature';
    public static final String CONTRACT_SellerSignatureProvided = 'Seller Signature Provided';
    public static final String CONTRACT_eBaySignatureSent       = 'Sent for eBay Signature';
    public static final String CONTRACT_NULL                    = '';    
    public static final String CTH_ALL                          = 'All';
    public static final String CTH_CONTRACTCLASS                = 'EBH_ContractTriggerHandler';
    public static final String CTH_METHOD                       = 'updateApprovalComments';
    public static final String CONTRACT_LOCKERROR               = 'You cannot edit an approved contract. '
                                                                + 'Please recall to make changes and then resubmit for approval.';
    public static final String CTH_AHRECTYPEQUERY
        = 'SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType=\'EBH_ContractApprovalHierarchy__c\'';    
    public static final String CTH_CONTRECTYPEQUERY         
        = 'SELECT Id,Name,DeveloperName FROM RecordType WHERE SobjectType=\'Contract\' OR '
        + 'SobjectType=\'EBH_ContractApprovalHierarchy__c\'';    
    public static final String CTH_APPMTRXQUERY
        = 'SELECT EBH_Site__c,EBH_LegalApprover__c,EBH_FinancePreCheckApprover__c,'
        + '(SELECT Id,CurrencyISOCode, EBH_Approver__c,EBH_BUApproverGroup__c,EBH_ContractApprovalMatrix__c,'
        + ' EBH_Threshold__c,EBH_UniqueId__c,RecordType.Developername'
        + ' FROM EBH_ContractApprovalHierarchies__r ORDER BY EBH_Threshold__c DESC) FROM EBH_ContractApprovalMatrix__c';
    public static final String CTH_CONTRACTMAPQUERY 
        = 'Select id, Status, EBH_CancellationReason__c, (Select Id,  ProcessInstanceId, TargetObjectId, StepStatus, '
        + 'Comments, CreatedDate FROM ProcessSteps ORDER BY CreatedDate DESC) '
        + 'From Contract WHERE Id IN : contracts' ;
    //EPH-5367
    public static String SOQL_PROCESSINTANCE_NODE_BY_CONTRACT = 'Select ProcessInstance.TargetObjectId, ProcessNodeName, ProcessInstanceId, NodeStatus From ProcessInstanceNode where ProcessNodeName=\'BU Approval\' AND NodeStatus=\'Pending\'  AND  ProcessInstance.TargetObjectId IN:contractIds';
    /*** EBH_ContractTriggerHandler - END ***************************************************************************************/    
    /*** EBH_PricingTriggerHandler - BEGIN **************************************************************************************/
    public static final String PRICING_LISTINGRECORDTYPE            = 'EBH_ListingPricing';
    public static final String PRICING_ACPTARGETRECORDTYPE          = 'EBH_ACPTargets';
    public static final String PRICING_REVENUESHARETARGETRECORDTYPE = 'EBH_RevenueShareTargets';
    public static final String PRICING_FREESUBSCRIPTION             = 'Free';
    public static final String PRICING_NONFREESUBSCRIPTION          = 'Not Free';
    public static final decimal STORE_FEES                          =  0.0;
    public static final String PRICING_MULTI                        = 'Multi';
    public static final String CONTRACT_PARENTCHILDQUERY 
        = 'SELECT Id,EBH_RebateTierrebate__c, EBH_ContractExposure__c,CurrencyISOCODE,EBH_Site__c,EBH_IncrementalGMVonly__c, EBH_AverageTakeRate__c, '
        + 'EBH_StoreSubscription__c, EBH_ContractValue__c, RecordType.DeveloperName, EBH_OnBoardingFees__c, '
        + '(SELECT Id, CurrencyISOCode,EBH_GMVTarget__c , EBH_ListingExposure__c,  EBH_ListingValue__c, EBH_ACPValue__c, EBH_ACPExposure__c, '
        + ' EBH_RevenueExposure__c, EBH_RevenueValue__c, EBH_PriorYearGMV__c,  '
        + ' EBH_StoreSubscription__c, EBH_Site__c, RecordType.DeveloperName FROM EBH_Pricing__r'
        + ' ) '
        + 'FROM Contract WHERE Id IN: parentIds AND '
        + ' RecordTypeId IN (SELECT Id FROM RecordType WHERE DeveloperName=\''+CONTRACT_LISTINGRECORDTYPE+'\''
        + ' OR DeveloperName = \'' + CONTRACT_RSRECORDTYPE + '\''
        + ' OR DeveloperName = \'' + CONTRACT_ACPRECORDTYPE + '\')';  
    public static final String CONTRACT_PRICINGCONTRACTQUERY 
        = ' SELECT id, EBH_ContractExposure__c,CurrencyISOCode,EBH_Site__c, EBH_AverageTakeRate__c, EBH_StoreSubscription__c, '
        + ' EBH_ContractValue__c, RecordType.DeveloperName, EBH_RebateTierrebate__c, EBH_RevenueShareRate__c, '
        + '(SELECT Id, EBH_GMVTarget__c ,CurrencyISOCode, EBH_ListingExposure__c, EBH_ListingValue__c, EBH_ACPValue__c, EBH_ACPExposure__c, '
        + ' EBH_RevenueExposure__c, EBH_PriorYearGMV__c, EBH_RevenueValue__c, EBH_StoreSubscription__c, '
        + ' EBH_Site__c, RecordType.DeveloperName '
        + ' FROM EBH_Pricing__r) from Contract where id IN :parents ';     
    /*** EBH_PricingTriggerHandler - END ****************************************************************************************/
    /*** Exception - BEGIN ******************************************************************************************************/
    public static final String PRICE_CLASSHANDLER = 'EBH_PricingTriggerHandler';
    public static final String PRICE_CLASSMETHOD  = 'updateContractValueExposure';
    /*** Exception - END ********************************************************************************************************/
    /*** EBH_CampaignRequestApprovalExtensions - BEGIN **************************************************************************/
    public static final String REQUEST_CLASS    = 'EBH_CampaignRequestApprovalExtensions';
    public static final String REQUEST_METHOD   = 'submitRequest';
    public static final String SUBMITTED_STATUS = 'Submitted';
    /*** EBH_CampaignRequestApprovalExtensions - END ****************************************************************************/
    /*** EBH_CampaignApprovalSettingsController - BEGIN *************************************************************************/
    public static final String GROUP_QUERY = 'SELECT id from Group where DeveloperName = \'EBH_CampaignRequestApprovers\'';
    public static final String SITE_GROUPQUERY = 'SELECT id from Group where DeveloperName = :groupName';
    public static final String CAMPAIGN_RECORDQUERY = 'SELECT EBH_Site__c from Campaign where id = :campaignId';
    public static final String CAMS_MTRXPQUERY 
        = 'SELECT id, EBH_Site__c, (SELECT id, EBH_Approver__c FROM EBH_CampaignApprovalGroup__r) '
        + 'FROM EBH_CampaignApprovalMatrix__c ';
    public static final String CAM_REMHRQUERY
        = 'SELECT Id FROM EBH_CampaignApprovalGroup__c WHERE Id IN:RemoveIds';  
    public static final String CASC_GRPMEMS    
        = 'SELECT Id, DeveloperName from Group WHERE DeveloperName IN : crsGroups';   
    /*** EBH_CampaignApprovalSettingsController - END ***************************************************************************/
    /*** EBH_UniqueCampaignSellersExtensions - BEGIN ****************************************************************************/
    public static final String ACCOUNT_API     = 'Account';
    public static final String CONTACT_API     = 'Contact';
    public static final String CM_QUERY        = 'SELECT  Name, ';
    public static final String CONTACT_ACCOUNT = 'Contact.Account.';
    public static final String ACC_NAME        = 'Account.';
    public static final String ACC_QUERY 
        = ' Id FROM AccountContactRelation where ContactID IN :contactIds AND Account.RecordType.DeveloperName =\'EBH_SELLER\' '
        + 'LIMIT 2000';
    public static final String CM_ACCQUERY          
        = ' Contact.Account.Id from CampaignMember where CampaignId IN :campaignIds AND'
        + ' ContactId IN (SELECT ContactId FROM AccountContactRelation) LIMIT 40000';
    /*** EBH_UniqueCampaignSellersExtensions - END ******************************************************************************/
    /*** EBH_UniqueCampaignsExtensions - BEGIN **********************************************************************************/
    public static final String CONTACT_CAMPAIGN = 'Campaign.';
    public static final String CAMPAIGN_API     = 'Campaign';
    public static final String CMCONTACT_QUERY  
        = ' Id FROM CAMPAIGNMEMBER where ContactId IN :contactIds';
    /*** EBH_UniqueCampaignsExtensions - END ************************************************************************************/
    /*** EBH_CampaignKPITriggerHandler - Begin **********************************************************************************/
    public static final String CKTH_CLASS  = 'EBH_CampaignKPITriggerHandler';
    public static final String CKTH_METHOD = 'createChildKPIRecords';
    public static final String KPI_QUERY   = 'SELECT id, ParentId from Campaign where ParentId IN :kpiIds';
    public static final String CKTH_PARENTCHILDQUERY 
        = 'SELECT Id,EBH_CAmpaign__r.ParentID, EBH_KPI__r.EBH_Type__c, EBH_Actual__c  '
        + 'FROM EBH_CAMPAIGNKPI__C WHERE EBH_CAMPAIGN__c IN: parentIds ORDER BY EBH_Actual__c DESC';    
    /*** EBH_CampaignKPITriggerHandler - End ************************************************************************************/
    /*** EBH_CampaignMemberTriggerHandler - Begin *******************************************************************************/
    public static final String CMTH_CLASS            = 'EBH_CampaignMemberTriggerHandler';
    public static final String CMTH_METHOD           = 'updateFieldCustomRollUpOnCampaign';
    public static final String CMTH_TARGETED         = 'Targeted';
    public static final String CMTH_EBHTARGETED      = 'EBH_Targeted__c';
    public static final String CMTH_SENT             = 'Sent';
    public static final String CMTH_EBHSENT          = 'EBH_Sent__c';
    public static final String CMTH_BLOCKED          = 'Blocked';
    public static final String CMTH_EBHBLOCKED       = 'EBH_Blocked__c';
    public static final String CMTH_HARDBOUNCES      = 'Hard Bounces';
    public static final String CMTH_EBHHARDBOUNCES   = 'EBH_HardBounces__c';
    public static final String CMTH_SOFTBOUNCES      = 'Soft Bounces';
    public static final String CMTH_EBHSOFTBOUNCES   = 'EBH_SoftBounces__c';
    public static final String CMTH_OPENEDUNIQUE     = 'Opened (unique)';
    public static final String CMTH_EBHOPENEDUNIQUE  = 'EBH_OpenedUnique__c';
    public static final String CMTH_CLICKEDUNIQUE    = 'Clicked (unique)';
    public static final String CMTH_EBHCLICKEDUNIQUE = 'EBH_ClickedUnique__c';
    public static final String CMTH_COMMITTOACT      = 'Commit to act';
    public static final String CMTH_EBHCOMMITTOACT   = 'EBH_CommittoAct__c';
    public static final String CMTH_NOTINTERESTED    = 'Not interested';
    public static final String CMTH_EBHNOTINTERESTED = 'EBH_NotInterested__c';
    public static final String CMTH_UNSUBSCRIBED     = 'Unsubscribed';
    public static final String CMTH_EBHUNSUBSCRIBED  = 'EBH_Unsubscribed__c';
	//NK:27/09/2018
    public static final String SOQL_CAM_MEMBER = 'Select Campaign_Related_Seller_Details__c, Contact.Account.OwnerId,Contact.Account.Outreach_Manager__c,Contact.EBH_DoNotContact__c,Contact.Incorrect_Phone_Number__c,Campaign.RecordTypeId,Campaign.EBH_Channel__c,Campaign.Campaign_Type__c,Campaign.EBH_Site__c ,Id,Contact.EBH_PhoneOptOut__c,Contact.Primary_Contact__c,LeadId,Campaign.EBH_MemberLastRefreshDate__c,contact.Name,contact.firstname,contact.lastname,lead.name,campaign.ownerId,Campaign.Triggered_Send_Name__c,CampaignId,Campaign.ParentId,Campaign.Parent.RecordType.DeveloperName,Campaign.RecordType.DeveloperName, ContactId, campaign.survey_id__c,Contact.AccountId, EBH_ResponseCode__c,EBH_LastResponseDate__c,EBH_FirstResponseDate__c From CampaignMember';
    public static final String SOQL_CM_BY_IDS = 'Select Id,Campaign.RecordType.DeveloperName,Campaign.Triggered_Send_Name__c,ContactId From CampaignMember Where Id IN:setCM_ids';
    public static Boolean CM_RESPONSE_CALCULATED = false; //update cm trigger on same trigger, prevent circle
    /*** EBH_CampaignMemberTriggerHandler - End *********************************************************************************/
    /*** EBH_CSVUploaderController - BEGIN **************************************************************************************/
    public static final String CSV_CLASS  = 'EBH_CSVUploaderController';
    public static final String CSV_METHOD = 'createTargetedSellers';
    public static final String CSV_IDS    = 'Ids';
    public static final String CSV_OIDS   = 'oIds';
    public static final String CSV_SELLERQUERY
        = 'SELECT Id,Name, EBH_OracleId__c FROM Account WHERE Id IN :sellerIds OR EBH_OracleId__c IN :sellerIds';
    public static final String CSV_ACCQUERY 
        = 'SELECT Id, EBH_OracleId__c '
        + 'FROM Account WHERE Id IN: sellerIds OR (EBH_OracleId__c IN: sellerIds AND EBH_OracleId__c <> NULL)';
    public static final String CSV_SELLERLISTQUERY 
        = 'SELECT Id FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c =: parentId';
    /*** EBH_CSVUploaderController - END ****************************************************************************************/
    /*** EBH_SellerListTriggerHandler - BEGIN ***********************************************************************************/
    public static final String STH_CLASS  = 'EBH_SellerListTriggerHandler';
    public static final String STH_METHOD = 'createSnapshot';
    /*** EBH_SellerListTriggerHandler - End *************************************************************************************/
    /*** EBH_CampaignHistory - BEGIN ********************************************************************************************/
    public static final String PLACEH = '[PLACEHOLDER]';
    public static final String CMQUERY 
        = 'SELECT Id[PLACEHOLDER] FROM CampaignMember '
        + 'WHERE ContactId IN (SELECT ContactId FROM AccountContactRelation '
        + 'WHERE AccountId = :accountId) ORDER BY LastModifiedDate DESC LIMIT :PageSize OFFSET :PageNumber';
    public static final String CMCOUNTQUERY 
        = 'SELECT COUNT() FROM CampaignMember '
        + 'WHERE ContactId IN (SELECT ContactId FROM AccountContactRelation WHERE AccountId = :accountId)';
    /*** EBH_CampaignHistory - END **********************************************************************************************/
    /*** EBH_TrainingMaterialsController - BEGIN ********************************************************************************/
    public static final String TRAINING_QUERY 
        = 'SELECT Id, Name, EBH_Description__c, EBH_FileURL__c, EBH_URL__c, Admins_Only__c  '
        + ' FROM EBH_TrainingMaterial__c '
        + ' WHERE (EBH_FileURL__c <> NULL OR EBH_URL__c <> NULL) '
        + ' ORDER BY EBH_Sequence__c ASC';
    /*** EBH_TrainingMaterialsController - END **********************************************************************************/
    /* EBH_InsertTargetSellersBatch  - BEGIN ************************************************************************************/
    public static final String LIGHTNINGURL            = '.lightning.force.com';
    public static final String ITSBATCH_CLASSNAME      = 'EBH_InsertTargetSellersBatch';
    public static final String ITSBATCH_METHODEXECUTE  = 'execute';
    public static final String ITSBATCH_METHODFINISH   = 'finish';
    public static final String ITSBATCH_NOREPLY = 'noreply@salesforce.com';
    public static final String ITSBATCH_SENDERDISPLAY  = 'Seller List Refreshed: ';
    public static final String ITSBATCH_MAILBODY  
        = 'Hello!\n\n' 
        + 'Your Targeted Seller has been refreshed. ' 
        + 'To view the list of Sellers, please go to:\n\n ';
    /* EBH_InsertTargetSellersBatch  - END **************************************************************************************/
    /*Apex Trigger - Begin*/
    public final static string TRIGGERCONTROLLER     = 'EBH Trigger Controller'; //custom setting name
    public       static boolean TARGETSELLER_CONTEXT = false;
    /*Apex Trigger - Begin*/   
    /*** EBH_AccountManagerUpdateBatch - BEGIN **********************************************************************************/
    public final static String ACCOUNT_QUERY 
        = 'SELECT id, ownerId, EBH_AccountManageName__c from Account WHERE EBH_UpdateAccountManager__c = true Limit 50000';
    /* EBH_AccountManagerUpdateBatch  - END *************************************************************************************/
    /*** EBH_DeleteTargetSellersBatch - BEGIN ***********************************************************************************/
    public static final String DTSBATCH_CLASSNAME   = 'EBH_DeleteTargetSellersBatch';
    public static final String DTSBATCH_CLASSMETHOD = 'execute';
    public final static String DTSBATCH_QUERYSTRING 
        = 'SELECT id from EBH_TargetedSeller__c where EBH_SellerList__C = :FilterId';
    /*** EBH_DeleteTargetSellersBatch - END *************************************************************************************/
    /*** EBH_CampaignMemberRefreshController - BEGIN ****************************************************************************/
    public final static String CMRC_EXECUTION     = 'Execution';
    public final static String CMRC_COMPLETED     = 'Completed';
    public final static String CMRC_CANCELLED     = 'Cancelled';
    public final static String CMRC_CAMPRECORDTYPE        = 'EBH_SubCampaign';
    public final static String CMRC_MASCAMPRECORDTYPE     = 'EBH_Campaign';
    public final static String CMRC_QUERY 
        = 'SELECT OwnerId,EndDate,Campaign_Type__c,EBH_TaskCreated__c,Survey_ID__c,EBH_ChannelMP__c,EBH_Channel__c,Journey_ID__c,Journey_Status__c,Journey_Version__c,Id, EBH_SellerList__c, EBH_ControlGroupSize__c, RecordType.DEveloperName, Status, Parent.Status FROM Campaign WHERE Id = :campaignId';
    public final static String CMRC_QUERY2 
        = 'SELECT Campaign_Type__c,EBH_TaskCreated__c,Survey_ID__c,EBH_ChannelMP__c,EBH_Channel__c,Journey_ID__c,Journey_Status__c,Journey_Version__c,Id, EBH_SellerList__c, EBH_ControlGroupSize__c, RecordType.DEveloperName, Status, Parent.Status FROM Campaign ';
    /*** EBH_CampaignMemberRefreshController - END ******************************************************************************/
    /*** EBH_ContractApprovalController - BEGIN *********************************************************************************/
    public static final String CAC_CLASSNAME = 'EBH_ContractApprovalController';
    public static final String CAC_METHOD    = 'submitApprovalRequest';
    public final static String CAC_QUERYSTRING 
        = 'SELECT EBH_Site__c, Status, EBH_BUApprover__c, EBH_ContractValue__c FROM Contract where id = :contractId';
    /*** EBH_ContractApprovalController - END ***********************************************************************************/
    /*** EBH_SellerListRefreshBatch - BEGIN *************************************************************************************/
    public static final String SLRBATCH_CLASSNAME = 'EBH_SellerListRefreshBatch';
    public static final String SLRBATCH_METHOD    = 'execute';
    public static final String SLRBATCH_SELLERLISTQUERY 
        = 'SELECT Id,Name,EBH_LastRefreshDate__c,EBH_NextRefreshDate__c,EBH_RefreshFrequence__c, '
        + 'EBH_RefreshUntil__c, EBH_Filter__c FROM EBH_Filter__c WHERE EBH_NextRefreshDate__c = TODAY AND '
        + 'RecordTypeId =: recTypeId AND EBH_RefreshFrequence__c > 0';
    public final static String SLRBATCH_RECORDTYPEQUERY = 'SELECT Id FROM RecordType WHERE sobjecttype = \'EBH_Filter__c\' ' 
                                                + 'AND DeveloperName = \'EBH_AutoRefreshSellerList\'';   
    /*** EBH_SellerListRefreshBatch - END ***************************************************************************************/
    /*** EBH_DistinctCampaignSellersController2 - BEGIN *************************************************************************/
    public static final String DCSC_COUNTQUERY 
        = 'SELECT COUNT() FROM CampaignMember WHERE CampaignId IN :campaignIds';
    public final static String DCSC_CAMPAIGNMEMBERQUERY 
        = 'SELECT EBH_SerialF__c, ContactId FROM CampaignMember WHERE CampaignId IN :campaignIds AND EBH_SerialF__c > :iOffset '
        + 'ORDER BY EBH_SerialF__c LIMIT :rows';   
    public final static String DCSC_ACRQUERY 
        = 'SELECT AccountId FROM AccountContactRelation WHERE ContactId IN :contactIds AND '
        + 'Account.RecordType.DeveloperName=\'EBH_Seller\'';
    /*** EBH_DistinctCampaignSellersController2 - END ***************************************************************************/
    /*** EBH_CustomCampaignTriggerHandler - BEGIN *******************************************************************************/
    public static final String CCTH_CLASSNAME    = 'EBH_CustomCampaignTriggerHandler';
    public static final String CCTH_METHODUPSERT = 'upsertCampaignMembers';
    public static final String CCTH_METHODDELETE = 'deleteCustomMembers';
    public static final String CCTH_CAMPAIGNMEMBERQUERY 
        = 'SELECT id, EBH_CockpitResultId__c from CampaignMember where campaignId IN :campaignIds '
        + 'and EBH_CockpitResultId__c IN :cockpitIds LIMIT 50000';
    /*** EBH_CustomCampaignTriggerHandler - END *********************************************************************************/
    /*** EBH_ContentDocumentLinkHandler - BEGIN *********************************************************************************/
    public static final String CDLH_CLASSNAME        = 'EBH_ContentDocumentLinkHandler';
    public static final String CDLH_METHOD           = 'updateTrainingMaterialFileURL';
    public static final String CDLH_TRAININGMATERIAL = 'EBH_TrainingMaterial__c';
    public static final String CDLH_DOWNLOADURL      = '/sfc/servlet.shepherd/version/download/';
    public final static String CDLH_CONTENTDOCUMENTQUERY 
        = 'SELECT Id, LinkedEntityId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE Id IN:fileFeedIds';
    public final static String CDLH_TRAININGMATERIALQUERY 
        = 'SELECT Id, EBH_FileURL__c FROM EBH_TrainingMaterial__c WHERE  Id IN: trainingMaterialMapId';
    /*** EBH_ContentDocumentLinkHandler - END ***********************************************************************************/
    /*** EBH_AccountManagerUpdateBatch - BEGIN **********************************************************************************/
    public static final String ABTH_CLASS   = 'EBH_AccountManagerUpdateBatch';
    public static final String ABTH_SMETHOD = 'Start';
    public static final String ABTH_FMETHOD = 'Finish';
    public static final String ABTH_EMETHOD = 'Execute';
    /*** EBH_AccountManagerUpdateBatch - END ************************************************************************************/
    /*** EBH_InsertCampaignMemberBatch - BEGIN **********************************************************************************/
    public static final String ICMBATCH_CLASS   = 'EBH_InsertCampaignMemberBatch';
    public static final String ICMBATCH_EMETHOD = 'Execute';
    /*** EBH_InsertCampaignMemberBatch - ENDf ***********************************************************************************/
    /*** EBH_DeleteCampaignMemberBatch - BEGIN **********************************************************************************/
    public static final String DCMBATCH_CLASS   = 'EBH_DeleteCampaignMemberBatch';
    public static final String DCMBATCH_EMETHOD = 'Execute';
    /*** EBH_DeleteCampaignMemberBatch - END ************************************************************************************/
    /*** EBH_AccountContactRelationTriggerHandler - BEGIN ***********************************************************************/
    public static final String ACRTH_DELETEDSTATUS    = 'Deleted';
    public static final String ACRTH_TERMINATEDSTATUS = 'Pending Termination';
    public static final String sysAdmin               = 'System Administrator';
    public static final String businessAdmin          = 'Business Admin';
    public static final String userProfileQuery       = 'SELECT Profile.Name from User where id = :userId';
    public static final String ACRTH_QUERY             
        = 'SELECT id, Account.EBH_Status__c, Contact.EBH_Status__c'
        + ' FROM AccountContactRelation WHERE (accountID IN :accountContactIds OR'
        + ' contactID IN :accountContactIds) AND '
        + '(Account.EBH_Status__c = \'Deleted\''
        + ' OR Account.EBH_Status__c = \'Pending Termination\''
        + ' OR Contact.EBH_Status__c = \'Deleted\''
        + ' OR Contact.EBH_Status__c = \'Pending Termination\')';
    /*** EBH_AccountContactRelationTriggerHandler - END ************************************************************************/
    /*** EBH_FutureTasksController - BEGIN *************************************************************************************/
    public final static Date FTC_DUEDATE 
        = Date.today();
    public final static String FTC_TASKQUERY 
        = 'SELECT Id[PLACEHOLDER] from Task WHERE ownerId =\''
        + UserInfo.getUserId()+'\' AND ActivityDate >= TODAY ORDER BY CREATEDDATE DESC LIMIT 5 ';   
    public final static String FTC_EVENTQUERY 
        = 'SELECT Id[PLACEHOLDER] from Event WHERE ownerId=\''
        + UserInfo.getUserId()+'\' AND ActivityDate >= TODAY ORDER BY CREATEDDATE DESC LIMIT 5';   
    public static final String FTC_COUNTTASKQUERY 
        = 'SELECT COUNT() FROM TASK WHERE ownerId =\''
        + UserInfo.getUserId()+'\' AND ActivityDate >= TODAY  ';   
    public static final String FTC_COUNTEVENTQUERY 
        = 'SELECT COUNT() FROM EVENT WHERE ownerId =\''
        + UserInfo.getUserId()+'\' AND ActivityDate >= TODAY '; 
    /*** EBH_FutureTasksController - END ***************************************************************************************/
    /*** EBH_TaskTriggerHandler - START ****************************************************************************************/
    public static final String TTH_CLASS = 'EBH_TaskTriggerHandler';
    public static final String TTH_METHOD = 'captureMemberResponseCode';
    public static final String TTH_QUERY = 'SELECT EBH_FirstResponseDate__c, '
                                            +' EBH_ResponseCode__c from CampaignMember '
                                            +' WHERE Campaign.RecordType.DeveloperName = \'EBH_AMOutreach\'' 
                                            +' AND Id IN :campaignMemberIds';
    public static final String TTH_URGENCYTASK = 'Urgency Task is created';
    public static final String TTH_ACCQUERY  = 'SELECT Id, EBH_UrgencyReason__c, EBH_DefectREason__c from '
                                             + 'ACCOUNT WHERE ID IN :accountIDs';
    public static final String TTH_URGENCYACTION = 'Urgency Action: ';                                         
    public static final String TTH_URGENCYREASON = 'Urgency Reason: ';                                         
    public static final String TTH_NEWLINE  = '\n';    
    /*** EBH_TaskTriggerHandler - END ******************************************************************************************/
    /*** EBH_PhoneCampaignCompletionBatch - START ******************************************************************************/
    public static final String PCB_CLASS = 'EBH_PhoneCampaignCompletionBatch';
    public static final String PCB_METHOD = 'execute';
    public static final String PCB_QUERY  = 'SELECT id, campaignId, EBH_LastResponseDate__c from CampaignMember '
                                             +' where Campaign.RecordType.DeveloperName =\'EBH_AMOutreach\''
                                             +' and Campaign.Status != \'Completed\' AND '
                                             +' EBH_LastResponseDate__c != null order by EBH_LastResponseDate__c DESC ';
    public static final String PCB_COMPLETED = 'Completed';
    /*** EBH_PhoneCampaignCompletionBatch - END ********************************************************************************/
    /*** EBH_CampaignApprovalGroupHandler - START ******************************************************************************/
    public static final String CAGH_GRPMEMS = 'SELECT Id, DeveloperName, '
                                             +' (SELECT id, GroupId, userOrgroupID from GroupMembers)  from Group' 
                                             +' WHERE DeveloperName IN : crsGroups';
     public static final String BU_MEMS = 'SELECT Id, DeveloperName, Name, '
                                             +' (SELECT id, GroupId, userOrgroupID from GroupMembers)  from Group' ;                                             
    /*** EBH_CampaignApprovalGroupHandler - END ********************************************************************************/
    /*** EBH_CampaignMemberTaskController - START ******************************************************************************/
    public static final String AOC_TASKNAME = ' - Phone Outreach';
    public static final String AOC_OUTREACH = 'Phone Outreach';
    public static final String AOC_TASKSTATUS = 'Open';
    public static final String AOC_TASKCALL   = 'Call Planned';
    public static final String AOC_TASKPHONE  = 'Phone Blacklist';
    public static final String AOC_TASKWRONGPHONE  = 'Wrong Phone Number';
    public static final String AOC_TASKCALLNOTANSWERED  = 'Call Not Answered';
    public static final String AOC_TASKDMCNOTREACHED  = 'DMC Not Reached';
    public static final String AOC_TASKDMCNOTINTERESTED  = 'DMC Not Interested';
    public static final String AOC_UNSUBSCRIBE  = 'Unsubscribe';
    public static final String AOC_TASKDMCINTERESTED  = 'DMC Interested';
    public static final String AOC_TASKDMCCOMMITTED  = 'DMC Committed';
    public static final Integer AOC_TASKDUE   =  7;
    public static final String AOC_CAMPQUERY 
        = 'SELECT campaignId, Id, EBH_CockpitResultId__c ,campaign.Name, ContactId,campaign.ownerId,Contact.AccountId, '
        + 'contact.account.Owner.Name '
        + 'FROM CampaignMember where campaignID =:campaignId';
    public static final String AOC_CLASS  = 'EBH_CampaignMemberTaskController';
    public static final String AOC_METHOD = 'createTasks';
    /*** EBH_CampaignMemberTaskController - END *******************************************************************************/
    /*** UserCreation -BEGIN **************************************************************************************************/
    public final static String SOQL_RECTYPE_USERFORM= 'SELECT Id,Name,DeveloperName FROM RecordType WHERE DeveloperName=\'User_Request_Form\' AND SobjectType=\'Ticket__c\'';    
    public final static String STATUS_INPROGRESS = 'In Progress';
    public final static String TICKET_STATUS_VALIDATED = 'Validated';
    public static final String SOQL_PERMISSIONSET = 'SELECT ID,Name FROM PermissionSet';
    public static final String SOQL_GRP = 'SELECT ID,Name,DeveloperName FROM Group';    
    public static final String SOQL_PROFILE = 'select Id,Name from Profile';
    public static final String AT_HIVE_SUFFIX = '@hive.project.com';
	public static final String AT_GCX_SUFFIX = '@hive.gcx.com';
    public static final String HIVE_SUFFIX = 'Hive';
    public static final String ERROR_NO_PROFILE = 'No prfile mapping found. ';
    public static final String STATUS_DONE = 'Done';
    public static final String STATUS_CLOSED = 'Closed';
    public static final String ENCODE_UTF8 = 'UTF-8';
    public static final String ERROR_INVALID_COUNTRY_MAPPING 
        = 'Invalid Country Mapping defined in CustomSetting(CountryMapping3__c) :';
    public static final String ERROR_NO_COUNTRY_MAPPING 
        = 'No Country Mapping defined in CustomSetting(CountryMapping3__c) :';
    public static final String ERROR_LOCALE_GROUP_MAPPING 
        = 'No Locale to Public Group Mapping defined in CustomSetting(Locale_PublicGroup_Mapping) :';
    public static final String CLASS_TICKETHANDLER = 'TicketHandler';
    public static final String CLASS_TICKETHANDLER_METH_CHECKCREATEUSERS = 'checkCreateUsers';
    public static final String CLASS_TICKETHANDLER_METH_ADDMEMBERASYN = 'addMemberAsyn'; 
    public static final String SOQL_User 
        = 'Select Id,FirstName, lastName,Name,UserType, username,Email,isActive, Permission_Sets__c,LocaleSidKey From User Where Id in: setUser';
    public static final String SOQL_ADMIN_PROFILES 
        = 'SELECT ID FROM Profile WHERE NAME IN(\'System Administrator\',\'Business Admin\',\'System Administrator - Limited Privileges\')';
    //public static final String SOQL_PERMISSIONSET_WAVE_A_USER         = 'SELECT ID FROM PermissionSet WHERE NAME =\'EBH_WaveAnalyticsUser\'';
    public static final String SOQL_PERMISSIONSET_WAVE_A_USER         
        = 'SELECT ID FROM PermissionSet WHERE NAME =\'CustomEinsteinAnalyticsPlusUser\'';
    /*** UserCreation -END ****************************************************************************************************/    
    /*** EBH_UpdateContractApproversBatch -START ******************************************************************************/    
    public static final String SOQL_CONTRACTS 
        = 'SELECT id from Contract where status =\'Draft\' OR status =\'In Negotiation\'';
    /*** EBH_UpdateContractApproversBatch -END ********************************************************************************/    
    /*** CustomApprovalActionController -START ******************************************************************************/  
    public static String soqlStepAndItem = 'Select Id, TargetObjectId,TargetObject.Name, SubmittedById,SubmittedBy.Name, Status, ProcessDefinitionId, SystemModstamp, '+
                                     '  LastActorId,LastActor.Name,  CreatedDate,  CompletedDate, '+ 
                                     '(Select Id, IsPending, ProcessInstanceId, TargetObjectId, StepStatus, ProcessNodeId,ProcessNode.Name, '+ 
                                      'OriginalActorId,OriginalActor.Name, ActorId,Actor.Name,  Comments,  CreatedDate From StepsAndWorkitems  %where1% ORDER BY CreatedDate DESC, Id DESC) '+
                                      'From ProcessInstance';
    public static String soqlContract = 'Select Id,Name,Status,AccountId,Account.Name,OwnerId,Owner.Name,Description,ContractNumber From Contract ';
    public final static String ADMIN_PROFILE_ID = '00e6A000000HNzwQAG';
  /*** CustomApprovalActionController -END ******************************************************************************/  
    public final static Set<String> SET_AVAIL_SLOT_COUNT  = new Set<String>{'New','Negotiating','Rejected'};
    /** NK:26/04/2018: EPH-5479 Additional bolt-ons for Listing and ACP *************************************************************/  
    public final static String CONTRACT_AMBOLT_STANDARD = 'Standard Price';
    public final static String CONTRACT_AMBOLT_FREE = 'Free';
    /** DSTN:01/05/2018: EPH-5630 Seller - Quality & Preference : Data Quality section*****/
    public final static String GREEN_CONTACT = 'Green';
    public final static String RED_ACCOUNT = 'Red';
    public final static String AMBER_ACCOUNT = 'Amber';
    /*** EBH_RandomControlGroupController - START ******************************************************************************/
    public final static String RCG_QUERY
        = 'SELECT Id , Status, EBH_ControlGroupSize__c FROM Campaign WHERE EBH_SellerList__c = :filterId Limit 1';
    public final static String RCG_FilTERQUERY 
        = 'SELECT EBH_ActualControlGroupSize__c  from EBH_Filter__c where Id = :filterId';
    public final static String RCG_TARGETEDSELLERQUERY 
         =  'SELECT Id, EBH_Seller__c, EBH_SellerList__c,Priority__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId '; 
    public final static String RCG_VALIDSELLERQUERY 
         =  'SELECT Id, EBH_Seller__c, EBH_SellerList__c, EBH_ExitCode__c FROM EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId AND EBH_ExitCode__c != \'30\' '; 
    public final static String RCG_TARGETEDSELLERQUERYLIMIT 
        = 'SELECT id from EBH_TargetedSeller__c where EBH_SellerList__c= :filterId limit 1 ';  
    /*** EBH_RandomControlGroupController - END ******************************************************************************/
    /*** NK:24/05/2018: EBH_TargetingCockpitController2 - START *************************************************************/
    public final static String SOQL_MCAMPAIGN_BY_SELLER_LIST = 'SELECT Status FROM Campaign WHERE EBH_SellerList__c =: filterId AND RecordType.DeveloperName=\'EBH_Campaign\'';
    public final static Set<String> CAMPAIGN_STATUS_TO_BLOCK_TE = new Set<String>{'Completed','Execution'};
    /*** EBH_TargetingCockpitController2 - END ******************************************************************************/
    /*** NK:25/05/2018: EBH_UploadDealController - START *************************************************************/
    //NK:25/05/2018: //EPH-5771 , code to id
    public static Map<String,String> MAP_SITE_CODE_ID = new Map<String,String>
    {
        'IT'=>'101',
         'ES'=>'186',
         'UK'=>'3',
         'FR'=>'71',
         'DE'=>'77'
    };
    /*** NK:25/05/2018: EBH_UploadDealController - END *************************************************************/
    /*** NK:26/05/2018: EBH_TargetingCockpitController2 - Start *************************************************************/
    public static final Integer LIMIT_SOQL = 50000;
    /*** NK:26/05/2018: EBH_TargetingCockpitController2 - END *************************************************************/
    /*** NK:29/05/2018: EBH_CSVUploaderController - Start *************************************************************/
    public static final String SOQL_ATTACHEMENT = 'Select Id,Body from Attachment Where Id =: attId';
    /*** NK:29/05/2018: EBH_CSVUploaderController - Start *************************************************************/
    /*** NL: 29/05/2018: EBH_ExitCodeController --- START ******************************************************************************/
    public static final String EXIT_TARGETEDSELLERQUERY = 'SELECT Id, EBH_Seller__c, EBH_Seller__r.EBH_OracleId__c from EBH_TargetedSeller__c WHERE (EBH_Seller__c IN :sellerIds OR EBH_Seller__r.EBH_OracleID__c IN :sellerIds) AND EBH_SellerList__c = :filterId';
    public static final String EXIT_Code = '09';
    public static final String RESET_Code = '10';
    public static final String EXIT_TARGETEDCOUNT =  'SELECT count() from EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId';
    public static final String EXIT_EXISTINGTARGET = 'SELECT Id, EBH_Seller__c from EBH_TargetedSeller__c WHERE EBH_SellerList__c = :filterId AND ( EBH_EXITCODE__C = \'09\' OR EBH_EXITCODE__C = \'9\')';
    /*** NL: 29/05/2018: EBH_ExitCodeController --- END ******************************************************************************/
    /*** NK: 04/06/2018: BatchDeactivateUsers --- START ******************************************************************************/
    public final static String DEACTIVATION_SENDER_DISPLAY ='Hive Support';
    public final static String SOQL_USER_DEACTIVATION = 'SELECT Reactivated_Date__c,Name, LastLoginDate,IsActive, Id,First_Notification__c,Final_Notification__c From User WHERE IsActive = true AND LastLoginDate <:lastLoginDateStrict30 AND Profile.Name <>\'System Administrator\' AND Active_Approver__c=false';
    public final static String DEACTIVATION_TEMPLATE_FIRST_NOTIFICATION  = 'We_Want_you_back';
    //public final static String DEACTIVATION_TEMPLATE_FINAL_NOTIFICATION  = 'Final_Notification';
    public final static String DEACTIVATION_TEMPLATE_FINAL_NOTIFICATION  = 'Final_Notification2'; //UPDATED BY DHE US-0007085
    //public final static String SOQL_DEACTIVATION_TEMPLATE = 'Select  Id,DeveloperName from EmailTemplate WHERE DeveloperName IN(\'We_Want_you_back\',\'Final_Notification\')';
    public final static String SOQL_DEACTIVATION_TEMPLATE = 'Select  Id,DeveloperName from EmailTemplate WHERE DeveloperName IN(\'We_Want_you_back\',\'Final_Notification2\')';//UPDATED BY DHE US-0007085
    /*** NK: 04/06/2018: BatchDeactivateUsers --- END ******************************************************************************/
    /*** NK: 07/06/2018: EBH_DealController --- START ******************************************************************************/
    public final static Set<String> DEAL_NEGOTIATION_STATUS = new Set<String>{'New','Negotiating Amended'};
    public final static String DEAL_STATUS_NEGOTIATING = 'Negotiating';
    public final static Set<String> DEAL_NEGOTIATION_IGNORE_PROFILES = new Set<String>{'System Administrator'};
    public final static String DEAL_LOCK_ERROR_MSG = 'Deal is locked while in Negotiating.';
    /*** NK: 07/06/2018: EBH_DealController --- End ******************************************************************************/
     /*** NK: 12/06/2018: LeadTriggerHandler --- START ******************************************************************************/
    public final static String SOQL_ACCOUNT = 'SELECT EBH_RevRollup__c,ID,NAME,EBH_OracleID__c FROM ACCOUNT WHERE ID IN:setAccountIds';
    public final static String SOQL_LEAD = 'SELECT ID,NAME FROM LEAD WHERE  EBH_eBayID__c IN:setEbayIds OR EBH_OracleID__c IN:setOracleIds  OR Email IN:setEmails';
    /*** NK: 12/06/2018: LeadTriggerHandler --- END ******************************************************************************/
     /*** NK: 12/06/2018: EBH_ContractTriggerHandler --- START ******************************************************************************/
     public final static Set<String> SET_EXCLUDE_CONTRACT = new Set<String>{EBH_ConstantsUtility.CONTRACT_READYFOREBAYSIGNATURE,'Sent for eBay Signature','Executed','Voided'};
     /*** NK: 12/06/2018: EBH_ContractTriggerHandler --- END ******************************************************************************/
     /*** NK: 25/06/2018: DocuSignLNSending2ControllerExt --- START ******************************************************************************/
     public final static String SOQL_DOCUSIGN_USER_PS = 'Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'DocuSign_User\',\'DocuSign_Administrator\') AND AssigneeId=:currentUserId LIMIT 1';
     /*** NK: 25/06/2018: DocuSignLNSending2ControllerExt --- END ******************************************************************************/
     /*** NK: 04/07/2018: SellerHealthSummaryController --- START ******************************************************************************/
     public final static String SOQL_SELLER_HEALTH_PDF  = 'Select Id, (Select EBH_DriverName__r.Group__c,EBH_DriverName__r.Order__c,Actual_calculated__c,ClinicMoM_calculated__c,Benchmark_calculated__c, EBH_DriverName__c,EBH_DriverName__r.Name, EBH_Actual__c, EBH_ActualBenchmarkRatio__c, EBH_Benchmark__c From EBH_Clinics__r Where EBH_DriverName__r.Order__c <> null Order By EBH_DriverName__r.Name),(Select CreatedDate, EBH_SiteIDText__c, EBH_RelevancyScore__c, EBH_ActionDescription__c, EBH_SiteID__c From EBH_NBAs__r order by EBH_RelevancyScore__c desc limit 5) From Account Where Id=:sellerId';
     /*** NK: 04/07/2018: SellerHealthSummaryController --- END ******************************************************************************/
     /*** NK: 15/08/2018: BoBTriggerHandler --- START ******************************************************************************/
     public final static String SOQL_BOB_SELLER ='Select (Select Previous_Status__c,Status__c,BoB__c,Seller__c, Active__c,BoB__r.EBH_BOBCNTRY__c,BoB__r.EBH_BOBVertical__c,EBH_BOBSegment__c,BoB_Subsegment__c  From BoB_Sellers__r Where Id IN :setBSId) From Account Where Id IN:setSellerId';
     public final static String SOQL_BOB_WITH_CHILDREN = 'Select Id,Seller__c,BoB__c From BoB_Seller__c Where BoB__c IN:setBoBIds';
     public final static String BOB_STATUS_ACTIVE = 'BoB Active';
     public final static String BOB_SELLER_STATUS_NEW = 'New';
     public final static String BOB_SELLER_STATUS_DRAFT = 'Draft';
     public final static String BOB_STATUS_SUBMITTED = 'Submitted';
     public final static String SOQL_BOB_BY_COUNRY_VERTICAL = 'Select Id,Status__c From BoB__c Where Id NOT IN :setBobIds AND EBH_BOBVertical__c IN :setBobVertical AND EBH_BOBCNTRY__c IN :setBobCounry AND EBH_BOBVertical__c<>NULL AND EBH_BOBCNTRY__c <> NULL ';
     public final static String BOB_STATUS_INACTIVE = 'BoB Inactive';
     public final static String SOQL_BOBSELLER_BY_BOB_AND_SELLER = 'Select Id,BoB__c,BoB__r.Name,BoB__r.OwnerId,BoB__r.EBH_BOBCNTRY__c,Seller__c,Seller__r.Name,Seller__r.EBH_OracleID__c from BoB_Seller__c Where BoB__c IN :setBoBIds AND Seller__c IN :setSellers';
     public final static String SOQL_BOBSELLER = 'Select EBH_BOBSegment__c,BoB_Subsegment__c,Status__c,Previous_Status__c,Id,Account_Manager__c,Account_Manager__r.Name,BoB__c,BoB__r.Name,BoB__r.EBH_BOBVertical__c,BoB__r.OwnerId,BoB__r.Owner.Name,BoB__r.EBH_BOBCNTRY__c,Seller__c,Seller__r.Name,Seller__r.EBH_OracleID__c from BoB_Seller__c ';
     public final static String SOQL_BOBSELLER_CHECK_BOB_ACTIVE = 'Select  BoB__r.OwnerId,BoB__r.Owner.Name, Id,BoB__c,BoB__r.Name,Seller__c,Seller__r.Name from BoB_Seller__c WHERE BoB__c NOT IN :setBoBIds AND Seller__c IN :setSellers';
     public final static String SOQL_BOB = 'Select (Select Id From BOBs__r limit 1),BoB_New_In_Confirm_Date__c,BoB_Removal_Confirm_Date__c,Id,Name,Status__c,EBH_BOBVertical__c,EBH_BOBCNTRY__c,Date_Activated__c,BoB_Cohort__c,OwnerId,Owner.Name,Owner.Email From BoB__c Where Id=:parentId';
     public final static String SOQL_BOB_SELLER_VIEW = 'Select SWL_Volume_Request__c,SWL_GMV_Request__c,Store_Subscription_Request__c,Free_Store_Request__c,Set_business_policies__c,Previous_Status__c,Active__c,Parent_Seller__c,Parent_Seller__r.Name,Id,Seller__c,Seller__r.Name,Oracle_Id__c,EBH_BOBSegment__c,BoB_Subsegment__c,Account_Manager__c,Account_Manager__r.Name,Status__c,LastModifiedDate From BoB_Seller__c Where BoB__c =:parentId';
     public final static String SOQL_BOB_SELLER_VIEW_SORT = '  order by Parent_Seller__r.Name asc';//' order by createddate desc';
     public final static String SOQL_BOB_CAT_LEAD='Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'BoB_Category_Lead\') AND AssigneeId=:currentUserId  limit  1';
     public final static String BOB_GROUP_GCX_LEADS = 'BOB_GCX_Leads';
     public final static String BOB_GROUP_BOB_FINANCE = 'BoB_Finance';
     public final static String BOB_GROUP_BOB_GCX_OPERATIONS = 'GCX_Operations';
     public final static String SOQL_GROUP_MEMBER = 'Select UserOrGroupId, Group.DeveloperName, GroupId From GroupMember Where Group.DeveloperName IN:setGoups';
     //NK:11/06/2024:US-0015255
     public final static String SOQL_BOB_USER_BY_COUNTRY  = 'Select Id,Name,Email From User Where Id IN:setUserId ';
     public final static String SOQL_BOB_USER_BY_ID  = 'Select isActive,Id,Name,Email From User Where Id IN:setUserId';
     public final static String SOQL_BOB_EMAIL_TEMPLATE = 'Select  Id,Subject,HtmlValue from emailTemplate where DeveloperName=:templateName';  
     public final static String SOQL_BOBSELLER_COUNT = 'Select Count() From BoB_Seller__c Where BoB__c =:parentId ';
     public final static String OFFSET_LIMIT =  ' limit :recordLimit offset :myOffSet ';
	 public final static String SOQL_BOB_BY_COUNTRY_VERTICAL = 'Select Id,RecordTypeId,LTTM_Group__c,EBH_BOBCNTRY__c,EBH_BOBVertical__c,Name,OwnerId,Owner.Name From BoB__c Where ((EBH_BOBCNTRY__c IN:setBoBCountry AND EBH_BOBVertical__c IN:setBoBVertical AND Status__c IN:bobStatusDupCreateCheck AND recordtypeId =:recTypeManageId) OR (EBH_BOBCNTRY__c IN:setBoBCountry AND EBH_BOBVertical__c IN:setBoBVertical AND LTTM_Group__c <> null AND LTTM_Group__c IN:setBoBLttmGroup AND recordtypeId =:recTypeLTTMId))';
     public final static Integer BOBSELLER_LIMT_VIEW = 30;
	 public final static Map<String,String> MAP_CODE_TO_COUNTRY  = new Map<String,String>{
     	'3'=> 'UK','77'=> 'DE','71'=> 'FR','101'=> 'IT','186'=> 'ES','163'=> 'PL','99'=> 'IE','193'=> 'CH','146'=> 'NL','23'=> 'BE','168'=> 'EEC-Unsited','15'=> 'AU'
     };
	 public final static String INTEGRATION_USER_ID = '0056A000000zaxM';
     /*** NK: 15/08/2018: BoBTriggerHandler --- END ******************************************************************************/
     public final static String BOB_SELLER_STATUS_REMOVED = 'Removed'; //DHE 2018-08-16
    public final static String BOB_SELLER_STATUS_SUBMITTED = 'Submitted'; //DHE 2018-08-16
    //public final static String CAMPAIGN_CHANNEL_PHONE_OUTREACH='GCX Outreach (Phone)';
    public final static String CAMPAIGN_CHANNEL_PHONE_OUTREACH='Phone Outreach';
    public final static String JOURNEY_STATUS_PUBLISHED = 'Published';
    /*DHE: 21-08-2018*/
    public final static String SOQL_GCX_TEAM_LEAD='Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'GCX_Super_User\') AND AssigneeId=:currentUserId  limit  1';
    public final static String GCX_TASK_TYPE='Phone Outreach';
    public final static String GCX_TASK_DESCRIPTION='Phone Outreach';
    Public final static String GCX_TASK_CALL_TYPE='Outbound'; 
    public final static String GCX_TASK_CALL_CHANNEL='GCX Outreach (Phone)';
    /*DHE: 25-10-2018 EPH-6581*/
    public final static String RECORDTYPE_DWH='DWH';
    /*NK: 19-11-2018 EPH-6636*/
    public final static String PROFILE_ID_STANDARD='00e6A000000hSSQQA2';
	public final static String CAMP_RECORDTYPE_OUTREACH='EBH_AMOutreach';
	public final static String CAMP_RECORDTYPE_OUTREACH_ID='0126A0000009qNBQAY';
	public final static String CAMP_CHANNEL_GCXINBOUND_PHONE ='GCX Inbound (Phone)';
    public final static String CAMP_CHANNEL_AM_OUTREACH = 'AM Outreach';
    public final static String PROFILE_ID_MARKETING='00e6A000000hSSPQA2';
    public final static String PROFILE_ID_BIZADMIN='00e6A000000hSSOQA2';
    public final static String CAMP_RECORDTYPE_REQUEST_ID='0126A000000M9xOQAS';
    public final static String CAMP_STATUS_DRAFT = 'Draft';
    public final static String CAMP_STATUS_REQUEST_SUBMITED = 'Submitted';
    public final static String CAMP_STATUS_PAUSED = 'Campaign Paused';
    public final static String TASK_STATUS_PAUSED = 'Paused';
    public final static String TASK_STATUS_CANCELLED = 'Cancelled';
    public final static String SOQL_TASK = 'Select EBH_ResponseCode__c,Campaign_related_Seller_Details__c, OwnerId,Owner.Name,Survey_ID__c,IsClosed,Id,EBH_CampaignMemberId__c,WhatId,WhoId,Status,Order_Priority__c,EBH_Response__c,Call_attempts__c From Task ';
    public final static String CAMP_RECORDTYPE_MASTER_ID = '0126A000000M9xMQAS'; 
    public final static String CAMP_RECORDTYPE_SUB_ID = '0126A000000M9xEQAS';
    /*TH: 28/12/2018 EPH-6915*/
    //public final static String MARKETINGTICKET_RECORDTYPE_COPY_CREATIVE_ID = '0126A000000TFMuQAO'; 
    //public final static String MARKETINGTICKET_RECORDTYPE_JOURNEY_ID = '0126A000000TFMvQAO'; 
    //public final static String MARKETINGTICKET_RECORDTYPE_TARGETING_ID = '0126A000000TFMwQAO'; 
	public final static String SOQL_CAMP_TARGET_SELLERLIST = 'Select CreatedDate,Id,Campaign__c,Campaign__r.EBH_MemberLastRefreshDate__c,Seller_List__c From Campaign_Targeting__c';
	public final static Integer RETRY_ASYN_JOB_LIMIT = 5; //retry in que job if failed	
	public final static String CONTACT_RECORDTYPE_DWH_ID = '0126A000000T3OOQA0';
    public final static String SOQL_ACCOUNT_CONTACTS = 'Select Id,(Select Id,Name,Primary_Contact__c,RecordtypeId From Contacts) From Account ';
    //NK:09/01/2019
    public final static String SOQL_TARGETING_ENGINE = 'Select Id,Name,EBH_TE_Expiration_Date__c,RecordTypeId,RecordType.DeveloperName From EBH_Filter__c ';
    //DH: 10/01/2019
    PUBLIC final static Integer NUMBER_OF_CALL_ATTEMPTS_TO_BE_CONSIDERED_NOT_REACHED=3;
    public final static String RESPONSE_CODE_NOT_REACHED = '55';
    //DHE 11/01/2019
    public final static String OUTREACH_SURVEY = 'ClickTools';
    //NK:16/01/2019
    public final static String GROUP_MARKETING_EXC = 'Marketing_Execution_Team';
    public final static String TICKET_PERMISSIONSET_MARKETING_EXC_TEAM = 'Marketing Execution Team';
    // DHE 16/01/2019
    public final static String GCX_SUPER_USER='GCX Super User';
    public final static String SOQL_GCX_FILL_GROUP='Select  AssigneeId From PermissionSetAssignment  where PermissionSet.Name IN (\'GCX_Super_User\')';
    public final static String SOQL_GET_GCX_PUBLIC_GROUP='Select id from group where name=\'GCX Super User\' limit 1';
    public final static String SOQL_GET_CURRENT_GROUP_ASSIGNATIONS='select id, groupid, userorgroupid from GroupMember where group.name=\'GCX Super User\'';
    public final static String SOQL_GET_MEMBERS_OF_GCX_SUPER_USER_GROUP='select id, groupid, userorgroupid from GroupMember where group.name=\'GCX_SUPER_USER\'';
    //TH 18/01/2019
    public final static String COMPETENCY_COPY = 'Copy';
    public final static String COMPETENCY_CREATIVE = 'Creative';
    public final static String COMPETENCY_JOURNEY = 'Journey';
    public final static String COPETENCY_TARGETING = 'Targeting';
    public final static String COPETENCY_SCRIPTING = 'Scripting';
    public final static String COPETENCY_OTHER = 'Other';
    //DHE 24/01/2019
    public final static map<String,String> MapCountryLanguage = new Map <String,STring>{'de'=>'de','uk'=>'en','es'=>'es','fr'=>'fr','it'=>'it'};   
	//NK:05/02/2019
    public final static  String SOQL_CONTRACT_SELLER = 'Select Id,EBH_BusinessName__c, EBH_ContractNumber__c,EBH_ContractNumber__r.Status From EBH_ContractSeller__c '; 	
	public final static  String OUTREACH_TYPE_MARKETING = 'Seller Marketing';
    public final static  String OUTREACH_TYPE_ADMIN = 'Admin';
	public final static  String CAMPAIGN_CHANNEL_EMAIL = 'Email';
    public final static  String CAMPAIGN_CHANNEL_GCX_OUTREACH = 'GCX Outreach (Phone)';
    // DHE 01/03/2019
    public final static String TASK_QUERY='SELECT Id[PLACEHOLDER],Description FROM TASK WHERE OWNERID =:userID [EXTRA_CLAUSE] ORDER BY Call_Back_Window_start__c DESC nulls last,Field_for_sorting__c ASC, call_attempts__c ASC NULLS FIRST  LIMIT :PageSize OFFSET :PageNumber';
    public final static String TASK_COUNTQUERY= 'SELECT COUNT() FROM TASK WHERE OWNERID =:userID [EXTRA_CLAUSE] LIMIT 2000';
    //NK:07/03/2019
    public final static String PROFILE_GCX_PARTNER = 'GCX Partner Profile';
    public final static String PROFILE_GCX_PARTNER_ID = '00e6A000001o6m4QAA';
    public final static String PERMISSION_SET_COMMUNITY_ANALYTICS_ID = '0PS6A000001p7NzWAI';
    public final static String PERMISSION_SET_LICENSE_COMMUNITYWAVE_ID = '0PL6A000000MD9LWAW';
    public final static String SOQL_GCX_ACCOUNT = 'Select Id From Account Where Name=\'GCX\' AND RecordTypeId=\'0126A000000M9xKQAS\' LIMIT 1';
    //NK:12/03/2019
    public final static String DEAL_STATUS_PLANNED = 'Planned';
    //AMT:14/01/2019
    public final static String SOQL_SUBCAMPAIGN = 'SELECT PriorityOrder__c, Campaign.Survey_ID__c,Campaign_Related_Seller_Details__c,CampaignId, ContactId FROM CampaignMember WHERE Campaign.RecordTypeId =: subCampaignRT AND Campaign.EBH_Channel__c =: GCXOutReachCampChannel AND Campaign.Survey_ID__c != null AND (Campaign.EndDate > TODAY OR Campaign.EndDate = null)';
    public final static String SOQL_TASKINCAMPAIGN = 'SELECT Campaign_related_Seller_Details__c, Order_Priority__c, WhatId, WhoId FROM Task WHERE WhatId IN: sCampaginId';
    //TH  :15/03/2019 EPH-5671 Create Contact Quality Task in Seller Record when Status = red for managed sellers
    public final static String EMAILTEMPLATE_CONTACTDATAUPDATETASKSELLER = 'Contact_Data_Update_Task_for_Seller';
    public final static String SOQL_EMAILTEMPLATE_CONTACTDATAUPDATETASKSELLER = 'Select e.Subject, e.Name, e.HtmlValue, e.DeveloperName, e.Body From EmailTemplate e where DeveloperName = \'Contact_Data_Update_Task_for_Seller\'';
    public final static String SOQL_ACCOUNT_SELLER = 'select id,Name,OwnerId,Owner.Name,Owner.Email,EBH_BOBManaged__c,Contact_Data_Quality__c, (select OwnerId, Incorrect_Phone_Number__c,Name,Email_Bounced__c,RecordTypeId,RecordType.Name From Contacts where Contact_Data_Quality__c = \'Red\' and RecordType.DeveloperName IN (\'EBH_MANUAL\',\'EBH_DWH\') order by RecordType.DeveloperName ASC limit 1) from Account where RecordType.DeveloperName = \'EBH_Seller\' and id IN: listAccounts';
    //DHE 15/03/2019
    public final static string PARTNER_USERROLE ='GCX Partner User';
    //DHE 03/04/2019
    public final static string PARTNER_COMMUNITY_NAME ='gcx';
	//NK:04/04/2019
    public final static String COUPON_SELLER_STAGE_NEGO = 'Contract Negotiation';
    public final static String SOQL_COUPON_SELLER = 'Select RecordType.DeveloperName, Allow_reaccept_contract__c,Advertising_Promotion__c, Day_1_Alert__c, Coupon_Contract_Due_Date__c, Day34AfterCouponEnd_Trigger_DE__c,Day4AfterCouponEnd_Trigger_DE__c,CurrencyIsoCode, Additional_Terms_Override_of_Agreement__c, Ad_Spend_Date__c, Advertising_Amount__c, Contract_Accept_Date__c,Coupon_Seller_Stage__c,Contract_Language__c,GMV_LC__c,Contra_LC__c,Cost_Share_Seller_LC__c,Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Due_Date__c,Free_Subtitles__c,Coupon__r.Max_Redemptions__c,Coupon__r.Owner.Name,EBH_CouponSellerOwner__r.Name,EBH_CouponSellerOwner__c,EBH_CouponSellerOwner__r.Email,Coupon__r.Contract_Language__c,Coupon__r.Coupon_Cap__c,Coupon_ID__c ,Coupon__r.Marketing_Coupon_Name__c,Coupon__r.OwnerId,Coupon__r.Owner.Email,Coupon__r.RecordType.DeveloperName,Coupon__r.CurrencyIsoCode,Additional_Terms__c,Email_Adress__c,Coupon__r.Minimum_Transaction_Value__c,Coupon__r.Name,Legal_Entity_Name_w__c,Legal_Entity_Street_w__c,Legal_Entity_Zip_w__c,Seller__r.Parent.EBH_BillingCountry__c,Seller__r.Parent.EBH_BillingCity__c,Seller__r.EBH_VATNumber__c,Seller__r.Name,Coupon__r.Couponsite_s__c,PayPal_adress_N__c,Coupon__r.Coupon_Start_Time__c,Coupon__r.Coupon_Start_Date__c,Coupon__r.Coupon_end_Time__c,Coupon__r.Coupon_End_Date__c,Coupon__r.Coupon_Discount__c,Coupon__r.Coupon_Discount_Amount__c,Coupon__r.T_Cs_URL__c,Id,Name,Seller__c,Coupon__c,Oracle_ID__c,PayPal_adress__c From Coupon_Seller__c ' ;
	public final static String PERMISSION_SET_PROMO = 'Promotions_User'; 
    public final static String PERMISSION_SET_NIEDITABLE = 'Nominated_Item_Editable'; 
    public final static String SOQL_PERMISSIONSET_ASSIGNMENT = 'Select PermissionSet.Name, PermissionSetId, AssigneeId From PermissionSetAssignment ';
	public final static Set<String> DATA_Q_CREATE_TASK = new Set<String>{'RED','AMBER'};
	//LA: 02/14/2020
	public final static String COUPON_SELLER_STAGE_APPROVED = 'Approved';
	public final static String CONTRACT_LANGUAGE_UK = 'UK';
	public final static String UK_COUPON_APPROVED_OWNER_NOTIFICATION = 'UK_Coupon_Approved_Owner_Notification';
	//TH : 08/04/2019
    public final static String SOQL_SELLER = 'Select Outreach_Manager__c, Coupon_Promotions_Participation__c, Coupon_Promotion_Types__c, Coupon_Discount_Rate__c, Coupon_Funding_Preference__c, Id,EBH_OracleID__c From Account ' ;
    public final static String COUPON_STAGE_DRAFT = 'Draft';
    //DHE : 08/04/2019
    public final static Integer TASK_DEFAULT_RESPONSE_CODE=10;
	// AMT:09-4-19, for get helpText from cross referernce field
    public static final Map<String, Map<String, String>> MAP_TE_FETCH_HELPTEXT = new Map<String, Map<String, String>>{
        'Seller_to_Product__c'  => new Map<String, String>{
                                    // Product
                                    //'Product__r.Brand__c' => 'Product__c',
                                    'Product__r.Vertical__c' => 'Product__c',
                                    //'Product__r.Category_Tree__c' => 'Product__c',
                                    'Product__r.TTP_Rank__c' => 'Product__c',
                                    'Product__r.Competitive_Status_eBay__c' => 'Product__c',
                                    'Product__r.Site__c' => 'Product__c',
                                    'Product__r.Active_TTP__c' => 'Product__c',
                                    'Product__r.Price_eBay_recommended__c' => 'Product__c',
									'Product__r.Total_Sellers_on_eBay__c'=>'Product__c',							//NK:18/05/2019
                                    'Product__r.Total_Sellers_for_Price_Optimization__c'=>'Product__c',
                                    'Product__r.Total_Sellers_for_Re_stocking__c'=>'Product__c',
                                    'Product__r.Total_Sellers_with_Sourcing_Opportunitie__c'=>'Product__c',
                                    // Seller
                                    //'Seller__r.Top_Top_Product_Availability__c' => 'Account', //NK:30/05/2019:EPH-7566: field removed from Account: 
                                    'Seller__r.Top_Top_Products_Competitiveness__c' => 'Account',
                                    'Seller__r.Total_Listings_for_Price_Optimisation__c' => 'Account',
                                    'Seller__r.Total_Listings_to_Re_stock__c' => 'Account',
                                    'Seller__r.Total_Products_to_Source__c' => 'Account'
                                },
        'Sourcing_Opportunity__c'=> new Map<String, String>{
                                    'Range_Based_Sourcing__r.Brand__c' => 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Site__c' => 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Price_Range__c'=> 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Vertical__c'=> 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Meta_Category__c'=> 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Category_L2__c'=> 'Range_Based_Sourcing__c',
                                    'Range_Based_Sourcing__r.Category_L3__c'=> 'Range_Based_Sourcing__c'
                                }
    };
	//TH : 10/04/2019 for Coupon co invest trigger handler
    public final static String SOQL_COUPON_SELLER_2 = 'Select Coupon__r.Seller_Co_funding_share_forecast__c,Coupon__r.Contract_Language__c, Date_4days_Sent__c, Date_34_days_Sent__c, TriggerEmailManhattan__c, Id,Seller__c,Seller__r.EBH_OracleID__c,Coupon__c,Coupon_Seller_Stage__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c,SellerShareHolder__c From Coupon_Seller__c' ;
    public final static String COUPON_CATEGORYBASE = 'Category_Based';
    public final static String COUPON_ITEMBASE = 'Item_Based';
    public final static String CO_INVEST_SELLER = 'Coupon_Co_Invest_Seller';
    public final static String CO_INVEST_CATEGORY = 'Coupon_Co_Invest_Category';
    public final static String CO_INVEST_ITEM = 'Coupon_Co_Invest_Item';
    public final static String COUPON_SELLER_NEGOTIATION_STAGE = 'Seller Negotiation';
    	
	//Loumang:US-0010777: add new SOQL_COUPON and cmt SOQL_COUPON because have to removed field Sellers_Targeted__c from 
    public final static String SOQL_COUPON = 'select Trigger34DayAfterEndDate__c,Trigger4DayAfterEndDate__c,OwnerId,Contract_Language__c, Coupon_ID__c, Days_since_coupon_End_Date__c, Coupon_Source__c, Couponsite_s__c, Coupon_Start_Date__c, Coupon_End_Date__c, Sellers_Targeted2__c, Owner.Name, Owner.Email, RecordTypeId, id,Seller_Co_funding_share_forecast__c from Coupon__c';
    //public final static String SOQL_COUPON = 'select Trigger34DayAfterEndDate__c,Trigger4DayAfterEndDate__c,OwnerId,Contract_Language__c, Coupon_ID__c, Days_since_coupon_End_Date__c, Coupon_Source__c, Couponsite_s__c, Coupon_Start_Date__c, Coupon_End_Date__c, Sellers_Targeted__c, Owner.Name, Owner.Email, RecordTypeId, id,Seller_Co_funding_share_forecast__c from Coupon__c';
	public final static String SOQL_COUPONCATEGORY = 'select Exception_Category__c,Category__c,Category__r.Name,Category_ID__c,Category_Level__c,Coupon__c,Coupon__r.RecordTypeID,Coupon__r.RecordType.DeveloperName,Coupon__r.Stage__c from Coupon_Category__c';
	public final static String SOQL_COUPONITEM = 'select id,Coupon_Seller_ID__c,Seller_Share__c,Coupon_Seller_ID__r.Coupon_Seller_Stage__c,Coupon_Seller_ID__r.Coupon__r.RecordType.DeveloperName,Coupon_Seller_ID__r.Coupon__r.Stage__c,Item_ID__c from Coupon_Item__c';
	public final static String SOQL_COUPONCOINVEST = 'select Seller_Funding__c, Coupon_Name__c,OwnerId, Coupon_Seller__r.Coupon_Seller_Stage__c,Coupon_Seller__r.Coupon__r.Contract_Language__c,id,Site__c,Category__c,Category_ID__c,Co_Invest__c, Item_ID__c, Coupon_Seller__c, Coupon_Category__c from Coupon_Co_Invest__c';
	//NK:11/04/2019
	public final static String TARGETING_ENGINE_RECTYPE_TRADING = 'Snapshot_Seller_List_Trading_Engine';
	//TH : 13/05/2019
	public final static String SOQL_SELLER_TO_PRODUCT = 'Select Product__r.Product_Link_2_auto__c,Product__r.Product_Link_2__c,Price_Main_Competitor__c,eBay_Item_Link_auto_h__c,eBay_Item_Link_auto__c,Product__r.Update_Date__c,Update_Date__c,Price_Difference_seller_vs_competitor__c,Product__r.Vertical__c,Product__r.Name,Name,Product__r.Price_competitor_2__c,Category_L3__c,Brand__c,Product_Brand__c, Seller__c,Seller__r.Name,Listing_ID__c,eBay_Link__c,EPID__c,Product__r.Price_competitor__c,Product__r.eBay_Product_Link__c,Product__r.EAN__c,Product__r.Product_ID__c,Listing_Title__c,Take_Rate__c,Price_seller__c,Id From Seller_to_Product__c';
	public final static String FVF_LISTING_RECORDTYPE = 'FVF_Listing_Level';
	public final static String FVF_SELLER_RECORDTYPE = 'FVF_Seller_Level';
	//NK: 14/05/2019
	public final static Integer ITEM_PER_TRANS = 1000; //NK:15/05/2020: 5k -> 1k : US-0007195
	public final static String SOQLEMAIL_TEMPLATES = 'Select Body,Id,DeveloperName,Subject,HtmlValue from emailTemplate ';
	public final static String COUPON_SELLER_STAGE_CONTRACT_SEND ='Contract Send';  
	public final static String COUPON_SELLER_STAGE_CONTRACT_SIGNED= 'Contract Signed';
	public final static String EMAIL_COUPON_CONTRACT_DE_ITEM = 'DE_Item_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_DE_CAT ='DE_Category_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_FR_CAT ='FR_Category_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_FR_ITEM ='FR_Item_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_UK_ITEM = 'UK_Item_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_UK_CAT ='UK_Category_Coupon_Contract';
	public final static String EMAIL_COUPON_CONTRACT_AU ='AU_Coupon_Contract_Template';
	public final static String EMAIL_COUPON_ITEM_CONTRACT_AU ='AU_Coupon_Contract_Item_Template';
	public final static String PERMISSION_SET_FVFAPPROVAL = 'Final_Value_Fee_Approval';
	//AMT : 18/05/2019 EPH-7407
    public final static String DEAL_QUERY = 'SELECT EBH_DealStartDate__c, EBH_LocalDealFormat__c, EBH_ProductTitle__c, EBH_DealSiteId__c, toLabel(EBH_DealSiteId__c)SiteLabel, EBH_Status__c, Invoice_Comment_From_Seller__c, Invoice_Number__c FROM EBH_Deal__c WHERE Id =: dealId';
    public final static String DEAL_STATUS_VERIFY_INVOICE = 'Verify Invoice';
    public final static String DEAL_STATUS_CLARIFICATION_REQUIRED = 'Clarification Required';
	public final static String FVF_STAGE_EBAY_APPROVED = 'eBay Approved';
	public final static String FVF_STAGE_CONTRACT_SENT = 'Contract Sent';
    public final static String FVF_STAGE_EBAY_SENT_TO_APPROVE = 'Sent_to_eBay_Approval';
    public final static String SOQL_FVF = 'Select FVF_Campaign__c,Site__c,Total_Number_of_Sellers__c,Total_Number_of_Listings_fvfcampaign__c,Campaign_Name__c,Contract_Send_Date__c,Requestor__c,Requestor__r.Name,Requestor__r.Email,Legal_Entity_Name__c, Legal_Entity_Street__c, Legal_Entity_Zip__c, Legal_Entity_Country__c,Seller_Name__r.Parent.EBH_BillingCity__c, Total_Number_of_Listings__c, Business_Reason__c, Free_shipping__c, Seller_Name__r.EBH_BillingStreet__c, Seller_Name__r.EBH_BillingCity__c, Seller_Name__r.EBH_BillingPostalCode__c, Seller_Name__r.EBH_BillingCountry__c, Seller_Name__r.EBH_ParentAccount__c,Seller_Name__r.ParentId,Seller_Email__c,Rev_RollUp__c,Owner.Email,Start_Time__c,Start_Date_w__c,End_Time__c,End_Date_w__c,Discount_FVF__c,Additional_Terms__c,RecordType.DeveloperName,Contact_Person__c,Contact_Person__r.Name,Contact_Person__r.Email,Id,Name,Final_Value_Fee_Stage__c,Owner.Name,OwnerId,Seller_Name__r.Name,Seller_Name__c,Seller_Name__r.EBH_OracleID__c,Seller_Name__r.EBH_VATNumber__c,Seller_Name__r.EBH_RegistrationCountry__c,Seller_Name__r.EBH_BillingAddress__c,Seller_Name__r.EBH_CompanyName__c, Seller_Name__r.EBH_RevRollup__c,Budget_estimated_w__c,Budget_Manually_Estimated__c From Final_Value_Fee_FVF__c ';
	public final static String COMPETITIVE_STATUS_SELLER_UN = 'Uncompetitive';
	public final static String COMPETITIVE_STATUS_SELLER_COMPETE = 'Competitive';
	public final static String COMPETITIVE_STATUS_OUTOF_STOCK= 'Inventory - Out of stock';
	//AMT : 12/06/2019 EPH-7607
    public final static String QUERY_PRIMARYCONTACT_ACCOUNT = 'SELECT Primary_Contact__c,Primary_Contact__r.Email FROM Account WHERE Primary_Contact__c != null AND Id IN: sSellerId';
    public final static String QUERY_ACCOUNT_CONTACT = 'SELECT Email, AccountId FROM Contact WHERE AccountId =: sSellerId AND RecordType.DeveloperName = \'EBH_DWH\'';
	//TH : 13/06/2019 EPH-EPH-7482
	public final static String SOQL_CONTACT = 'Select c.Id, c.Phone, c.Name, c.LastName, c.FirstName, c.EBH_Status__c, c.RecordType.DeveloperName, c.RecordTypeId, c.Email, c.EBH_Decision_Maker_Role__c, c.Primary_Contact__c, c.AccountId From Contact c';
	public final static String DECISION_MAKER_ROLE = 'Coupons';
	public final static String CONTACT_RECORDTYPE_DWH = 'EBH_DWH';
	public final static String CONTACT_STATUS_INACTIVE = 'Inactive';
	public final static String CONTACT_STATUS_ACTIVE = 'Active';
	//AMT : 21/06/2019 EPH-7591
    public final static String QUERY_ACCOUNTEROWNER_FROMSELLER = 'SELECT Outreach_Manager__c, OwnerId FROM Account WHERE Id IN: sSellerId';
	public final static String 	DEAL_STATUS_STATEMENT_VERIFIED = 'Statement Verified';
	public final static String DEAL_INVOICE_STATUS_READY_PAYMENT = 'Ready for Payment';
	public final static String DEAL_INVOICE_STATUS_REJECTED  = 'Invoice Rejected';
	public final static String 	DEAL_STATUS_READY_PAYMENT = 'Ready for Payment';
	public final static String 	DEAL_STATUS_INV_REJECT = 'Invoice Rejected (Email resend to Seller)';
	//TH: 25/06/2019 EPH-7467 Deal Budget -Object - Redesign
	public final static String SOQL_DEAL = 'Select EBH_MarketingTitle__c,EBH_CommentfromeBaySourcer__c,Subsidy_Planned_Gross__c,EBH_SellerPrice__c,CompanyName__c,EBH_BusinessName__r.Name, EBH_BusinessName__r.ParentId,EBH_BusinessName__r.EBH_ParentAccount__c,EBH_BusinessName__r.EBH_VATNumber__c,EBH_BusinessName__r.Parent.EBH_BillingStreet__c,EBH_BusinessName__r.Parent.EBH_BillingCountry__c,EBH_BusinessName__r.Parent.EBH_BillingPostalCode__c,EBH_BusinessName__r.Parent.EBH_BillingCity__c,EBH_MaximumPurchases__c, EBH_Quantity__c,EBH_RRPWASPrice__c,EBH_DealPrice__c,EBH_EAN__c,Additional_Terms_Override_Of_Agreement__c, Shipping_Rate_Funding__c,EBH_BusinessName__c, EBH_DealStartTime__c, EBH_DealEndTime__c, EBH_SpotlightCategory__r.Active__c,EBH_SpotlightCategory__c,EBH_SpotlightCategory__r.Name,NumberOfDaysSinceDealEnd__c,EBH_Status__c,Id,Owner.Email,EBH_SellerEmail__c,VAT_N__c,Subsidy_Final_Net__c,EBH_Subsidy__c,EBH_Payout_SI_calc__c,EBH_LocalDealFormat__c,EBH_eBayItemID__c,EBH_ProductTitle__c,EBH_DealSiteId__c,EBH_DealStartDate__c,EBH_DealEndDate__c,EBH_StartDateMonthYear__c,EBH_Vertical__c, Subsidy_Running__c, EBH_SubsidyForecast__c, EBH_SubsidyFinal__c, EBH_SubsidyMax__c From EBH_Deal__c ';
	public final static String SOQL_DEALBUDGET = 'Select EBH_Vertical__c,Deal_Site__c,Non_Payout_Items_Estimate__c,e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Forecast__c, e.Subsidy_Final__c,EBH_Quarter__c,Year__c From EBH_DealsBudget__c e';
	public final static String SOQL_DEALBUDGETMONTH = 'Select e.EBH_DealsBudget__r.Deal_Site__c, e.EBH_DealsBudget__r.EBH_Vertical__c, e.Subsidy_Running__c, e.Subsidy_Planned__c, e.Subsidy_Final__c, e.EBH_SubsidyForecast__c, e.EBH_MonthYear__c, e.EBH_DealsBudget__c From EBH_DealsBudgetMonth__c e';
	public final static String SOQL_PRODUCT_STPRODUCT = 'Select Id,(Select Id From Seller_to_Products__r %where1%) From Product__c ';
	public final static String SOQL_AGGR_COUNT_SELLER_TO_PRODUCT = 'Select Product__c,count(Id) rowCount From Seller_to_Product__c ';
	public final static String SOQL_SPOTLIGHT_CAT = 'Select Active__c,EBH_Country__c,Spotlight_Start_Date__c,Spotlight_End_Date__c,Id,Name,EBH_SpotlightCategoryID__c From EBH_SpotlightCategory__c';
	public final static String SOQL_SOPP = 'Select Product__r.eBay_Product_Link__c, Product__r.Price_competitor__c,Update_Date__c,Product__r.Vertical__c,Id,Brand__c,Name,Category_L3__c,Product__r.Category_Tree__c,Product__r.Category_Tree__r.Name,Product__c,Product__r.Name,Product_Title__c,Product__r.Price_competitor_2__c,Product__r.EAN__c,Seller__c,Seller__r.Name From Sourcing_Opportunity__c ';  
	//TH : 22/07/2019 EPH-7767 FVF Approval Process
	public final static set<String> SET_REV_ROLLUP = new set<String>{'DE','FR','IT','ES'};
	public final static String UK_REV_ROLLUP = 'UK';
	//TH : 24/07/2019 EPH-7723 Coupon Object - csv file + download functionality for BCD
	public final static String SOQL_COUPONSELLER_FOR_BCD = 'select Cost_Share_Seller_LC__c,External_ID__c, Provider_ID__c, Currency__c, Cost_Share_Seller__c,CurrencyIsoCode,Seller__c,Coupon__c,Coupon__r.ID_Type__c,Coupon__r.Invoice__c,Coupon__r.Transaction_Type__c,Coupon__r.Credit_type__c,Coupon__r.Reason__c,Coupon__r.Memo__c from Coupon_Seller__c';
	//NK:29/07/2019
	public final static String SOQL_NOMINATED_ITEMS = 'Select Max_Price_During_Promotion__c,Id,Name,Listing_Name_w__c,Listing_ID_w__c,Price_target_w__c,Discount_FVF_w__c,Final_Value_Fee_FVF__c From Nominated_Item__c ';
	public final static String FVF_STAGE_CONTRACT_SIGNED = 'Contract Signed';
	//TH: 30/07/2019 EPH-7725 Send BCD file via email to Finance DL after Coupon ended
	public final static String BCD_EMAIL_TEMPLATED_NAME = 'BCD_File_Email_Coupon_Manhattan';
	//TH: 31/07/2019 EPH-7565 Coupon - Manhattan Invoice Statment send to coupon seller
	public final static String DE_INVOICE_4Days_EMAIL_TEMPLATED_NAME = 'DE_Coupon_Invoice_Statement_4_days_after_Coupon_End_date';
	public final static String DE_INVOICE_34Days_EMAIL_TEMPLATED_NAME = 'DE_Coupon_Invoice_Statement_34_days_after_Coupon_End_date';
	//TH: 21/08/2019 EPH-7879 "Open Related Tasks” and "Completed Related Tasks" tab in Task Detail Page
	public final static String TASK_STATUS_COMPLETED = 'Completed';
	public final static String SOQL_TASK1 = 'select Campaign_Priority__c, Campaign_Group__c, Action_Committed__c, Action_Outcome__c, Action_Outcome_Date__c, Description, Subject, WhatId,What.Name, WhoId,Who.Name,OwnerId,Owner.Name,Order_Priority__c,Task_Completed_Date__c, EBH_fResponseCode__c, EBH_Response__c, Call_Back_Comments__c From Task';
	//TH : 22/08/2019 EPH-7880 Coupon Seller - Block any user to set stages running, executed, staements send (i.e. fields that are updated by Trigger)
	public final static String COUPON_ERROR_MSG = 'User unable to change Coupon stages manually';
	public final static String COUPON_SELLER_ERROR_MSG = 'User unable to change Coupon Seller stages manually';
    //AMT: 21/08/2019 EPH-7896 Coupon Seller and Coupon Co-Invest - Take the Currency value from related Coupon Object
    public final static String COUPON_COINVEST_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM Coupon_Co_Invest__c ';
    public final static String COUPON_SELLER_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM Coupon_Seller__c ';
    public final static String COUPON_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM Coupon__c ';
    public final static String SOQL_ORG_EMAIL = 'SELECT Id, DisplayName, Address From OrgWideEmailAddress ';
    public final static String COUPON_SELLER_STAGE_RUNNING = 'Coupon Running';
    public final static String COUPON_SELLER_STAGE_EXEC = 'Coupon executed';
    public final static String COUPON_SELLER_STAGE_DECLINED = 'Seller Declined'; 
    public final static String DEAL_STATUS_EXEC = 'Executed'; 
    public final static String DEAL_STATUS_VERIFY = 'Verify Statement'; 
    //TH: 20/09/2019 US-0015702 Coupon Object - BCD File (add missing fields)
    public final static set<String> COUPON_SELLER_STAGE = new set<String>{'T4 Statement Send','T34 Statement Send'}; 
    public final static String COUPON_SELLER_STAGE_T4 = 'T4 Statement Send'; 
    public final static String COUPON_SELLER_STAGE_34 = 'T34 Statement Send'; 
    //SRM: 20/09/2019 US-0009431 User creation ticket process enhancement
    public final static String TICKET_USER_TYPE_LICENSE = 'Full License User'; 
    public final static String TICKET_USER_TYPE_PORTAL = 'GCX Portal User';
    public final static String TICKET_AU_PROFILE = 'AU Standard User Profile';
    public final static String TICKET_STANDARD_PROFILE = 'Standard User Profile';
    public final static String TICKET_GCX_PROFILE = 'GCX Partner Profile';
    public final static String TICKET_COUNTRY_AU = 'AU';
    //DHE 25/09/2019 getting ebay images
    public final static String DEALS_IMAGES_ITEM='Item';
    public final static String DEALS_IMAGES_ITEMID='ItemID';
    public final static String DEALS_IMAGES_GALLERYURL='GalleryURL';
    public final static String DEALS_IMAGES_PICTUREURL='PictureURL';
    public final static String EMAIL_TEMPLATE_CS_T4_DE =  'DE_Coupon_Invoice_Statement_4_days_after_Coupon_End_date';
    public final static String EMAIL_TEMPLATE_CS_T34_DE = 'DE_Coupon_Invoice_Statement_34_days_after_Coupon_End_date';
	public final static String JOB_STATUS_NEW = 'New';
	public final static String JOB_STATUS_PREP = 'Preparation';
	public final static String JOB_STATUS_PROGRESS ='In Progress';
	public final static String JOB_STATUS_SUCCESS	='Complete Success';
	public final static String JOB_STATUS_FAILED ='Complete Failed';
	public final static String JOB_STATUS_NOTSTART ='Not Start';
    //AMT: 04/10/2019 US-0015694
    public final static String CAMPAIGN_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM Campaign ';
    public final static String CONTACT_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM Contact ';
    public final static String EBH_PROJECT_SQL = 'SELECT Id,[EXTRA_CLAUSE] FROM EBH_Project__c ';
    //SRM: 10/10/2019 US-0015722
    public final static String SOQL_FINAL_VALUE_FEE = 'SELECT Id, RecordType.DeveloperName, Total_Number_of_Listings_fvfcampaign__c, Total_Number_of_Sellers__c, Requestor__c, OwnerId,Discount_FVF__c from Final_Value_Fee_FVF__c';
    //TH : 23/10/2019
    public final static String PERMISSION_SET_MSO = 'MSO_Permission';
    public final static String SOQL_GCX_USER = 'Select Id,Name,Campaign_Name__c,User_Name__c,Active__c From GCX_User__c ';
    //TH : 24/10/2019 US-0009403 Deals Invoice VAT - Rejection Email template localization for UK, FR, IT & ES
    public final static String EMAILTEMPLATE_ES_DEAL_INVOICE_REJECT = 'ES_Deal_Invoice_Reject';
    public final static String EMAILTEMPLATE_UK_DEAL_INVOICE_REJECT = 'UK_Deal_Invoice_Reject';
    public final static String EMAILTEMPLATE_IT_DEAL_INVOICE_REJECT = 'IT_Deal_Invoice_Reject';
    public final static String EMAILTEMPLATE_DE_DEAL_INVOICE_REJECT = 'DE_Deal_Invoice_Reject';
    public final static String EMAILTEMPLATE_FR_DEAL_INVOICE_REJECT = 'FR_Deal_Invoice_Reject';
    public final static String SOQL_LEAD2 = 'SELECT isapproved__c, Converted_Date__c, Name, Salutation, RecordTypeId, RecordType.DeveloperName, Company, eBayID__c, EBH_OracleID__c, LeadSegment__c, LeadSource, OtherLeadSource__c, Campaign__c, VAT_Number__c, FirstName, LastName, Title, Email, Phone, MobilePhone, EBH_PreferredContactTime__c, Street, City, Country, PostalCode, State, Website, EBH_OtherMarketplaces__c, OnlineRank__c, EBH_CommentsBusinessReview__c, ShippingTechnology__c, TheoreticalRevenue__c, Site__c, EBH_Vertical__c, Status FROM Lead ';
    public final static String LEAD_STATUS_QLY = 'Qualified';
    //SRM : 15/11/2019 US-0015725 Attach csv tempaltes for FVF
    public final static String DOC_NAME_LISTING = 'FVF_LISTING_NOMINATED_ITEM';
    public final static String DOC_NAME_PRODUCT = 'FVF_PRODUCT_NOMINATED_ITEM';
    public final static String SOQL_DOC = 'SELECT Id FROM Document';
    //TH : 18/11/2019 US-0018863 Deals - Masterschedule - Extend Deal Trigger (Assign Deal Record to Dealsslot Record)
    public final static String DEAL_FORMAT_PRIMARY = 'Primary';
    public final static String SOQL_DEAL_SLOT_ALLOC = 'Select Id,Name,EBH_Date__c,EBH_DealFormat__c,EBH_Country__c,EBH_AcceptProposalsEnd__c,EBH_AcceptProposalsStart__c,EBH_Category__c,EBH_Description__c,EBH_DealSlotDisabled__c,EBH_DealTitle__c,EBH_OpenSeatsAvailable__c,EBH_Slots__c,EBH_Vertical__c,toLabel(EBH_Vertical__c) vertical From EBH_DealSlotAllocation__c ';
    //SRM : 22/11/2019 US-0018858 Deals - Masterschedule - Batch Process for Deals Slot Record Creation
    //AMT : This use to define coupon-seller stage order number
    public final static Map<String, Integer> COUPONSELLER_STAGE_ORDER = new Map<String, Integer>{
        'Targeted' => 1,
        'Reached' => 2,
        'Commited' => 3,
        //'Negotiation' => 4, Updated by AMT: 19-12-19, Coupon Seller Stage Label: Negotiation, API Name: Contract Negotiation
        'Contract Negotiation' => 4,
        'Approved' => 5,
        'Contract Send' => 6,
        'Contract Signed' => 7,
        'Coupon Running' => 8,
        'Coupon executed' => 9,
        'T4 Statement Send' => 10,
        'T34 Statement Send' => 11,
        'Invoice paid' => 12,
        'Seller Declined' => 13
    };
    //AMT : 12/December/2019 US-0005984
    public final static String COUPONSELLER_SOQL = 'SELECT Coupon_Seller_Stage__c, Negotiation_End_Date__c, EBH_CouponSellerOwner__c, Coupon__r.Contract_Language__c FROM Coupon_Seller__c ';
    public final static String PERMISSION_COUPONSPECIALPERMISSION = 'Coupon_Special_Permission';
    public final static String MSG_SELLERFUNDINGLOCKED =  'Seller Funding Share is locked for any changes.';
    public final static String MSG_SELLERFUNDINGLOCKED_SENTAPPROVAL =  'Seller Funding Share is locked from editing as it is sent for Approval';
    public final static String COUPONSELLER_STAGE_APPROVED = 'Approved';
    //public final static String DIMANNO_ISABELLA_EMAIL  = 'idimanno@ebay.com';
    public final static String SELECTUSER_BYROLE  = 'SELECT Email, UserRoleId, UserRole.Id, UserRole.Name FROM User ';
    public final static String HEADOFHARDVERTICALS_ROLE = 'Head of Hard Verticals';
    public final static String CPN_APPR_EMAILNOTIFI_TO_CAT_GROW_MANGR_EMAILTEMPLATE = '_Coupon_Approval_Email_Notification_to_Category_Growth_Manager';
    //public final static String ISAUPROFILE = '00e3u000000S5nxAAC';
    //TH: 24/Dec/2019
    public final static String EMAILTEMPLATE_AU_WIHT_SUBSIDY = 'AU_Deal_Template_with_Subsidy';
    public final static String EMAILTEMPLATE_AU_WIHTOUT_SUBSIDY = 'AU_Deal_Template_without_Subsidy';
    //TH : 26 Dec 2019 : US-0006886 [AU] Approval Process for eBay AU SMB Project with lead Source "Self Gen"
     public final static String LEAD_SOURCE_SELF_GEN = 'Self Gen';
     public final static String LEAD_STATUS_QUALIFIED = 'Qualified';
    //AMT: 31/Dec/2019
    public final static String BATCH_LEAD_SQL = 'SELECT Site__c,OwnerId,Lead__r.Site__c,Lead__r.LeadSegment__c,EBH_Seller__c, EBH_Seller__r.Primary_Contact__r.Email, Lead__c, Lead__r.FirstName, Lead__r.LastName, Lead__r.Title, Lead__r.Email, Lead__r.Phone, Lead__r.MobilePhone, Lead__r.Street, Lead__r.City, Lead__r.Country, Lead__r.PostalCode, Lead__r.State, Lead__r.EBH_PreferredContactTime__c FROM EBH_Project__c';
    public final static String PROJECT_STAGE_STORELAUNCHED = 'Store Launched';
    public final static String PROJECT_RT_AUSMB = 'eBayAUSMB';
    public final static String PROJECT_RT_AUENTERPRISE = 'eBayAUEnterprise';
    public final static String PROJECT_STAGE_LIVETOSITE = 'Live to Site';
    //TH: 20/Jan/2020 US-0007005
    public final static String PERMISSION_SET_CONTRACT_ADMIN = 'EBH_ContractAdmin';
	public final static String CM_MC_STATUS_CANCELLED = 'Cancelled';
	//TH: 04/Feb/2020 US-0007167
	public final static String SOQL_QUERRY_CONTRACTRECORDTYPE = 'select id from RecordType';
	//TH: 11/Feb/2020 US-0005905 FVF Contact Person
	public final static String FVF_DECISION_MAKER_ROLE = 'Final Value Fee';
    //AMT: 11/Feb/2020 
    public final static String CPNSLR_CPNCOINVSQL = 'SELECT Id, (SELECT Id FROM Coupon_Co_Invests__r WHERE Co_Invest__c = null LIMIT 1) FROM Coupon_Seller__c WHERE Id IN:sCpnSlrId';
    //DHE : 11/Feb/2020
    public final static String DEAL_STATUS_NEW = 'New';
    public final static List<String> DEAL_CLONE_FIELDS_TO_COPY = new List<STring>{'EBH_BusinessName__c','EBH_SellerEmail__c','EBH_ProductTitle__c','EBH_DealSiteId__c','EBH_MarketingTitle__c','EBH_Category__c','EBH_Vertical__c','EBH_SpotlightCategory__c','EBH_DealPrice__c'};
    public final static String recType = 'Select DeveloperName from RecordType';
    //SRM: 13/Feb/2020
    public final static String FVF_CAMPAIGN_RECORDTYPE = 'FVF_Campaign';
    public final static String EMAILTEMPLATE_FVF_CAMPAIGN_UPLOAD_RESULT  = 'FVFCampaignUploadResult';
    public final static String CPNSELLER_CPNCOINVSOQL = 'SELECT (SELECT Coupon_Name__c, Coupon_Category__r.Category__r.Name, Coupon_Seller__c, Coupon_Seller__r.Name, Coupon_Seller__r.Coupon_Seller_Stage__c, Coupon_Seller__r.Seller__r.Name, Coupon_Seller__r.EBH_CouponSellerOwner__r.Name, Coupon_Seller__r.Oracle_ID__c, Seller_Funding__c, Co_Invest__c, eBayFunding__c FROM Coupon_Co_Invests__r WHERE Coupon_Seller__r.Coupon_Seller_Stage__c =: couponStageNego), Contract_Due_Date__c, Coupon_Cap__c, Max_Redemptions__c, Contract_Language__c, Coupon_ID__c, Marketing_Coupon_Name__c, Coupon_Start_Date__c, Coupon_End_Date__c, Coupon_Discount__c, Coupon_GMV_Target__c, Owner.Email FROM Coupon__c ';
    public final static String GROUP_UKCOUPONAPPROVER = 'UKCouponApprover';
    public final static String EMAILTEMPLATE_FVF_APPROVAL_REQUEST = 'Final_Value_Fee_Discount_Request';
    public final static String EMAILTEMPLATE_FVF_CAMPAIGN_APPROVAL_NOTIFY = 'FVF_Campaign_ApprovalNotify';
	public static final String SOQL_User2 
        = 'Select Id,FirstName, lastName,Name,UserType, username,Email,isActive, Permission_Sets__c,LocaleSidKey From User ';
    //Th : 3/3/2020: US-0007259 POP COUPON - NEW RECORD TYPE COUPON OBJECT
    public final static String COUPON_POP_RECORDTYPE = 'Pop_Coupon';
    public final static String COUPONSELLER_MANHATTAN_RECORDTYPE = 'Manhattan_Coupon';
    // POP Master-Child Coupon Record Types
    public final static String COUPON_MASTER_RECORDTYPE = 'Single_Contract_Multi_Coupon_SCMC_Category_Based';
    public final static String COUPON_PROGRAM_RECORDTYPE = 'Program_Coupon';

    //Th : 25/03/2020 :  US-0007330 - [EU & AU] Approval Process   
    public final static String LEAD_COUNTRY_AU = 'AU';
    public final static String LEAD_SEGMENT_SMB = 'SMB';   

    public final static String FVF_STAGE_DRAFT = 'Draft';   
    //SRM : 25/03/2020 : US-0007373 - [FVF (campaign)] attach csv. template
    public final static String DOC_NAME_FVFCAMPAIGN = 'FVF_Campaign_Bulk_Upload';
    //AMT : 24/3/2020: US-0006918 - [EU & AU] Auto Project Creation
    public final static String TASK_AU_RT = 'AU_Task';
    public final static String LEAD_PROJECT_SQL = 'SELECT Id, (SELECT Id From Projects__r ORDER BY Id DESC LIMIT 1) FROM Lead ';
    //TH : 26/03/2020 : US-0007354 - LTTM - Manual addition of LTTM BoB Sellers
    public final static String BOB_SELLER_SEGMENT_LTTM = 'LTTM';
    public final static String SOQL_BOB_1 = 'Select Status__c, Name, RecordTypeId,Account_Manager__c,Owner.Name,owner.Email From BOB__c';
    public final static String BOB_LTTM_RECORDTYPE = 'Light_Touch_Category_Cohort';
    public final static String BOB_MANAGE_RECORDTYPE = 'Managed_Cohort';
    //TH : 26/03/2020 : US-0007333 - LTTM - Bulk Upload BoB Sellers
    public final static String BOB_STATUS_DRAFT = 'Draft';
    public final static String BULK_RESULT_EMAIL = 'ManagedSellerUploadResult';
    public final static String BULK_BOBSELLER_DOC = 'Bob_Seller_Bulk_Upload';
    public final static String SOQL_BOB_SELLER_1 = 'select Oracle_Id__c, Seller__r.Name from BoB_Seller__c';
    
    public final static String SOQL_CAT_TREE = 'Select Note_ID__r.Note_ID__r.Note_ID__r.Level_auto__c,Note_ID__r.Note_ID__r.Note_ID__r.Name,Note_ID__r.Note_ID__r.Note_ID__r.Id, Id,Name,Category_ID__c,External_ID__c,Level_auto__c,Site_auto__c,Site__c,Site_Name__c,Note_ID__c,Note_ID__r.Id,Note_ID__r.Name,Note_ID__r.Level_auto__c,Note_ID__r.Note_ID__c,Note_ID__r.Note_ID__r.Id,Note_ID__r.Note_ID__r.Name,Note_ID__r.Note_ID__r.Level_auto__c From Category_Tree__c ';
	//TH : 15/04/2020 : US-0007434 - [AU & EU] Related Contact
	public final static String SOQL_PROJECT = 'Select LegalEntity__c, EBH_Seller__r.ParentId, EBH_Seller__c From EBH_Project__c';//[PLACEHOLDER]
	public final static String SOQL_CONTACT_FIELDSET = 'Select Id[PLACEHOLDER] From Contact';
	public final static String SOQL_CONTACT_LIMIT = 'limit 6';
	
	//Start-NK:20/04/2020:US-0007443  
	public static final String RECTYPE_ACTION_TEMPLATE_ACQ='Acquisition';
	public static final String SOQL_ACTION_TEMPLATE  = 'Select Id,Name,Active__c,Country__c,Description__c,Group__c,Lead_Segment__c,RecordTypeId,RecordType.Name,Required__c From Action_Template__c ';
	public static final String SOQL_ACTION = 'Select Id,Name,Action_Outcome__c,Action_Template__c,Completed_Date__c,Description__c,Due_Date__c,Project__c,RecordTypeId,Required__c,Status__c From Action__c ';
    //End-NK:20/04/2020:US-0007443
    
    //Start-AMT:21/04/2020:US-0007400
	public static final String ACCOUNT_SOQL='SELECT Website, EBH_VATNumber__c FROM Account ';
	//End-AMT:21/04/2020:US-0007400
	
	//Start-SRM:21/04/2020:US-0007429
	public static final Map<String,String> mapCountry = new Map<String,String>{'3'=>'UK','77'=>'DE', '71'=>'FR','101'=>'IT','186'=>'ES','163'=>'PL',
            '99'=>'IE','193'=>'CH','146'=>'NL','23'=>'BE','15'=>'AU','168'=>'EEC-Unsited'};
    public static final String RECTYPE_ACTION_TEMPLATE_LTTM = 'LTTM';
	//End-SRM:21/04/2020:US-0007429
	
	//TH : US-0007509 : 24/04/2020 
	public static final String CONTACT_MANAUL_RECORDTYPE = 'EBH_MANUAL';
}