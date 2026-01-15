/**
 * test class for DD_DisputeFormController.cls
 */
@isTest
public class DD_DisputeFormControllerTest {
    
     private static Map<String,Object> testSetupData(){

        Map<String,Object> mapResult = new Map<String,Object>();

        insert new EBH_ActiveTriggers__c(Name = 'EBH Trigger Controller',UserAvailabilityTrigger__c = true, EBH_TaskTrigger__c = true);
        User[] allAdmins = [Select Id From User where ProfileId=:ApexUtil.ADMIN_PROFILE_ID AND ISActive=true limit 2];
        Profile userProfile = [select Id,Name from Profile where Id =:UserInfo.getProfileId()];

        Account acc;
        Deal_Statement__c ds;
        Contact cont;
        User user;

        System.runAs(allAdmins[0]) {

            acc = new Account();
            acc.Name = 'AMT_Account';
            acc.BillingCountry = 'US';
            acc.NA_Deal_Program_Vetted__c = true;
            acc.NA_Deals_Subsidy_PayPal_Email__c = 'test@test.com';
            insert acc;

            ds = new Deal_Statement__c();
            ds.eBay_Seller__c = acc.Id;
            ds.Name = 'Test eBaySeller For Doc Approve 2';
            ds.Status__c = '1st Payout Approved';
            ds.Sold_item_effective_Date__c = System.Today().addMonths(-2);
            ds.Subsidy_30_day_calculation__c = 20;
            ds.Initial_Payout__c = 12;
            ds.Amount_Held_Back__c= 8;   
            insert ds;
            
            Deal_Timezone__c dealTimezone = new Deal_Timezone__c();
            dealTimezone.TimeZone__c='America/Los_Angeles';     
            insert dealTimezone;
            
            cont = new Contact();
            cont.LastName = 'AMT_Cont';
            cont.AccountId = acc.Id;
            cont.Contact_Role__c = 'Deals;NA Deals Statement Recipient';
            cont.Email = 'test@testtest.com';
            insert cont;

            user = new User();
            user.Alias='AMT';
            user.Email='amtmail@ebay.com';
            user.EmailEncodingKey='UTF-8';
            user.LastName='AMTUser';
            user.LanguageLocaleKey='en_US'; 
            user.LocaleSidKey='en_US';
            user.ProfileId = userProfile.Id;
            user.TimeZoneSidKey='America/Los_Angeles';
            user.UserName='amtmail@ebay.com';
            insert user;
            
        }
        
        Date myDate = System.Today().adddays(2);
        Time myTime = Time.newInstance(1, 1, 1, 1);

        Id euRecordTypeId = ApexUtil.getRecordTypeByName('EBH_Deal__c', 'Deal_V2').Id;
        List<EBH_Deal__c> listDeal = new List<EBH_Deal__c>();
        for(Integer i=0;i<2;i++){
            EBH_Deal__c deal1 = new EBH_Deal__c();
            deal1.RecordTypeId = euRecordTypeId;
            deal1.Deal_Statement__c = ds.Id;             
            deal1.Seller_Approver_1__c  = cont.Id;
            deal1.RecordTypeId = euRecordTypeId;
            deal1.Merchant_Approver__c = user.Id;
            deal1.EBH_BusinessName__c = acc.Id;
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
            deal1.Seller_Approver_1__c = cont.Id;
            deal1.Sold_Items_30_Days__c = 1;
            deal1.Sold_Items_60_Days__c = 2;
            deal1.Final_Sold_Items__c = 1; 
            deal1.EBH_DealSiteId__c = '77';
            deal1.EBH_MaximumPurchases__c = 1;

            listDeal.add(deal1);
        }
        insert listDeal;
        
       // String currentDigest = DD_Utils.doEncrypt(ds.Id,DD_Utils.encryptionkey);
        
       mapResult.put('listDeal',listDeal);
       mapResult.put('ds',ds);

       return mapResult;

    }
    @isTest 
    public static void testDispute(){
        
        Map<String,Object> mapResult = testSetupData();
        List<EBH_Deal__c> listDeal = (List<EBH_Deal__c>)mapResult.get('listDeal');
        Deal_Statement__c ds = (Deal_Statement__c)mapResult.get('ds');

        PageReference pageRef = Page.DD_DisputeForm; 
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('pid', ds.Id);

        Test.startTest();

            DD_DisputeFormController disputeCon = new DD_DisputeFormController();            
            disputeCon.limit_deals_size = 1;
            
            disputeCon.selectedId = listDeal[0].Id;
            DD_DisputeFormController.DealDTO d = new DD_DisputeFormController.DealDTO(listDeal[0]);
            
            
            disputeCon.searchItem = 'AMTProductTest';
            PageReference searchItem =  disputeCon.searchItemData();  
            System.assertEquals(searchItem,null);  
            
            PageReference next = disputeCon.next();  
            System.assertEquals(next,null); 
            
            PageReference prev = disputeCon.prev();  
            System.assertEquals(prev,null);
            
            PageReference selectAll = disputeCon.selectedAllItem();  
            System.assertEquals(selectAll,null);
            
            disputeCon.checkedAll = true;
            selectAll = disputeCon.selectedAllItem();  
            System.assertEquals(selectAll,null);
            
            PageReference selectItem = disputeCon.selectedItem();  
            System.assertEquals(selectItem,null);
            
            disputeCon.caseInfo.Reason = 'Quantity variance';
            PageReference changeType = disputeCon.getDisputeType();
            System.assertEquals(changeType,null);
            
            disputeCon.caseInfo.Reason = 'Deal omitted from statement';
            changeType = disputeCon.getDisputeType();
            System.assertEquals(changeType,null);
            
            disputeCon.caseInfo.Reason = 'Other';
            changeType = disputeCon.getDisputeType();
            System.assertEquals(changeType,null);
            
            PageReference addDealOmit = disputeCon.addAnotherDeal();
            System.assertEquals(addDealOmit,null);
            
            disputeCon.dealOmitDeleteIndex = 1;
            PageReference removeDealOmit = disputeCon.deleteDeal();
            System.assertEquals(removeDealOmit,null);
            
            disputeCon.caseInfo.Description = 'Test desc'; 
            
            PageReference createCaseUpdateD = disputeCon.createCaseUpdateDeal();
            System.assertEquals(createCaseUpdateD,null);
            
            disputeCon.Description = 'Test desc2'; 
            disputeCon.createCaseUpdateDeal();

            DD_DisputeFormController.DealOmittedDTO dealO = new DD_DisputeFormController.DealOmittedDTO('123456789','test 001',System.Today(),System.Today().adddays(2));
            disputeCon.dealOmitted.add(dealO);
            PageReference createCase = disputeCon.createCaseDeal();
            System.assertEquals(createCase,null);
            
            disputeCon.caseInfo.SuppliedName = 'test';
            disputeCon.caseInfo.SuppliedEmail = 'test@test.test';
            PageReference createCaseOther = disputeCon.createCaseDealOther();
            System.assertEquals(createCaseOther,null);

            disputeCon.getDisputeTypeQV();
            disputeCon.getDisputeTypeSPU();
            disputeCon.getDisputeTypeDOS();
            disputeCon.getDisputeTypeOTH();
            Integer i1 = disputeCon.mapItemsSize;
            Boolean b = disputeCon.isDisputeWindowClose;
            String s1 = disputeCon.suppliedName;
            String s2 = disputeCon.suppliedEmail;

        Test.stopTest();
    }
}