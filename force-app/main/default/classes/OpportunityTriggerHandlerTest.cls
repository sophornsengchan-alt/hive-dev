/*****************************************************************************************************************************
@ Class:          OpportunityTriggerHandlerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test Class for OpportunityTriggerHandler
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  24.08.2020 / Sophal Noch / Created the method.
@ Change history:  20.10.2022 / Bora Chhorn / US-0012489 - Fix failing test class OpportunityTriggerHandlerTest
@               :  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
@               :   22.10.2024 / Vimean Heng / US-0015586 - SAP for ADS - Duration Formula enhancement
@*****************************************************************************************************************************/
@isTest
private class OpportunityTriggerHandlerTest {

    public static Account account;
    public static Opportunity opp;
    public static Opportunity opp2;
    public static Integer currentYear = System.Today().year();

    public static Date startDate;
    public static Date endDate;

    public static Decimal opp1DefaultAmount = 100;

    private static void setUpOpp(){

        byPass__c bp = new byPass__c(SetupOwnerId = UserInfo.getUserId(), triggerObjects__c = 'Opportunity Quote QuoteLineItem', byPass_Trigger__c = false,ByPass_Validation__c=true,byPass_WFRule__c=true);
        insert bp;

        account = TST_DataGenerator.generateAccount();
        insert account;

        Contact con = new Contact(FirstName='test fn', LastName='test ln', AccountId=account.Id, Contact_Role__c='Billing Contact');
        insert con;

        startDate = Date.today();
        endDate = startDate.addMonths(3);

        opp = new Opportunity(
                Name = 'Opp',
                Amount = opp1DefaultAmount,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate,
                RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay')?.Id,
                Bill_To_Party__c = 'Advertiser',
                AccountId = account.Id
        );
        insert opp;

        opp2 = new Opportunity(
                Name = 'Opp',
                Amount = opp1DefaultAmount,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 7, 1),
                Start_Date__c = Date.newInstance(currentYear, 1, 1),
                End_Date__c = Date.newInstance(currentYear, 6, 1),
                RecordTypeId = ApexUtil.getRecordTypeByName('Opportunity','eBay')?.Id,
                Bill_To_Party__c = 'Advertiser',
                AccountId = account.Id,
                Payment_Terms__c = 'quarterly'
        );
        insert opp2;
    }


    /*****************************************************************************************************************************
    @ Method:       testGeneratingAdProductWithoutPrimaryQuote
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      test method for story US-0008007
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.08.2020  / Sophal Noch / Created the  method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.10.2020  / Sophal Noch / US-0008451 update the  method name and add test more case for US-0008451.
    @ Change history:  20.10.2022  / Bora Chhorn / US-0012489 - Fix failing test class OpportunityTriggerHandlerTest
    @*****************************************************************************************************************************/ 
    static testMethod void testGeneratingAdProductWithoutPrimaryQuote(){
        // add start date and end date for case in US-0008451
        setUpOpp();
        
        List<Ad_Product__c> adProductList = [
                SELECT Id, 
                TotalPrice__c, 
                Opportunity__c,
                from_Date__c,
                until_Date__c
                FROM Ad_Product__c Where Opportunity__c =: opp.Id
                ORDER BY Opportunity__c ASC
        ];

        System.assertEquals(1, adProductList.size());
        System.assertEquals(opp.Amount,adProductList[0].TotalPrice__c);
        System.assertEquals(opp.Start_Date__c,adProductList[0].from_Date__c);
        System.assertEquals(opp.End_Date__c,adProductList[0].until_Date__c);

        opp.Amount = 200;

        Opportunity opp2 = new Opportunity(
                Name = 'Opp 3',
                Amount = 900,
                StageName = 'Qualified Meeting',
                CloseDate = Date.newInstance( currentYear, 1, 1),
                Start_Date__c = startDate,
                End_Date__c = endDate
        );

        upsert new List<Opportunity>{opp,opp2};

        List<Ad_Product__c> adProductListAfterOppUpsert = [
                SELECT Id, 
                TotalPrice__c, 
                Opportunity__c,
                from_Date__c,
                until_Date__c
                FROM Ad_Product__c Where Opportunity__c =: opp.Id OR Opportunity__c =: opp2.Id
                ORDER BY Opportunity__c ASC
        ];

        System.assertEquals(2, adProductListAfterOppUpsert.size());

        System.assertEquals(opp.Amount,adProductListAfterOppUpsert[0].TotalPrice__c);
        System.assertEquals(opp.Start_Date__c,adProductListAfterOppUpsert[0].from_Date__c);
        System.assertEquals(opp.End_Date__c,adProductListAfterOppUpsert[0].until_Date__c);

        System.assertEquals(opp2.Amount,adProductListAfterOppUpsert[1].TotalPrice__c);
        System.assertEquals(opp2.Start_Date__c,adProductListAfterOppUpsert[1].from_Date__c);
        System.assertEquals(opp2.End_Date__c,adProductListAfterOppUpsert[1].until_Date__c);

        // update start date and end date for case in US-0008451
        opp.Amount = 111;
        opp.End_Date__c = endDate.addMonths(1);

        opp2.Amount = 333;
        opp2.End_Date__c = endDate.addMonths(1);

        List<Opportunity> oppListToUpdate = new List<Opportunity>{opp,opp2};

        Test.startTest(); 

        Database.SaveResult[] savedList = Database.update(oppListToUpdate, false);

        List<Ad_Product__c> adProductListAfterFinalOppUpdate = [
                SELECT Id, 
                TotalPrice__c, 
                Opportunity__c,
                from_Date__c,
                until_Date__c
                FROM Ad_Product__c Where Opportunity__c =: opp.Id OR Opportunity__c =: opp2.Id
                ORDER BY Opportunity__c ASC
        ];

        System.assertEquals(2, adProductListAfterFinalOppUpdate.size());

        // compare start date and end date for case in US-0008451

        opp.Amount = 400;
        opp.Quote_Sync_In_Progress__c = true;
        opp2.Amount = 600;

        oppListToUpdate = new List<Opportunity>{opp,opp2};

        savedList = Database.update(oppListToUpdate, false);

        System.assertEquals(true,savedList[0].isSuccess());
        System.assertEquals(true,savedList[1].isSuccess());

        Test.stopTest(); 

    }

    /*****************************************************************************************************************************
    @ Method:       testGeneratingAdProductWithPrimaryQuote
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      test method for story US-0008451
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.10.2020  / Sophal Noch / Created the  method.
    @ Change history:  20.10.2022  / Bora Chhorn / US-0012489 - Fix failing test class OpportunityTriggerHandlerTest
    @*****************************************************************************************************************************/ 
    static testMethod void testGeneratingAdProductWithPrimaryQuote(){
        Test.startTest(); 
        setUpOpp();

        Date newStartDate = Date.today().addYears(1);
        Date newEndDate = newStartDate.addMonths(5);

        opp.Start_Date__c = newStartDate;
        opp.End_Date__c = newEndDate;
        opp.Amount = 111;

        update new List<Opportunity>{opp};

        List<Ad_Product__c> adProductListAfterOppUpdate = [
                SELECT Id, 
                Opportunity__c,
                from_Date__c,
                until_Date__c,
                TotalPrice__c
                FROM Ad_Product__c Where Opportunity__c =: opp.Id
                ORDER BY Opportunity__c ASC
        ];

        // not equal for opp
        System.assertEquals(opp.Start_Date__c,adProductListAfterOppUpdate[0].from_Date__c);
        System.assertEquals(opp.End_Date__c,adProductListAfterOppUpdate[0].until_Date__c);
        System.assertEquals(opp.Amount,adProductListAfterOppUpdate[0].TotalPrice__c);

        // equal for opp
        System.assertNotEquals(startDate,adProductListAfterOppUpdate[0].from_Date__c);
        System.assertNotEquals(endDate,adProductListAfterOppUpdate[0].until_Date__c);
        System.assertNotEquals(opp1DefaultAmount,adProductListAfterOppUpdate[0].TotalPrice__c);

        Test.stopTest(); 

    }

  /*********************************************************************************************************************************
    @ Method:         testPopulateBillInv
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   24.04.2024 / Sophal Noch / Created the method.
    @               :   22.10.2024 / Vimean Heng / US-0015586 - SAP for ADS - Duration Formula enhancement / Related To US-0015475 : BillingInvoice__c create when opportunity change to closed won. I have to remove this method.
    *********************************************************************************************************************************/ 
    /*
    static testMethod void testPopulateBillInv(){
        Test.startTest(); 
                setUpOpp();
        Test.stopTest();
        List<BillingInvoice__c> billInvList = [SELECT Id FROM BillingInvoice__c Where RelatedBillingOpportunity__c =: opp.Id];
        System.assert(billInvList.size() > 0);
        List<Ad_Revenue_Monthly__c> listMonthly = [Select Id From Ad_Revenue_Monthly__c Where BillingInvoice__c IN: billInvList];
        System.assertEquals(0, listMonthly.size());
    }
    */
   /*********************************************************************************************************************************
    @ Method:         testPopulateBillInvClosedWon
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   24.04.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/ 
    static testMethod void testPopulateBillInvClosedWon(){
        setUpOpp();

        Test.startTest(); 
                opp.StageName = 'Closed Won';
                update opp;
        Test.stopTest();

        List<BillingInvoice__c> billInvList = [SELECT Id FROM BillingInvoice__c Where RelatedBillingOpportunity__c =: opp.Id];
        System.assert(billInvList.size() > 0);
        List<Ad_Revenue_Monthly__c> listMonthly = [Select Id From Ad_Revenue_Monthly__c Where BillingInvoice__c IN: billInvList];
        System.assert(listMonthly.size() > 0);
    }

    /*********************************************************************************************************************************
    @ Method:         testValidateOppClosedWon
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   25.04.2024 / Bora Chhorn / Created the method.
    *********************************************************************************************************************************/
    static testMethod void testValidateOppClosedWon(){
        setUpOpp();
        Test.startTest();
                opp.StageName = 'Closed Won';
                opp.Bill_To_Party__c = 'Advertiser';
                update opp;
        Test.stopTest();

        Contact con = [SELECT Id FROM Contact WHERE AccountId =: opp.AccountId];
        List<BillingInvoice__c> billInvList = [SELECT Id, InvoiceRecipient__c FROM BillingInvoice__c Where RelatedBillingOpportunity__c =: opp.Id];
        System.assert(billInvList.size() > 0);
        for(BillingInvoice__c bi : billInvList){
                System.assertEquals(bi.InvoiceRecipient__c, con.Id);
        }
    }

    /*********************************************************************************************************************************
    @ Method:         testPopulateBillInvClosedWon_Quarterly
    @ Version:        1.0
    @ Author:         Acmatac Seing
    @ Purpose:        22.05.2024 / Acmatac Seing / US-0015036 - 2.2 SAP for ADS - Billing Invoice record creation (quarterly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   22.05.2024 / Acmatac Seing / Created the method.
    *********************************************************************************************************************************/ 
    static testMethod void testPopulateBillInvClosedWon_Quarterly(){
        setUpOpp();

        Test.startTest(); 
                opp2.StageName = 'Closed Won';
                update opp2;
        Test.stopTest();

        // 6Months = 6RM
        List<Ad_Revenue_Monthly__c> listMonthly = [Select Id From Ad_Revenue_Monthly__c Where Opportunity__c =: opp2.Id];
        System.assertEquals(6, listMonthly.size());

        // 6Months => 1(Jan,Feb,Mar) 2(Apr,May,June) => 2 Billing Invoice
        List<BillingInvoice__c> billInvList = [SELECT Id FROM BillingInvoice__c Where RelatedBillingOpportunity__c =: opp2.Id];
        System.assertEquals(2, billInvList.size());
    }
    
    @isTest
    private static void testAutoLinkSeller(){
		EBH_TestDataFactory.setUpCustomSettings();
		List<Account> listSeller =  EBH_TestDataFactory.createAccounts(2, 'EBH_Seller') ;
		listSeller[0].Name = 'TEST Seller AMT 01';
    	listSeller[0].EBH_OracleId__c = '111222333';

		listSeller[1].Name = 'TEST Seller AMT 02';
    	listSeller[1].EBH_OracleId__c = '444555666';
		update listSeller;

		Opportunity myOppo = new Opportunity();
		myOppo.RecordTypeId = OpportunityTriggerHandler.opportunityRecTypeBD.Id;
		myOppo.Seller__c = listSeller[0].Id;
        myOppo.Name = 'TEST Oppo';
        myOppo.StageName = 'Discovery';
        myOppo.CloseDate = System.today();
		insert myOppo;

		Test.startTest();
            Opportunity oOppo = [SELECT Name, Seller__c, Oracle_ID__c, Seller_Name__c FROM Opportunity WHERE Id=:myOppo.Id];
			System.assertEquals(oOppo.Oracle_ID__c, listSeller[0].EBH_OracleId__c, ' OracleId should be inherited from Seller');
			System.assertEquals(oOppo.Seller_Name__c, listSeller[0].Name, ' SellerName should be inherited from Seller');
			
			oOppo.Seller__c = null;
			oOppo.Oracle_ID__c = '444555666';
			update oOppo;
			oOppo = [SELECT Name, Seller__c, Oracle_ID__c, Seller_Name__c FROM Opportunity WHERE Id=:myOppo.Id];
			System.assertEquals(oOppo.Seller__c, listSeller[1].Id, ' Seller should be == Seller of that oracleId');
			System.assertEquals(oOppo.Seller_Name__c, listSeller[1].Name, ' SellerName should be inherited from Seller');
		Test.stopTest();
	}
    
}