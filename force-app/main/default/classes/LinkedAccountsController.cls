/*********************************************************************************************************************************
@ Class:        LinkedAccountsController
@ Version:      1.0
@ Author:       Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:      Controller for lwcLinkedAccounts  
@              
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.04.2022 / mony nou / Created the class.
@ Change history: 31.08.2022 / Sophal Noch / US-0012302 - Seller Portal Group needs to reflect the SP field values in the Related Account
@ Change history: 12.10.22 / Bora Chhorn / US-0012024 - Delete Seller Portal Region for Seller Group
@               : 20.10.2022/vadhanak voun/ US-0012854 - Remove Oracle ID from contact when moved to seller portal group
@               : 09.12.2022/vadhanak voun/US-0012896 - Cloning of DWH contact after move to group during linking accounts
@               : 12.12.2022 / Sambath Seng / US-0013001 - Domain Selection for SP Eligible Sellers
@               : 21.12.2022/vadhanak voun/ US-0012914 - [UK] Enable Link Multiple Accounts for UK Portal Sellers
@               : 03.04.2022/ Mony Nou / US-0013325 - Account - Sharing Rules and validation
@               : 05.09.2023 / Bora Chhorn / US-0014084 - SP Account Management Eligibility flag
@               : 15.02.2024 / Mony Nou / US-0014491 - [Tech Debt] Remove dependency from URL Domain and replace with SP Main Domain Field in SEP Features
@               : 11/06/2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
@               : 04/04/2025 / Sovantheany Dim / US-0016623 - Enable Link Multiple Account for NA 
@               : 17.04.2025 / vadhanak voun / US-0017119 - Linked Account - SP Promotion Manager reflect on the SP Group
@               : 28.04.2025/ vadhanak voun / US-0016968 - Enable Sales Engagement and Cadence
*********************************************************************************************************************************/
public with sharing class LinkedAccountsController {

    //private final static String PF_PORTAL_DE = 'DE - Seller Portal'; //MN-11062024-US-0015298: No longer use Profile
    //private final static String PF_PORTAL_NA = 'NA - Seller Portal'; //MN-11062024-US-0015298: No longer use Profile
    
    private final static String ELIGBILE_DEALS_DE = 'Eligible_for_DE_Deals';

    private final static String RT_CONT_DWH ='EBH_DWH';
    public static Boolean IS_LINKING_ACCOUNT = false;
    // SRONG TIN 10.06.2022 : US-0011345
    private final static String ACCESS_ALLOWED ='Allowed';

    private static final String RT_ACC_GROUP='Seller_Portal_Group';
    
    
    
    /* MN-11062024: No using anywhere
    //NK:21/12/2022:US-0012914
    private final static Map<String, String> PROFILE_METADATA_MAPPING = new Map<String,String>
    {
        PF_PORTAL_DE=>'eBay_DE_Login',
        PF_PORTAL_NA=>'Sign_in_with_eBay_Logins',
        'AU - Seller Portal'=>'eBay_AU_Login',
        PF_PORTAL_DE+'UK'=>'eBay_UK_Login',
        PF_PORTAL_DE+'FR'=>'eBay_FR_Login'
    };
    
    private final static Map<String, String> PROFILE_SITE_MAPPING = new Map<String,String>
    {
        PF_PORTAL_DE=>'77',
        PF_PORTAL_NA=>'0',
        'AU - Seller Portal'=>'15'        
    };
    */

    //MN-11062024-US-0015298: Using SP Main Domain instead
    private final static Map<String, String> SPMAINDOMAIN_SITE_MAPPING = new Map<String,String>
    {
        SEP_Helper.SEP_Domain_DE =>'77',
        SEP_Helper.SEP_Domain_FR =>'77',
        SEP_Helper.SEP_Domain_UK =>'77',
        SEP_Helper.SEP_Domain_IT =>'77',
        SEP_Helper.SEP_Domain_NA =>'0',
        SEP_Helper.SEP_Domain_AU =>'15'        
    };

    private final static String SOQL_ACR_LOGIN_USER = 'Select Id, AccountId,Account.eBay_API_User_Id__c From AccountContactRelation Where ContactId =:loginContactId';
    private final static String SOQL_ACR_IN_GROUP = 'Select Id, Contact.Account.SP_Coupons__c, Contact.Account.SP_Deals__c, AccountId, ContactId, Contact.AccountId, Contact.Original_Seller__c, IsDirect From AccountContactRelation Where AccountId =:selectAccountId AND Account.Seller_Portal_Group__c != null And Account.Seller_Portal_Group__c =:sellerGroupId';
    private final static String SOQL_ACR_RELATED_TO_SELCTED_ACC = 'Select Id from AccountContactRelation Where isDirect = false And ContactId IN:setContactId And AccountId IN:setAccId And Id NOT IN:setAcrIdToDelete';
    
    //NK:17/04/2025:US-0017119 
    private final static String SOQL_AGGR_SELLER_GROUP = 'Select count(SP_Promotions_Manager__c)spPMCount ,Seller_Portal_Group__c spgId, count(SP_Deals__c) spDealsCount, count(SP_Coupons__c) spCouponsCount, count(SP_Account_Management__c) spAccManagementCount, count(NA_Deal_Program_Subsidy_eligible_W__c) spNaDealSubEligible From Account Where Seller_Portal_Group__c IN:setSellerGroupId And Id NOT IN:setUnlinkedAccountId And Seller_Portal_Group__c != null And Seller_Portal_Group__r.RecordType.DeveloperName = '+ApexUtil.closeSQoute(RT_ACC_GROUP)+' Group by Seller_Portal_Group__c';
    
    /*********************************************************************************************************************************
    @ method:        getAccounts
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      US-0011080 - Linked Accounts Landing Page
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.04.2022 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getAccounts()
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
    
        User currentUser = [Select Contact.Account.Requested_By__c,Contact.Original_Seller__c,Contact.Original_Seller__r.Name,Contact.Account.Name,Id,UserName,Email,ContactId,Contact.RecordType.DeveloperName,Contact.Account.RecordType.DeveloperName,Contact.AccountId,Contact.Account.OwnerId,Federated_Login__c From User Where Id=:UserInfo.getUserId()];
        
        Map<String,Object> mapRelation = new Map<String,Object>();

        // String sQuery = 'Select Id,AccountId,Account.Name,Contact.Name,Contact.Email,ContactId,IsActive From AccountContactRelation';
        // String sWhere = ' Where Account.RecordType.DeveloperName =\'EBH_Seller\' and ContactId=\'' + currentUser.ContactId + '\'' ;

        // for(AccountContactRelation acr : (List<AccountContactRelation>) WithoutSharing.doQuery(sQuery, sWhere, '')) {
        //     mapRelation.put(acr.AccountId,acr);
        // }
        
        Boolean mainHasGroup = currentUser.Contact.Account.RecordType.DeveloperName==RT_ACC_GROUP;
      

        /* MN-25042022-Need to use query without sharing in order to get information from other Accounts that not owned the User.ContactId*/
        RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
        //And (AccountId=:currentUser.Contact.AccountId OR Account.Seller_Portal_Group__c=:currentUser.Contact.AccountId)
        for(AccountContactRelation acr : [Select Contact.Original_Seller__c,Id,AccountId,Account.Name,Contact.Name,Contact.Email,ContactId,IsActive From AccountContactRelation Where Account.RecordTypeId =:recSeller.Id ]) // and ContactId=:currentUser.ContactId 
        {
            mapRelation.put(acr.AccountId,new Map<String,Object>{'Id'=>acr.Id,'Contact'=>acr.Contact,'Account'=>acr.Account,'isAdmin'=>(!mainHasGroup?true:acr.AccountId== currentUser.Contact.Original_Seller__c)});//(currentUser.Contact.Account.PrimaryLinkedSeller__c==acr.AccountId)
        }
         
        mapResult.put('hasGroup',mainHasGroup);  
        mapResult.put('mainGroupId',(mainHasGroup? String.valueOf(currentUser.Contact.AccountId) :'') );
        mapResult.put('mainGroupName',mainHasGroup?currentUser.Contact.Account.Name:'');  
        mapResult.put('curentUser',currentUser);
        mapResult.put('accRelation',mapRelation.values());
       
        return mapResult;
    }
    
    /*********************************************************************************************************************************
    @ method:        apexGetSessionId
    @ Version:      1.0
    @ Author:       vadhanak voun(vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0011082 - Allow Sellers to link Accounts
    @               get ebay session id to pass to consent screen flow for ebay quthentication (auth 'n' auth)
    @               which previousely stored in attachment
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2022 / vadhanak / Created the method. 
    @               :21.12.2022/ vadhanak / US-0012914 - [UK] Enable Link Multiple Accounts for UK Portal Sellers
    @               :11.06.2024 / Mony Nou / US-0015298 - [Seller Portal License Assignment] - Replace Profile Name with SP_Main_Domain__c
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexEbayConfirmIdentity()
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok','ack'=>'ko'};
        try 
        {
            User usr  = [Select Contact.Original_Seller__c,Contact.Original_Seller__r.Name,Contact.ClonedSource__r.AccountId,Contact.ClonedSource__r.Account.Name, Id,Profile.Name,ContactId,Contact.AccountId,Contact.Account.Name,Contact.Account.ebay_session_id_tmp__c,Contact.Account.Seller_Portal_Group__c,Contact.Account.Seller_Portal_Group__r.Name,Contact.Account.RecordType.DeveloperName From User Where Id=:UserInfo.getUserId()];
            //String profileName = usr.Profile.Name; //MN-11062024-US-0015298: No longer use Profile
            mapResult.put('hasSession',(usr.Contact.Account.ebay_session_id_tmp__c <> null));
            if(usr.Contact.Account.ebay_session_id_tmp__c <> null)
            {
                String authName = getAuthMetaName();//NK:21/12/2022:US-0012914
                //EbayService.IdentityConfirmService idService = new EbayService.IdentityConfirmService(PROFILE_SITE_MAPPING.get(profileName),PROFILE_METADATA_MAPPING.get(profileName),usr.Contact.Account.ebay_session_id_tmp__c);
                //EbayService.IdentityConfirmService idService = new EbayService.IdentityConfirmService(PROFILE_SITE_MAPPING.get(profileName),authName,usr.Contact.Account.ebay_session_id_tmp__c); //MN-11062024-US-0015298: No longer use Profile
                
                //MN-11062024-US-0015298: Using SP Main Domain instead
                EbayService.IdentityConfirmService idService = new EbayService.IdentityConfirmService(SPMAINDOMAIN_SITE_MAPPING.get(SEP_Helper.sepUser.domain),authName,usr.Contact.Account.ebay_session_id_tmp__c);

                idService.sendRequest();
                system.debug('--isSuccess: '+idService.isSuccess());
                if(idService.isSuccess())
                {              
                    Boolean ackOK = idService.getListObject()[0]=='Success';
                    String linkingSeller =  ackOK?String.valueOf(idService.getListObject()[1]):'';
                    Boolean mainHasGroup = usr.Contact.Account.RecordType.DeveloperName==RT_ACC_GROUP;
                    mapResult.put('ack',(ackOK?'ok':'ko'));
                    mapResult.put('userID',linkingSeller);
                    mapResult.put('ack_error',idService.getListObject()[0]=='Failure'?idService.getListObject()[1]:'');
                    mapResult.put('hasGroup',mainHasGroup); //main seller alredy has group?
                    mapResult.put('mainGroupId',(mainHasGroup?String.valueOf(usr.Contact.AccountId):'') );
                    mapResult.put('mainGroupName',mainHasGroup?usr.Contact.Account.Name:''); //when having group, user moved to group
                    mapResult.put('mainIsNotPortalGroupRT',(usr.Contact.Account.RecordType.DeveloperName<>RT_ACC_GROUP));             
                    mapResult.put('mainAccId',mainHasGroup?String.valueOf(usr.Contact.Original_Seller__c):String.valueOf(usr.Contact.AccountId));
                    mapResult.put('mainAccName',(mainHasGroup? usr.Contact.Original_Seller__r.Name:usr.Contact.Account.Name));
                    //mapResult.put('mainAccNameOrigin',(mainHasGroup?usr.Contact.ClonedSource__r.Account.Name:usr.Contact.Account.Name)); //parent account before clone/lave
                    //mapResult.put('mainAccIdOrigin',(mainHasGroup?usr.Contact.ClonedSource__r.AccountId:usr.Contact.AccountId));
                    if(!String.isBlank(linkingSeller))
                    {
                        String soqlAcc = 'Select Id,Name,Seller_Portal_Group__c,Seller_Portal_Group__r.Name From Account ';
                        String soqlAccWhere = ' Where Name='+ApexUtil.closeSQoute(linkingSeller) +' AND ID <>'+ApexUtil.closeSQoute(usr.Contact.AccountId)+' AND RecordType.DeveloperName='+ApexUtil.closeSQoute('EBH_Seller')+'';
                       
                        Account[] findAcc = WithoutSharing.doQuery(soqlAcc, soqlAccWhere, '');
                        Boolean isFound = !findAcc.isEmpty(); 
                        Boolean slaveHasGroup = (isFound && String.isNotBlank(findAcc[0].Seller_Portal_Group__c));
                        mapResult.put('hiveExist',isFound);
                        mapResult.put('slaveGroupName',(isFound && slaveHasGroup ? String.valueOf(findAcc[0].Seller_Portal_Group__r.Name) : '') );
                        mapResult.put('slaveGroupId', (isFound ? String.valueOf(findAcc[0].Seller_Portal_Group__c) : '')  );
                        mapResult.put('slaveAccountId',(isFound ? String.valueOf(findAcc[0].Id) : ''));
                        mapResult.put('slaveHasGroup',slaveHasGroup);
                         
                        // for(User u_slave:[Select Contact.Account.RecordType.DeveloperName,Id,ContactId,Contact.AccountId,Contact.Account.Name,Contact.ClonedSource__r.AccountId,Contact.ClonedSource__r.Account.Name From User Where Federated_Login__c=False AND (Contact.AccountId=:findAcc[0].Id OR Contact.ClonedSource__r.AccountId=:findAcc[0].Id)] )
                        // {
                        //     // mapResult.put('slaveHasGroup',(isFound && u_slave.Contact.Account.RecordType.DeveloperName==RT_ACC_GROUP) );
                        //     // mapResult.put('slaveGroupId', (isFound ? findAcc[0].Seller_Portal_Group__c+'' : '')  );
                        // }
                    }
                    
                }
                
                Account acc = new Account(Id=usr.Contact.AccountId,ebay_session_id_tmp__c=null);
                WithoutSharing.doUpdate(new Account[]{acc});
            }
        } catch (Exception ex) { mapResult.put('status','ko');mapResult.put('error',ex);mapResult.put('errorDetail',ex.getStackTraceString()); }
       

        return mapResult;
    }
    
    /*********************************************************************************************************************************
    @ method:        apexGetSessionId
    @ Version:      1.0
    @ Author:       vadhanak voun(vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0011082 - Allow Sellers to link Accounts
    @               get ebay session id to pass to consent screen flow for ebay quthentication (auth 'n' auth)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2022 / vadhanak / Created the method. 
    @               : 12.12.2022/ vadhanak/ US-0012896 - Cloning of DWH contact after move to group during linking accounts
    @                                    / added errorDetail
    @               :21.12.2022/ vadhanak / US-0012914 - [UK] Enable Link Multiple Accounts for UK Portal Sellers
    @                                      / getAuthMetaName()
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexGetEbaySessionId()
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        try {     
            User usr  = [Select Id,Profile.Name,Contact.AccountId,Contact.Account.ebay_session_id_tmp__c  From User Where Id=:UserInfo.getUserId()];
            
            //String profileName = usr.Profile.Name; //MN-11062024-US-0015298: No longer use Profile

            String authName = getAuthMetaName();//NK:21/12/2022:US-0012914

            // EbayService.GetSessionService sessionService = new EbayService.GetSessionService(PROFILE_SITE_MAPPING.get(profileName),PROFILE_METADATA_MAPPING.get(profileName));
            //EbayService.GetSessionService sessionService = new EbayService.GetSessionService(PROFILE_SITE_MAPPING.get(profileName),authName); //MN-11062024-US-0015298: No longer use Profile
            
            //MN-11062024-US-0015298: Using SP Main Domain instead
            EbayService.GetSessionService sessionService = new EbayService.GetSessionService(SPMAINDOMAIN_SITE_MAPPING.get(SEP_Helper.sepUser.domain),authName);

            sessionService.sendRequest();
            system.debug('--isSuccess: '+sessionService.isSuccess());

            //Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance(PROFILE_METADATA_MAPPING.get(profileName));
            Ebay_SSO_Provider__mdt cred =  Ebay_SSO_Provider__mdt.getInstance(authName);
            
            mapResult.put('ebayStatus',sessionService.isSuccess());
            mapResult.put('ebaySessionId',sessionService.getListObject()[0]);
            mapResult.put('endpoint',cred.Consent_Screen_Url__c);
            mapResult.put('ebayRuName',cred.RuName__c);

            //temporarily store in a field. to be cleared in the next step
            if(sessionService.isSuccess())
            {
                Account acc = new Account(Id=usr.Contact.AccountId,ebay_session_id_tmp__c=mapResult.get('ebaySessionId')+'');
                WithoutSharing.doUpdate(new Account[]{acc});
            }
            

        } catch (Exception ex) { mapResult.put('status','ko');mapResult.put('error',ex); mapResult.put('errorDetail',ex.getStackTraceString());     }
                
        return mapResult;
         
    }
    //NK:21/12/2022:US-0012914
    private static String getAuthMetaName()
    {
        //String curDomain = (ApexUtil.runningInASandbox())?System.Label.SEP_Current_Sandbox_Domain:ApexUtil.getDomain(); //MN-15022024-US-0014491
        String curDomain = SEP_Helper.getSPMainDomain(); //MN-15022024-US-0014491
        
        return (SEP_Helper.DOMAIN_AUTH_MAPPING.containsKey(curDomain)?SEP_Helper.DOMAIN_AUTH_MAPPING.get(curDomain):SEP_Helper.DOMAIN_AUTH_MAPPING.get(SEP_Helper.SEP_Domain_DE));
    }
    /*********************************************************************************************************************************
    @ method:       apexManageGroup
    @ Version:      1.0
    @ Author:       vadhanak voun(vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0011082 - Allow Sellers to link Accounts
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.04.2022 / vadhanak / Created the method. 
    @               : 09.06.2022 / SRONG TIN / US-0011345 - Coupon Account Linking for new permission model
    @               : 12.10.22 / Bora Chhorn / US-0012024 - Delete Seller Portal Region for Seller Group
    @               : 12.12.2022 / Sambath Seng / US-0013001 - Domain Selection for SP Eligible Sellers
    @               : 03.04.2022/ Mony Nou / US-0013325 - Account - Sharing Rules and validation
    @               : 05.09.2023 / Bora Chhorn / US-0014084 - SP Account Management Eligibility flag
    @               : 04.04.2025 / Sovantheany Dim / US-0016623 - Enable Link Multiple Account for NA
    @               : 17.04.2025 / vadhanak voun / US-0017119 - Linked Account - SP Promotion Manager reflect on the SP Group
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> apexManageGroup(String groupName,String groupId,String mainAccId,String newLinkAccountId,String groupAt)
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        Boolean isNewGroup = String.isBlank(groupId); //new group to be created?
        Savepoint sp = Database.setSavepoint();
        try 
        {
            RecordType portalGroupRT = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
            RecordType contSellerPortalRT = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
            User usr  = [Select Id,ContactId,Contact.AccountId,Contact.Account.OwnerId,Contact.Account.Seller_Portal_Group__c,Contact.Account.SP_Main_Domain__c  From User Where Id=:UserInfo.getUserId()];
            // SRONG TIN 10.06.2022 : US-0011345 //TH:05.04.2025:US-0016623 : Add NA_Deal_Program_Vetted__c
            //NK:17/04/2025:US-0017119  SP_Promotions_Manager__c
            String soqlAcc = 'Select Id, SP_Deals__c, SP_Coupons__c, SP_Account_Management__c,NA_Deal_Program_Vetted__c,SP_Promotions_Manager__c From Account ';
            String sWhere1 = isNewGroup ? ' Where Id IN('+ApexUtil.constructQuoteString(new Set<String>{usr.Contact.AccountId,newLinkAccountId})+')':' WHERE ( Id ='+ApexUtil.closeSQoute(newLinkAccountId) +' OR Seller_Portal_Group__c='+ApexUtil.closeSQoute(groupId)+')';
            //String sWhere2 = ' AND SP_Deals__c IN('+ApexUtil.constructQuoteString(new Set<String>{'Full Access','Read Only'})+')'; 
            
            List<Account> listAccounts = (Account[])WithoutSharing.doQuery(soqlAcc, sWhere1,'');//sWhere2
            system.debug('--groupName: '+groupName+' groupId: '+groupId+'  mainAccId: '+mainAccId+'  newLinkAccountId: '+newLinkAccountId);
            //String primaryLinkContactId = usr.ContactId;
            //1,create new group             
            List<Account> listToGroup = new  List<Account>();
            // SRONG TIN 08.06.2022 : US-0011345
            Boolean isSP_Deal = false;
            Boolean isSP_Coupon = false;
            Boolean isSP_AccountManagement = false; //BR 05-09-2023-US-0014084
            Boolean isSP_NADeal_Sub_Eligible = false;//TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
            Boolean isPM =  false; //NK:17/04/2025:US-0017119;
            for(Account ac: listAccounts){
                if(ac.SP_Deals__c != null){isSP_Deal = true;}
                if(ac.SP_Coupons__c != null){isSP_Coupon = true;}
                if(ac.SP_Account_Management__c != null){isSP_AccountManagement = true;} //BR 05-09-2023-US-0014084
                if(ac.NA_Deal_Program_Vetted__c){isSP_NADeal_Sub_Eligible = true;}//TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
                //NK:17/04/2025:US-0017119;
                if(String.isNotBlank(ac.SP_Promotions_Manager__c))
                {
                    isPM = true;
                }
            }
            if(isNewGroup)  
            {
                Account accGroup = new Account(Name=groupName,
                    // Seller_Portal_Region__c='DE', //BR-US-0012024 
                    //OwnerId=usr.Contact.Account.OwnerId, //MN-03042023-US-0013325
                    OwnerId = ApexUtil.INTEGRATION_USER_ID, //MN-03042023-US-0013325-AC2: Assigned owner to Integration User
                    Requested_By__c=usr.ContactId,
                    RecordTypeId=portalGroupRT.Id,
                    SP_Deals__c = isSP_Deal?ACCESS_ALLOWED:'',
                    SP_Coupons__c = isSP_Coupon?ACCESS_ALLOWED:'',
                    SP_Main_Domain__c = usr.Contact.Account.SP_Main_Domain__c,
                    SP_Account_Management__c = isSP_AccountManagement?ACCESS_ALLOWED:'', //BR 05-09-2023-US-0014084
                    NA_Deal_Program_Vetted__c = isSP_NADeal_Sub_Eligible?true:false, //TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
                    //PrimaryLinkedSeller__c=mainAccId
                    SP_Promotions_Manager__c = isPM?ACCESS_ALLOWED:''//NK:17/04/2025:US-0017119;
                );
                //crate group first to get id
                WithoutSharing.doInsert(new Account[]{accGroup});
                groupId = accGroup.Id;

                listToGroup.add(new Account(Id=newLinkAccountId,Seller_Portal_Group__c=groupId,User_Disconnected__c=false));
                listToGroup.add(new Account(Id=usr.Contact.AccountId,Seller_Portal_Group__c=accGroup.Id,User_Disconnected__c=false));
                
            }else //group exists
            {                 
                String soqlGroup = 'Select Id,SP_Deals__c,SP_Coupons__c,Requested_By__c,SP_Account_Management__c,NA_Deal_Program_Vetted__c,SP_Promotions_Manager__c From Account Where Id='+ApexUtil.closeSQoute(groupId);
                Account[] accGroup  = WithoutSharing.doQuery(soqlGroup, '', '');  
                
                // SRONG TIN 08.06.2022 : US-0011345 
                //NK:17/04/2025:US-0017119   
                if(isPM || isSP_Deal || isSP_Coupon || isSP_AccountManagement || isSP_NADeal_Sub_Eligible){//TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
                    if(String.isBlank(accGroup[0].SP_Deals__c) || String.isBlank(accGroup[0].SP_Coupons__c) || String.isBlank(accGroup[0].SP_Account_Management__c) || !accGroup[0].NA_Deal_Program_Vetted__c){//TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
                        accGroup[0].SP_Deals__c = (String.isBlank(accGroup[0].SP_Deals__c) && isSP_Deal)?ACCESS_ALLOWED:accGroup[0].SP_Deals__c;
                        accGroup[0].SP_Coupons__c = (String.isBlank(accGroup[0].SP_Coupons__c) && isSP_Coupon)?ACCESS_ALLOWED:accGroup[0].SP_Coupons__c;
                        accGroup[0].SP_Account_Management__c = (String.isBlank(accGroup[0].SP_Account_Management__c) && isSP_AccountManagement)?ACCESS_ALLOWED:accGroup[0].SP_Account_Management__c; //BR 05-09-2023-US-0014084
                        accGroup[0].NA_Deal_Program_Vetted__c = (!accGroup[0].NA_Deal_Program_Vetted__c && isSP_NADeal_Sub_Eligible)?true:false;//TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c
                        
                        accGroup[0].SP_Promotions_Manager__c = isPM?ACCESS_ALLOWED:accGroup[0].SP_Promotions_Manager__c;
                        listToGroup.add(accGroup[0]);
                    }
                }
                // primaryLinkContactId = accGroup[0].Requested_By__c;

                listToGroup.add(new Account(Id=newLinkAccountId,Seller_Portal_Group__c=groupId,User_Disconnected__c=false));
                listToGroup.add(new Account(Id=mainAccId,Seller_Portal_Group__c=groupId,User_Disconnected__c=false));
            }
            system.debug('--listToGroup: '+listToGroup);
            WithoutSharing.doUpdate(listToGroup);
            
            //clone all portal contacts
            Map<String,String> mapUsrSSO_SlaveCont  = movingContactsToGroup(mainAccId,newLinkAccountId,groupId,groupAt,isNewGroup);
            
            //manage account-contact relationship
            manageContactsRelationship(groupId);
           
            //deactivate slave user
            createW2CaseToDisconnectSPUser(newLinkAccountId,mapUsrSSO_SlaveCont,true);

        } catch (Exception ex){mapResult.put('status','ko');mapResult.put('error',ex); mapResult.put('errorDetail',ex.getStackTraceString());Database.rollback(sp);}


        return mapResult;
    }

    /*********************************************************************************************************************************
    @ method:        movingContactsToGroup           
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  09.12.2022/vadhanak voun/US-0012896 - Cloning of DWH contact after move to group during linking accounts
    @               : 28.04.2025/ vadhanak voun / US-0016968 - Enable Sales Engagement and Cadence
    *********************************************************************************************************************************/
    private static Map<String,String>  movingContactsToGroup(String mainAccountId,String slaveAccountId,String groupAccId,String groupAt,Boolean isNewGroup)
    {
        Set<String> setAllContId = new Set<String>();
        Map<String,String> mapUsrSSO_SlaveCont = new Map<String,String>{'Id'=>slaveAccountId};
        List<Contact> listCont = new List<Contact>();
        RecordType contSellerPortalRT = ApexUtil.getRecordTypeByName('Contact', 'Seller_Portal');
        RecordType rtContDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
        
        //NK:28/04/2025:US-0016968: some fields not able to clone. e.g. Cadence fields
        Set<String> setExcludedFields = new Set<String>();  
        String soqlMDT = 'Select Id,DeveloperName,MasterLabel,Value_Big__c From Seller_Portal_Global_Variables__mdt Where DeveloperName =:mdtConfigName';
        List<Seller_Portal_Global_Variables__mdt> mdtConfig = ApexSafe.query().secCheck(false).doQuery(soqlMDT,new Map<String,Object>{'mdtConfigName'=>'LinkAccountCloneContactExcludedFields'});
        if(!mdtConfig.isEmpty() && mdtConfig[0].Value_Big__c != null)
        {
            setExcludedFields.addAll(mdtConfig[0].Value_Big__c.split(','));
        }        

        String soqlInerUser = ',Account.eBay_API_User_Id__c,(select Id,ContactId,Contact.AccountId,Federated_Login__c From Users limit 1) '; 
        String soqlCont = 'Select '+ApexUtil.generateSQOLFields('Contact',false,setExcludedFields) +soqlInerUser+' From Contact ';
        system.debug('soqlCont: '+soqlCont);
        String sWhereCont = isNewGroup? ' WHERE AccountId IN(' + ApexUtil.constructQuoteString(new Set<String>{mainAccountId,slaveAccountId})+')':' WHERE AccountId='+ApexUtil.closeSQoute(slaveAccountId); 
        //system.debug('--soqlCont:'+JSON.serialize(soqlCont+' - '+sWhereCont));
        for(Contact originCont : (Contact[])WithoutSharing.doQuery(soqlCont,sWhereCont,'') )
        {   
            //move sso user from Seller A to group
            //and all federation users from seller A and B, but not SSO user from Seller B
            if(!isNewGroup && ((groupAt=='a' && originCont.AccountId==mainAccountId) || (groupAt=='b' && originCont.AccountId==slaveAccountId))) continue; 
            //The Contact related to the logged in User is cloned      
            //Contact newClone = originCont.clone(false,true,false,false);
            if(originCont.AccountId==slaveAccountId)
            {
                mapUsrSSO_SlaveCont.put('eBay_API_User_Id__c',originCont.Account.eBay_API_User_Id__c);
            }

            //only contact with user
            if(!originCont.Users.isEmpty())
            {
                String originSeller = originCont.AccountId;
                 //sso of slave account to be dissconnected and revoked:
                if(!originCont.Users[0].Federated_Login__c && originCont.Users[0].Contact.AccountId==slaveAccountId)
                {                       
                    mapUsrSSO_SlaveCont.put('UserId',originCont.Users[0].Id);   //to revoke and disconnect
                    mapUsrSSO_SlaveCont.put('ContactId',originCont.Users[0].ContactId);
                }else
                {
                    //NK:13/12/2022:US-0012896  - clone DWH to seller before moving to group
                    if(originCont.recordTypeId == rtContDWH.Id)
                    {                  
                        Contact newClone = originCont.clone(false,true,false,false);
                        listCont.add(newClone);
                    }
                    
                    //sso user from Seller A and federation user (both A,B) moving to Group
                    originCont.AccountId = groupAccId;
                    originCont.RecordTypeId=contSellerPortalRT.Id;
                    //originCont.External_ID__c=null;
                    originCont.EBH_OracleId__c = null;  //NK:20/10/2022:US-0012854
                    originCont.Original_Seller__c = originSeller;//newClone.AccountId;
                    listCont.add(originCont);               
                }
               
            }           
            
            //listCont.add(newClone);
        }
        
        IS_LINKING_ACCOUNT = true;
        
        WithoutSharing.doUpsert(listCont);

        return mapUsrSSO_SlaveCont;
    }

    /*********************************************************************************************************************************
    @ method:       apexCreateGroup > manageContactsRelationship
    @ Version:      1.0
    @ Author:       vadhanak voun(vadhanak.voun@gaea-sys.com)
    @ Purpose:      US-0011082 - Allow Sellers to link Accounts
    @               Any other Seller Portal enabled contacts related to Account A are also;
    @               Cloned
    @               The Contact related to the logged in User is moved to the Seller Portal Group, the cloned contact remains untouched
    @               The Contact related to the logged in User is moved to the Seller Portal Group have their Account Contact Records kept the same
    @               The Contact related to the logged in User is moved to the Seller Portal Group are changed from DWH to Seller Portal Record Type
    @               The Contact related to the logged in User is moved to the Seller Portal Group have the External ID removed from the Contact Record
    @               -----------
    @               Any other Seller Portal enabled contacts related to Account B are also;
    @               Cloned
    @               The Contact related to the logged in User is moved to the Seller Portal Group, the cloned contact remains untouched
    @               The Contact related to the logged in User is moved to the Seller Portal Group have their Account Contact Records kept the same
    @               The Contact related to the logged in User is moved to the Seller Portal Group are changed from DWH to Seller Portal Record Type
    @               The Contact related to the logged in User is moved to the Seller Portal Group have the External ID removed from the Contact Record
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.04.2022 / vadhanak / Created the method. 
    @                15.07.2022 / vadhanak voun / to public.to call from ManageUserController
    *********************************************************************************************************************************/    
    public static void manageContactsRelationship(String groupId)
    {  
        Set<String> setConts = new Set<String>();
        Set<String> setAccs = new Set<String>();
        Map<String,AccountContactRelation> mapACR = new Map<String,AccountContactRelation>();
        //ClonedSource__c =null = no cloned no user
        //String soqlConts = 'Select Id,AccountId,Account.Seller_Portal_Group__c From Contact Where (Recordtype.DeveloperName=%RT_CONT_DWH% AND Account.Seller_Portal_Group__c=%2% AND ClonedSource__c=NULL) OR (Recordtype.DeveloperName=%Seller_Portal% AND AccountId=%groupId%)';
        String soqlConts = 'Select Id,AccountId,Account.Seller_Portal_Group__c From Contact WHERE AccountId='+ApexUtil.closeSQoute(groupId);
       // soqlConts = soqlConts.replace('%RT_CONT_DWH%',ApexUtil.closeSQoute(RT_CONT_DWH)).replace('%groupId%',ApexUtil.closeSQoute(groupId)).replace('%Seller_Portal%',ApexUtil.closeSQoute('Seller_Portal'));        
        //Contact[] conts = [Select Id,AccountId,Account.Seller_Portal_Group__c From Contact Where (Recordtype.DeveloperName='EBH_DWH' AND Account.Seller_Portal_Group__c='groupId') OR (Recordtype.DeveloperName='Seller_Portal' AND AccountId='groupId')];
        for(Contact cont: (Contact[])WithoutSharing.doQuery(soqlConts,'',''))
        { 
            setConts.add(cont.Id); 
        }
        
        String soqlAcc = 'Select id from Account where Seller_Portal_Group__c='+ApexUtil.closeSQoute(groupId);         
        for(Account acc :  (Account[])WithoutSharing.doQuery(soqlAcc,'',''))
        {   
        
            for(String contId : setConts)
            {
                mapACR.put(acc.Id+''+contId,new AccountContactRelation(ContactId=contId,AccountId=acc.Id));
            }
        }

        IS_LINKING_ACCOUNT = true;
        
        WithoutSharing.doInsert(mapACR.values(),false);  //partial
        
    }

    /*****************************************************************************************************************************
    @ Method:         createW2CaseToDisconnectSPUser
    @ Version:        1.0
    @ Author:         vadhanak voun
    @ Purpose:        US-0011343 - Adding User to Existing Seller Portal Group
    @ Param:          slaveAccId: account Id being linked
    @                 mapUsrSSO_SlaveCont : eBay_API_User_Id__c => apiKeyIdxxx, UserId => userIdxxxx
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 24.05.2022 /vadhanak voun/ Created the  Method.
    *****************************************************************************************************************************/
    @future(callout=true)
    private static void createW2CaseToDisconnectSPUser(String slaveAccId,Map<String,String> mapUsrSSO_SlaveCont,Boolean isLinking)
    {
        RecordType caseSP = ApexUtil.getRecordTypeByName('Case', 'Seller_Portal_Deactivation');
        List<String> listParam = new List<String>
        {
            'orgid='+UserInfo.getOrganizationId(),
            'retURL=http://www.salesforce.com',
            'subject='+(isLinking?'LINKING':'UNLINKING') +'_SELLER%3A'+slaveAccId,
            'status=Closed',
            'recordType='+ String.valueOf(caseSP.Id).left(15),
            'description='+JSON.serialize(mapUsrSSO_SlaveCont)
            //'external=1'
        };

        String url = System.URL.getSalesforceBaseUrl().toExternalForm()+'/servlet/servlet.WebToCase?encoding=UTF-8&';
        String body = String.join(listParam,'&');
        
        HTTPWrapper.IRequest reqCase = new HTTPWrapper.SimpleRequest(url,'POST',body);
        HTTPWrapper.SimpleResponse resCase = new HTTPWrapper.SimpleResponse(reqCase);
    }

    // @future
    // private static void deactivateOtherUser(Map<String,String> mapUsrSSO_SlaveAcc)
    // {
    //      //revoke access
    //      //uncomitted pending..
    //     // revokeUserAccess3PLink(mapUsrSSO_SlaveAcc);

    //     List<User> listUser = new List<User>();
    //     String soqlUser = 'Select Id,FirstName,LastName,IsActive, IsPortalEnabled From User '; 
    //     String sWhereUserSSO = ' Where ContactId IN('+ApexUtil.constructQuoteString(new Set<String>(mapUsrSSO_SlaveAcc.values()))+') ';
        
    //     for(User usr:(User[]) WithoutSharing.doQuery(soqlUser, sWhereUserSSO, ''))
    //     {
    //        // usr.IsPortalEnabled = FALSE;             
    //         usr.IsActive = FALSE;
    //         usr.User_Deactivated__c = TRUE;
    //         usr.UserName = (usr.Id+'@deactivated.com');
    //         usr.FirstName = 'Deactivated '+usr.FirstName;
    //         usr.LastName = 'Deactivated '+usr.LastName;
    //         usr.Email = (usr.Id+'@deactivated.com');
             
    //         Database.DMLOptions dlo = new Database.DMLOptions();
    //         dlo.EmailHeader.triggerUserEmail = false;
    //         usr.setOptions(dlo);
     
    //         listUser.add(usr);    
    //     } 
        
    //     if(!listUser.isEmpty())
    //     {
    //         WithoutSharing.doUpdate(listUser);
    //     }

    // }

    // private static void doRevokeUserAccess3PLink(Map<String,String> mapUsrSSO_SlaveAcc)
    // //public static void revokeUserAccess3PLink(Map<String,String> mapUsrSSO_SlaveAcc)
    // {
    //     String authProviderId = '';//Provide the Auth. Provider Id
    //     String strUserId = '';//Provide the User Id
        
   
    //     ThirdPartyAccountLink[] userTPL = [ select id,Provider, UserId, RemoteIdentifier, SsoProviderId  from ThirdPartyAccountLink WHERE RemoteIdentifier IN :mapUsrSSO_SlaveAcc.keySet()];
    //     for(ThirdPartyAccountLink tpl : userTPL)
    //     {
    //         //For Facebook use facebook, for Google use google
    //     Boolean isOK = Auth.AuthToken.revokeAccess( tpl.SsoProviderId, tpl.Provider, tpl.UserId, tpl.RemoteIdentifier );
    //     system.debug( '--revokeUserAccess3PLink:  ' + isOK );
    //     }
        
    // }
 

    /*****************************************************************************************************************************
    @ Method:         removeLinkedAccount
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0010902 - Allow Sellers to unlink Accounts
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.05.2022 /Sophal Noch/ Created the  Method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> removeLinkedAccount(String accId)
    {
        Savepoint sp = Database.setSavepoint();
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        try {
            RecordType recSeller = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller');
            RecordType recGroup = ApexUtil.getRecordTypeByName('Account', 'Seller_Portal_Group');
            User cUser = [Select Id,ContactId,Contact.AccountId, Contact.Account.RecordTypeId, Contact.Account.Seller_Portal_Group__c From User Where Id=:UserInfo.getUserId()];
            if(cUser.Contact.Account.RecordTypeId == recSeller.Id && cUser.Contact.Account.Seller_Portal_Group__c == null){ // remove AccountContactRelation record when login User.Contact.Account.RecordType is EBH_Seller
                WithoutSharing.doDelete([Select Id From AccountContactRelation Where AccountId =: accId and ContactId =: cUser.ContactId AND IsDirect=FALSE]);
            }else{ // remove AccountContactRelation records when login User.Contact.Account.RecordType is in Seller_Portal_Group or login User.Contact.Account.RecordType is Seller But has Seller_Portal_Group__c
                Map<String, AccountContactRelation> mapAccIdToAcr = new Map<String, AccountContactRelation>();
                Id loginContactId = cUser.ContactId;
                String sqlAcrLoginUser = SOQL_ACR_LOGIN_USER;
                sqlAcrLoginUser = sqlAcrLoginUser.replace(':loginContactId',ApexUtil.closeSQoute(loginContactId));
                if(cUser.Contact.Account.RecordTypeId == recGroup.Id) sqlAcrLoginUser += ' And IsDirect = false';
                for(AccountContactRelation acr : (List<AccountContactRelation>)WithoutSharing.doQuery(sqlAcrLoginUser, '', '')){
                    mapAccIdToAcr.put(acr.AccountId, acr);
                }
                if(!mapAccIdToAcr.containsKey(accId)) return mapResult; 
                AccountContactRelation  selectedAcr = mapAccIdToAcr.remove(accId);
                if(mapAccIdToAcr.isEmpty()) return mapResult;  // do not remove when there is no EBH_Seller AccountContactRelation records left
                
                List<AccountContactRelation> listAcrToDelete = new List<AccountContactRelation>();
                Set<String> setAcrIdToDelete = new Set<String>();
                Map<Id, Account> mapAccToUpdate = new Map<Id, Account>();

                String soqlAcrInGroup = SOQL_ACR_IN_GROUP;
                Set<String> setContactId = new  Set<String>();
                Set<String> setAccId = mapAccIdToAcr.keySet();
                Id selectAccountId = selectedAcr.AccountId;
                Id sellerGroupId;
                if(cUser.Contact.Account.RecordTypeId == recGroup.Id || cUser.Contact.Account.Seller_Portal_Group__c == null){
                    // login as main sso user
                    sellerGroupId = cUser.Contact.AccountId; 
                }else{
                    // login as not main sso user. ex: using contact in sf to login as user.contact.account.recordtype = seller .
                    sellerGroupId = cUser.Contact.Account.Seller_Portal_Group__c; 
                }
                soqlAcrInGroup = soqlAcrInGroup.replace(':selectAccountId',ApexUtil.closeSQoute(selectAccountId));
                soqlAcrInGroup = soqlAcrInGroup.replace(':sellerGroupId',ApexUtil.closeSQoute(sellerGroupId));
                for(AccountContactRelation acr :(List<AccountContactRelation>)WithoutSharing.doQuery(soqlAcrInGroup,'','')){
                    if(!acr.isDirect){
                        listAcrToDelete.add(acr); // is used store ACR records of selected account in every Account in Group
                        setAcrIdToDelete.add(acr.Id);
                        if(!mapAccToUpdate.containsKey(acr.AccountId)) mapAccToUpdate.put(acr.AccountId, new Account(Id = acr.AccountId, Seller_Portal_Group__c = null, User_Disconnected__c = true));
                    }
                    if(acr.Contact.Original_Seller__c == selectedAcr.AccountId || selectedAcr.AccountId == acr.Contact.AccountId){
                        setContactId.add(acr.ContactId); // is used for querying ACR records of every account in group that exists in selected account contact.
                    }
                }

                String soqlAcrRelToSelectedAcc = SOQL_ACR_RELATED_TO_SELCTED_ACC;
                soqlAcrRelToSelectedAcc = soqlAcrRelToSelectedAcc.replace('IN:setContactId','IN('+ApexUtil.constructQuoteString(setContactId)+')');
                soqlAcrRelToSelectedAcc = soqlAcrRelToSelectedAcc.replace('IN:setAccId','IN('+ApexUtil.constructQuoteString(setAccId)+')');
                soqlAcrRelToSelectedAcc = soqlAcrRelToSelectedAcc.replace('IN:setAcrIdToDelete','IN('+ApexUtil.constructQuoteString(setAcrIdToDelete)+')');
                listAcrToDelete.addAll((List<AccountContactRelation>)WithoutSharing.doQuery(soqlAcrRelToSelectedAcc,'',''));

                if(!listAcrToDelete.isEmpty()){                   

                    IS_LINKING_ACCOUNT = true;
                    WithoutSharing.doDelete(listAcrToDelete);  // remove AccountContactRelation records from login user and ferderate users
                    mapAccToUpdate.putAll(populateSellerGroupSPFields(new Set<String>{sellerGroupId}, new Set<String>{selectAccountId})); // 31.08.2022 / Sophal Noch / US-0012302
                    WithoutSharing.doUpdate(mapAccToUpdate.values()); // update unlinked Account from Group by set Seller_Portal_Group__c = null.

                    // Map<String, String> mapContId = new Map<String, String>();
                    // String soqlCont = 'Select Id From Contact Where AccountId = '+ApexUtil.closeSQoute(sellerGroupId)+' AND Original_Seller__c='+ ApexUtil.closeSQoute(accId) +' AND RecordType.DeveloperName='+ ApexUtil.closeSQoute('Seller_Portal');
                    // for(Contact cont : (Contact[])WithoutSharing.doQuery(soqlCont, '', '')){
                    //     mapContId.put(cont.Id, cont.Id);
                    // }
                    // if(!mapContId.isEmpty()) deactivateOtherUser(mapContId); // 19.05.2022 / Sophal Noch / US-0010902 : deactivate user from an unlinked account.contacts
        
                    // //retstoreContact(accId);
                    // IS_LINKING_ACCOUNT = false;

                     // 25.05.2022 / Sophal Noch / US-0010902  :
                    Map<String,String> mapUsrSSO_SlaveCont = new Map<String,String>{'eBay_API_User_Id__c' => selectedAcr.Account.eBay_API_User_Id__c};
                    createW2CaseToDisconnectSPUser(selectedAcr.AccountId, mapUsrSSO_SlaveCont, false);
                    
                }


                
            }
        }catch(Exception e){Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',e.getMessage());mapResult.put('errorDetail',e.getStackTraceString());}
        return mapResult;
    }
    
    // private static void retstoreContact(String accId)
    // {
    //     //contact that moved to Group
    //     String soqlCont = 'Select Id, AccountId From Contact Where Original_Seller__c='+ApexUtil.closeSQoute(accId) +' AND RecordType.DeveloperName='+ ApexUtil.closeSQoute('Seller_Portal');
    //     Contact[] ssoCont = (Contact[])WithoutSharing.doQuery(soqlCont, '', '');
    //     if(!ssoCont.isEmpty())
    //     {
    //         RecordType rtContDWH = ApexUtil.getRecordTypeByName('Contact', 'EBH_DWH');
    //         Id accGroupId = ssoCont[0].AccountId;
    //         ssoCont[0].AccountId = accId;
    //         ssoCont[0].RecordTypeId = rtContDWH.Id; //moved back to DHW
            
    //         List<Contact> listContToDelete = new List<Contact>();
    //         String soqlAcc = 'Select Id,(Select Id,External_ID__c From Contacts Where ClonedSource__c='+ApexUtil.closeSQoute(ssoCont[0].Id)+') From Account Where Id='+ApexUtil.closeSQoute(accId);
    //         for(Account acc: (Account[])WithoutSharing.doQuery(soqlAcc, '', ''))
    //         {
    //             //contact that has been cloned
    //             for(Contact cont: acc.Contacts)
    //             {
    //                 ssoCont[0].External_ID__c = cont.External_ID__c;   //transfer ExtId before deletion
    //                 ssoCont[0].Original_Seller__c = null;
    //                 listContToDelete.add(cont);
    //             }
    //         }
    //         WithoutSharing.doUpdate(ssoCont);

    //         //  // 16.05.2022 / Sophal Noch / US-0010902 : below is deleting ACR of group because it is not direct relationship anymore
    //         WithoutSharing.doDelete((AccountContactRelation[])WithoutSharing.doQuery('Select Id From AccountContactRelation Where ContactId ='+ApexUtil.closeSQoute(ssoCont[0].Id)+' And AccountId ='+ApexUtil.closeSQoute(accGroupId)+' And isDirect = false', '', ''));
            
    //         if(!listContToDelete.isEmpty())
    //         {
    //             WithoutSharing.doDelete(listContToDelete);
    //         }
    //     }        
         
    // }

    /*********************************************************************************************************************************************************
    @ Method:         populateSellerGroupSPFields
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        US-0012302 - Seller Portal Group needs to reflect the SP field values in the Related Account
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 31.08.2022 / Sophal Noch / Created the  Method.
    @               : 05.09.2023 / Bora Chhorn / US-0014084 - SP Account Management Eligibility flag
    @               : 04.04.2025 / Sovantheany Dim / US-0016623 - Enable Link Multiple Account for NA
    @               : 17.04.2025 / vadhanak voun / US-0017119 - Linked Account - SP Promotion Manager reflect on the SP Group
    *********************************************************************************************************************************************************/
    public static Map<Id, Account> populateSellerGroupSPFields(Set<String> setSellerGroupId, Set<String> setUnlinkedAccountId){
        // when unlinking any account, this method populates seller group field SP_Deals__c and SP_Coupons__c to allowed or null depending on remaining linked account.
        // this method is reused in class EBH_AccountTriggerHandler so when any linked account SP_Deals__c and SP_Coupons__c is changed, this method populates seller group field SP_Deals__c and SP_Coupons__c to allowed or null.
        Map<Id, Account> mapAccToUpdate = new Map<Id, Account>();
        if(!setSellerGroupId.isEmpty()){
            String soqlAggrSellerGroup = SOQL_AGGR_SELLER_GROUP;
            soqlAggrSellerGroup = soqlAggrSellerGroup.replace('IN:setSellerGroupId','IN('+ApexUtil.constructQuoteString(setSellerGroupId)+')');
            soqlAggrSellerGroup = soqlAggrSellerGroup.replace('NOT IN:setUnlinkedAccountId','NOT IN('+ApexUtil.constructQuoteString(setUnlinkedAccountId)+')');
            for(AggregateResult aggr : (List<AggregateResult>)WithoutSharing.doQuery(soqlAggrSellerGroup,'','')){
                Account acc = new Account(
                    Id = Id.valueOf(aggr.get('spgId')+''), 
                    SP_Deals__c = Integer.valueOf(aggr.get('spDealsCount')) > 0 ? ACCESS_ALLOWED : null, 
                    SP_Coupons__c = Integer.valueOf(aggr.get('spCouponsCount')) > 0 ? ACCESS_ALLOWED : null,
                    SP_Account_Management__c = Integer.valueOf(aggr.get('spAccManagementCount')) > 0 ? ACCESS_ALLOWED : null, //BR 05-09-2023-US-0014084
                    NA_Deal_Program_Vetted__c = Integer.valueOf(aggr.get('spNaDealSubEligible')) > 0 ? true : false, //TH:05.04.2025:US-0016623 : Check with NA_Deal_Program_Vetted__c

                    SP_Promotions_Manager__c = Integer.valueOf(aggr.get('spPMCount')) > 0 ? ACCESS_ALLOWED : null //NK:17/04/2025:US-0017119 
                );
                mapAccToUpdate.put(acc.Id, acc);
            }
        }
        return mapAccToUpdate;
    }
    
}