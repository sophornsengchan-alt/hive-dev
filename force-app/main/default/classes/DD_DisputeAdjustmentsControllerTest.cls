@isTest 
private class DD_DisputeAdjustmentsControllerTest {

    private static Map<String,Object> setupData() {

        Map<String,Object>  mapResult = new Map<String,Object> ();

        Profile adminProfile = [select Id,Name from Profile where Id =:UserInfo.getProfileId()];

        User[] allAdmins = [Select Id From User where ProfileId=:ApexUtil.ADMIN_PROFILE_ID AND ISActive=true limit 2];

        User user = new User();
        Account acc;
        Contact cont;
        Deal_Statement__c ds1;

        System.runAs(allAdmins[0]) {

            Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
            dealTimezone.TimeZone__c='America/Los_Angeles';     
            insert dealTimezone;

            acc = new Account();
            acc.Name = 'AMT_Account';
            acc.BillingCountry = 'US';
            acc.NA_Deal_Program_Vetted__c = true;
            acc.NA_Deals_Subsidy_PayPal_Email__c = 'test@test.com';
            insert acc;       

            cont = new Contact();
            cont.LastName = 'AMT_Cont';
            cont.AccountId = acc.Id;
            cont.Email = 'test@test.com';
            cont.Contact_Role__c = 'Deals;NA Deals Statement Recipient';
            insert cont;

            // Spotlight_Category__c spCat = new Spotlight_Category__c();
            // spCat.Name = 'AMT_Spotligth NA';
            // spCat.Country__c = 'NA';
            // spCat.Spotlight_Category_ID__c = 'SCiD-934035';
            // spCat.Vertical__c = 'Fashion';
            // insert spCat;        
            Date myDate = System.Today().adddays(2);

            ds1 = new Deal_Statement__c();
            ds1.Name = acc.Name+myDate.month()+'Statement';
            ds1.Subsidy_Final_Calculation__c=0;                 
            ds1.Status__c = '1st Statement';
                
            ds1.eBay_Seller__c =acc.Id ;
            ds1.Subsidy_Final_Calculation__c=0;
            
                
            insert ds1;


            user = new User();
            user.Alias='AMT';
            user.Email='amtmail@ebay.com';
            user.EmailEncodingKey='UTF-8';
            user.LastName='AMTUser';
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US';
            user.ProfileId = adminProfile.Id;
            user.TimeZoneSidKey='America/Los_Angeles';
            user.UserName='amtmail@ebay.com';
            insert user;
            
        }

        


        EBH_Deal__c deal1 = createDeal(ds1.Id,acc.Id,user.Id,cont.Id);  
        deal1.Dispute_Type__c = 'Quantity Variance';

        EBH_Deal__c deal2 = createDeal(ds1.Id,acc.Id,user.Id,cont.Id); 
        deal2.Dispute_Type__c = 'Subsidy per Unit';

        insert new List<EBH_Deal__c>{deal1,deal2};          
       
        mapResult.put('deal1',deal1);
        mapResult.put('deal2',deal2);
        mapResult.put('ds1',ds1);


        

       return mapResult;

        
    }
   
    @isTest 
    public static void testAdjustDispute () {
        
        Map<String,Object>  mapResult = setupData();

        Date myDate = System.Today().adddays(2);
        String dsname = 'AMT_Seller'+myDate.month()+'Statement';
        Deal_Statement__c ds1 =  (Deal_Statement__c)mapResult.get('ds1');
        
        Map<String, Object> mpRes = DD_DisputeAdjustmentsController.getDeals(ds1.Id);

        // assert data
        List<String> picklistObjs = new List<String>();
        picklistObjs.add('EBH_Deal__c');
        List<String> picklistFields = new List<String>();
        picklistFields.add('Dispute_Status__c');

        Map<String,List<String>> getPicklistValue = DD_DisputeAdjustmentsController.getPicklistValueData(picklistObjs,picklistFields); 
                        
        // update some deal comment and dispute price
        List<DD_DisputeAdjustmentsController.RowData> rowLst = (List<DD_DisputeAdjustmentsController.RowData>)mpRes.get('dealList');
       
        for (DD_DisputeAdjustmentsController.RowData d : rowLst) {
                                
            for (DD_DisputeAdjustmentsController.ColData cd : d.rowData) {
                        
                if (cd.colApiName=='Dispute_Approval_Comments__c') {
                        cd.value ='Test comment';
                    }  else if (cd.colApiName=='Sold_Items_Disputes__c') {
                        
                        cd.value ='100';
                    }                   
                }               
            } 
        
        // json
        String rowdatajson = Json.serialize(rowLst);
             
        // save    
        Map<String, Object> res = DD_DisputeAdjustmentsController.save(rowdatajson);
        
        
        // select data and assert
        List<EBH_Deal__c> deals = [select Id, Sold_Items_Disputes__c,Dispute_Approval_Comments__c from EBH_Deal__c where Deal_Statement__c=:ds1.Id ];
        
        for (EBH_Deal__c d : deals) {
            
             System.assertEquals('Test comment',d.Dispute_Approval_Comments__c);
             System.assertEquals(100,d.Sold_Items_Disputes__c);
             
        }           
       
   }
    
   static EBH_Deal__c createDeal(String dsId,String accId,String mApprId,String sApprId)
   {
        Id euRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;
        Date myDate = System.Today().adddays(2);
        Time myTime = Time.newInstance(1, 1, 1, 1);

       EBH_Deal__c deal1 = new EBH_Deal__c();
           deal1.RecordTypeId = euRecordTypeId;
           deal1.Deal_Statement__c = dsId;             
           deal1.RecordTypeId = euRecordTypeId;
           deal1.Merchant_Approver__c = mApprId;
           deal1.EBH_BusinessName__c = accId;
           deal1.EBH_ProductTitle__c = 'AMTProductTest';
           deal1.EBH_DealSiteId__c = '0';
	       deal1.EBH_Vertical__c = 'Home & Garden';
	       deal1.EBH_Category__c='Home & Garden';
	       deal1.Sub_Category__c = 'Bedding';
           deal1.EBH_DealFormat__c = 'Primary';
           deal1.EBH_DealStartDate__c = myDate;
           deal1.EBH_DealStartTime__c = myTime;
           deal1.EBH_DealEndDate__c = myDate;
           deal1.EBH_DealEndTime__c = myTime;
           deal1.EBH_Status__c = 'New';
           deal1.EBH_Quantity__c = 1;
           deal1.Quantity_Limitation_per_Purchaser__c = 1;
           deal1.EBH_DealPrice__c = 1;
           deal1.EBH_SellerPrice__c = 1;
           deal1.EBH_SoldItemsForecast__c = 123456;
           deal1.Seller_Approver_1__c = sApprId;
           deal1.Sold_Items_30_Days__c = 1;
           deal1.Sold_Items_60_Days__c = 2;
           deal1.Final_Sold_Items__c = 1; 
           deal1.EBH_DealSiteId__c = '77';
           deal1.EBH_MaximumPurchases__c = 1;

           return deal1;
   }
}