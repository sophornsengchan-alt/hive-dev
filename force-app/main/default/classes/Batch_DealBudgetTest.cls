/************************************************************************************************************************************
@ Class:          Batch_DealBudgetTest
@ Version:        1.0
@ Author:         Acmatac SEING (acmatac.seing@gaea-sys.com)
@ Purpose:        US-0009132 - [EU Deals] Deals Budget & Deal Budget Month Batch Process
--------------------------------------------------------------------------------------------------------------------------------------
@ Change history: 23.04.2021 / Acmatac SEING / Created the test class.
**************************************************************************************************************************************/


@isTest
private class Batch_DealBudgetTest {
    private static Id dealRT_V1 = ApexUtil.getRecordTypeByName('EBH_Deal__c','Deal_V1').Id;
    private static Id accountRT_Seller = ApexUtil.getRecordTypeByName('Account','EBH_Seller').Id;

    @TestSetup
    static void makeData(){
		Date currentDay = Date.today();
        Map<Integer, String> mMonth = new Map<Integer, String>{
			1=> 'January', 
			2=> 'February', 
			3=> 'March', 
			4=> 'April',
			5=> 'May',
			6=> 'June',
			7=> 'July',
			8=> 'August',
			9=> 'September',
			10=> 'October',
			11=> 'November',
			12=> 'December'
		};
        //nextYear = nextYear.addYears(1);
        EBH_DealsBudget__c db1 = new EBH_DealsBudget__c(
            Deal_Site__c='3', 
            EBH_Vertical__c='P&A', 
            EBH_Quarter__c = 'Q3',
            Year__c = String.valueOf(currentDay.year()),
            Non_Payout_Items_Estimate__c = 20
        );
        EBH_DealsBudget__c db2 = new EBH_DealsBudget__c(
            Deal_Site__c = '3', 
            EBH_Vertical__c = 'Fashion', 
            EBH_Quarter__c = 'Q3',
            Year__c = String.valueOf(currentDay.year()),
            Non_Payout_Items_Estimate__c = 10
        );
        insert new List<EBH_DealsBudget__c>{db1,db2};
            
        EBH_DealsBudgetMonth__c dbm1 = new EBH_DealsBudgetMonth__c(EBH_DealsBudget__c=db1.Id,EBH_Month__c= mMonth.get(currentDay.month()));
        EBH_DealsBudgetMonth__c dbm2 = new EBH_DealsBudgetMonth__c(EBH_DealsBudget__c=db2.Id,EBH_Month__c= mMonth.get(currentDay.month()));
        insert new List<EBH_DealsBudgetMonth__c>{dbm1,dbm2};

        Account acc1 = new Account(
            RecordTypeId = accountRT_Seller,
            Name = 'Seller',
            EBH_VATNumber__c = 'VAT1111',
            EBH_RegistrationCountry__c = 'United Kingdom'
        );
        insert acc1;
        Date tmr = Date.today();
        tmr = tmr.addDays(1);
        List<EBH_Deal__c> lstDeal = new List<EBH_Deal__c>();
        for(Integer i=1;i<=5;i++){
            for(Integer j=1;j<=2;j++){
                lstDeal.add(new EBH_Deal__c(
                    RecordTypeId = dealRT_V1,
                    EBH_DealSiteId__c = '3',
                    EBH_SellerPrice__c=1000,
                    EBH_DealPrice__c=200,
                    EBH_SoldItems__c=2,
                    EBH_Vertical__c= i<=3 ? 'P&A' : 'Fashion',
                    EBH_DealStartDate__c = currentDay,
                    EBH_DealEndDate__c = currentDay.addDays(10),
                    EBH_MaximumPurchases__c = 100,
                    EBH_Status__c='Running',
                    EBH_Category__c='Art',
                    EBH_ProductTitle__c='product 1',
                    EBH_SellerEmail__c='sales@test.com',
                    EBH_Quantity__c=5,
                    EBH_DealFormat__c = 'iji',
                    EBH_BusinessName__c = acc1.Id,
                    Subsidy_Running__c = 10,
                    EBH_Payout_SI__c = 10,
                    EBH_DealTrackingEndDate__c = tmr
                ));
            }
        }
        insert lstDeal;
    }
	
    @isTest
    static void Batch_DealBudgetTest() {
        
        Set<Id> dIds = new Set<Id>();
        Set<Id> dbIds = new Set<Id>();
        Set<Id> dbmIds = new Set<Id>();
        for(EBH_DealsBudgetMonth__c oD: [SELECT Id, EBH_DealsBudget__c FROM EBH_DealsBudgetMonth__c]){
            dbIds.add(oD.EBH_DealsBudget__c);
            dbmIds.add(oD.Id);
        }
        for(EBH_Deal__c d: [SELECT Id, Unique_Budget_Month__c FROM EBH_Deal__c]){
            dIds.add(d.Id);
        }
        Test.startTest();	
            Database.executeBatch(new Batch_DealBudget());
            Database.executeBatch(new Batch_DealBudget(dIds));
        	Database.executeBatch(new Batch_DealBudget('DBM',dbIds,dbmIds));
        Test.stopTest();   
    }
}