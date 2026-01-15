/*********************************************************************************************************************************
@ Class:        AccountPickerController
@ Version:      1.0
@ Author:       Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:      Controller for lwcAccountPicker  
@               US-0010950 - Account Selection field on Deal Creation/List Views
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.04.2022 / mony nou / Created the class.
@               : 14.06.2022 / SRONG TIN / US-0011345 AC7
@               : 29.08.2022 / Sophal Noch / US-0012311 - Seller filter on calendar displaying for deal only sellers
@               : 31.08.2022 / Mony Nou / US-0011362 - [DE Launch Day] Grant access to users for Coupon launch
@               : 17.10.2022 / Bora Chhorn / US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
@               : 20.12.2023 / SRONG TIN / US-0014594 - Secure Coding - Tech Debt : AccountPickerController
*********************************************************************************************************************************/
public with sharing class AccountPickerController {
    
    //private static final String ELIGIBLE_FOR_DE_DEALS = 'Eligible_for_DE_Deals_Full_Access'; // BR-17-10-2022-US-0012600
    private static final String ELIGIBLE_FOR_DEALS_FULL_ACCESS = 'Eligible_for_Deals_Full_Access'; // BR-17-10-2022-US-0012600
    private static final String ELIGIBLE_FOR_DE_COUPONS = 'Eligible_for_DE_Coupons_Full_Access'; //MN-31082022-US-0011362
    private static final String FULL_ACCESS = 'Full Access';
    private static final String RT_SELLER = 'EBH_Seller';
    //SRONG TIN 20.12.2023 / US-0014594
    private static final String U_QUERY = 'Select Id,UserName,Email,ContactId,Contact.RecordType.DeveloperName,Contact.AccountId,Contact.Account.OwnerId From User';
    private static final String S_QUERY = 'Select Id,AccountId,Account.Name,Account.SP_Coupons__c,Account.SP_Deals__c,Contact.Name,Contact.Email,ContactId,IsActive From AccountContactRelation';
    private static final String M_QUERY = 'Select Id,DeveloperName,Filter_Values__c from Seller_Portal_Setting__mdt';

    /*********************************************************************************************************************************
    @ method:       getDEEligibleAccounts
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      US-0010950 - Account Selection field on Deal Creation/List Views
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2022 / Mony Nou / Created the method.
    @               : 14.06.2022 / SRONG TIN / US-0011345 AC7
    @               : 29.08.2022 / Sophal Noch / US-0012311 - Seller filter on calendar displaying for deal only sellers
    @               : 17.10.2022 / Bora Chhorn / US-0012600 - Enable Link Multiple Accounts for NA/ AU Portal Sellers
    @               : 20.12.2023 / SRONG TIN / US-0014594 - Secure Coding - Tech Debt : AccountPickerController
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> getDEEligibleAccounts()
    {
        //SRONG TIN 20.12.2023 / US-0014594 
        List<String> sepEligible = new List<String>{ELIGIBLE_FOR_DEALS_FULL_ACCESS,ELIGIBLE_FOR_DE_COUPONS}; //MN-31082022-US-0011362
        String sepEligibleText = '(' + ApexUtil.closeSQoute(String.join(sepEligible, '\',\'')) + ')';
        String mWhere = ' Where DeveloperName IN '+sepEligibleText;
        List<Seller_Portal_Setting__mdt> meta = ApexSafe.query().doQuery(M_QUERY + mWhere);
        return getDEEligibleAccountsByMetadata(meta);
    }

    /*********************************************************************************************************************************
    @ method:       getDEEligibleAccountsByMetadata
    @ Version:      1.0
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0012311 - Seller filter on calendar displaying for deal only sellers
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history    : 29.08.2022 / Sophal Noch / US-0012311 create method
    @                   : 20.12.2023 / SRONG TIN / US-0014594 - Secure Coding - Tech Debt : AccountPickerController
    *********************************************************************************************************************************/
    public static Map<String,Object> getDEEligibleAccountsByMetadata(List<Seller_Portal_Setting__mdt> listMeta)
    {
        //SRONG TIN 20.12.2023 / US-0014594
         String uWhere = ' Where Id='+ApexUtil.closeSQoute(UserInfo.getUserId());
         List<User> sObjectList = ApexSafe.query().doQuery(U_QUERY + uWhere);
         User currentUser = sObjectList[0];
     	
        Map<String,AccountContactRelation> mapRelation = new Map<String,AccountContactRelation>();
        Map<String,AccountContactRelation> mapRelationDeals = new Map<String,AccountContactRelation>();
        Map<String,AccountContactRelation> mapRelationCoupons = new Map<String,AccountContactRelation>();

        String sFilter = '';

        List<String> listFilter = new  List<String>();
        for(Seller_Portal_Setting__mdt meta : listMeta){
            listFilter.add(meta.Filter_Values__c);
        }

        sFilter = String.join(listFilter,' OR ');

        String sWhere = ' Where Account.RecordType.DeveloperName ='+ApexUtil.closeSQoute(RT_SELLER)+' and ContactId='+ApexUtil.closeSQoute(currentUser.ContactId);
        sWhere += ' AND AccountId IN (SELECT Id FROM Account WHERE '+ sFilter +')';
        //SRONG TIN 20.12.2023 / US-0014594
        List<AccountContactRelation> accContactRelations = ApexSafe.query().doQuery(S_QUERY + sWhere);
        for(AccountContactRelation acr : accContactRelations) {
            if(acr.Account.SP_Coupons__c == FULL_ACCESS){mapRelationCoupons.put(acr.AccountId,acr);}
            if(acr.Account.SP_Deals__c == FULL_ACCESS){mapRelationDeals.put(acr.AccountId,acr);}
            mapRelation.put(acr.AccountId,acr);
        }
        return new Map<String,Object> {'curentUser'=>currentUser,'accRelation'=>mapRelationDeals.values(),'accRelationCoupons'=>mapRelationCoupons.values(),'accRelationAll'=>mapRelation.values()};
    }

}