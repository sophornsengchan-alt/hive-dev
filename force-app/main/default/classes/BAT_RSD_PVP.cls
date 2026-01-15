/*********************************************************************************************************************************
@ Class:          BAT_RSD_PVP
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0009295 - Migrate BAT_RSD_PVP from EU Ads to Hive. 
                  This class is migrated From EU instance class 'BAT_RSD_PVP'
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  12.04.2021 / Sophal Noch / Created the class. Run BAT_RSD_PVP_Test for test coverage
@ Change history:  02.08.2021 / Sophal Noch / US-0010063 Modified method.
@ Change history:  04.07.2023 / Sophal Noch / US-0013851 - ADS - Incorrect revenue calculation for Callisto CPM
*********************************************************************************************************************************/
global with sharing class BAT_RSD_PVP implements Database.Batchable<SObject>, Schedulable{

    private final static String SUM_X3_PARTY_GROSS = 'sumX3PartyGross';
    private final static String SUM_X3_PARTY_CLICK = 'sumX3PartyClick';
    private final static String SUM_X_PARTY_AI = 'sumXPartyAI';

    private final static String AD_REVENUE_MONTHLY_NAME = 'Ad_Revenue_Monthly__c';
    

    private final static String REV_DAILY_QUERY = 'Select Ad_Revenue_Monthly__c, sum(X3rd_Party_Gross__c) '+SUM_X3_PARTY_GROSS+', sum(X3rd_Party_Clicks__c) '+SUM_X3_PARTY_CLICK+', sum(X3rd_Party_AI__c) '+SUM_X_PARTY_AI+' From Ad_Revenue_Daily__c WHERE Ad_Revenue_Monthly__c IN: scope Group By Ad_Revenue_Monthly__c';

    private final static String REV_MONTHLY_QUERY = 'Select Id,Billing_Category__c, X3rd_Party_Monthly_Gross__c, X3rd_Party_Clicks__c, X3rd_Party_AI__c  From Ad_Revenue_Monthly__c Where Transaction_Date__c {!condition} {!transactionDate} And Ad_Product__r.Product2__r.Callisto__c= true Order By Ad_Product__c, Transaction_Date__c';


    // private static final String BILLING_CATEGORY_CPC = 'CPC';
    private static final Set<String> SET_BILL_CATE_BLANK_X3PARTYGROSS = new Set<String>{'cpc','cpm'}; //  04.07.2023 / Sophal Noch / US-0013851 : must be in lower case

    private String batchQuery = '';


    Map<String,X3PartyNumber> mapMonthlyCal = new Map<String,X3PartyNumber>();

    public BAT_RSD_PVP(){
        batchQuery = REV_MONTHLY_QUERY;
        batchQuery = batchQuery.replace('{!condition}', '=');
        batchQuery = batchQuery.replace('{!transactionDate}', 'LAST_MONTH');
    }

    public BAT_RSD_PVP(String conditon, String transactionDate){
        // Sophal: 02/08/2021: US-0010063 set parameter for querying with specific date
        batchQuery = REV_MONTHLY_QUERY;
        batchQuery = batchQuery.replace('{!condition}', conditon);
        batchQuery = batchQuery.replace('{!transactionDate}', transactionDate);
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC)
    { 
        return Database.getQueryLocator(batchQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Ad_Revenue_Monthly__c> scope)
    {

        Map<Id, X3PartyNumber> mapRmonthlyIdX3num = new Map<Id, X3PartyNumber>();
        
        for (AggregateResult arRDaily : Database.query(REV_DAILY_QUERY)){
            mapRmonthlyIdX3num.put(String.valueOf(arRDaily.get(AD_REVENUE_MONTHLY_NAME)), new X3PartyNumber(arRDaily));
        }
        
        List<Ad_Revenue_Monthly__c> listMonthlyToUpdate = new List<Ad_Revenue_Monthly__c>();

        for(Ad_Revenue_Monthly__c rMonthly : scope){

            X3PartyNumber sumNum = mapRmonthlyIdX3num.get(rMonthly.Id);

            if(sumNum != null){

                // if(rMonthly.Billing_Category__c.equalsignorecase(BILLING_CATEGORY_CPC) && sumNum.x3PartyGross==0){
                //  04.07.2023 / Sophal Noch / US-0013851 :
                if(String.ISNOTBLANK(rMonthly.Billing_Category__c) && SET_BILL_CATE_BLANK_X3PARTYGROSS.contains(rMonthly.Billing_Category__c.toLowerCase()) && sumNum.x3PartyGross==0){

                    sumNum.x3PartyGross = null;
                }

                if(rMonthly.X3rd_Party_Monthly_Gross__c != sumNum.x3PartyGross || rMonthly.X3rd_Party_Clicks__c != sumNum.x3PartyClick || rMonthly.X3rd_Party_AI__c != sumNum.xPartyAI){
                    
                    rMonthly.X3rd_Party_Monthly_Gross__c = sumNum.x3PartyGross;
                    rMonthly.X3rd_Party_Clicks__c = sumNum.x3PartyClick;
                    rMonthly.X3rd_Party_AI__c = sumNum.xPartyAI;
    
                    listMonthlyToUpdate.add(rMonthly);
    
                }   

            }

        }


        if(!listMonthlyToUpdate.isEmpty()){
            update listMonthlyToUpdate;
        }

      
    }
    
    global void finish(Database.BatchableContext BC)
    {
        
    }
    
    global void execute(SchedulableContext sc) 
    {
        BAT_RSD_PVP bat_rsd = new BAT_RSD_PVP();
        Database.executeBatch(bat_rsd,100);
    }

    class X3PartyNumber
    {
        Decimal x3PartyGross = 0;
        Decimal x3PartyClick = 0;
        Decimal xPartyAI = 0;
        
        public X3PartyNumber(AggregateResult arRDaily)
        {
            x3PartyGross = arRDaily.get(SUM_X3_PARTY_GROSS) == null ? 0 : Decimal.valueOf(String.valueOf(arRDaily.get(SUM_X3_PARTY_GROSS)));
            x3PartyClick = arRDaily.get(SUM_X3_PARTY_CLICK) == null ? 0 :  Decimal.valueOf(String.valueOf(arRDaily.get(SUM_X3_PARTY_CLICK)));
            xPartyAI = arRDaily.get(SUM_X_PARTY_AI) == null ? 0 : Decimal.valueOf(String.valueOf(arRDaily.get(SUM_X_PARTY_AI)));
        }
    }
    
}