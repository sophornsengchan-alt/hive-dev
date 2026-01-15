/** Batch process of Account Turnover
 *  @Created Date: 12/03/2021  
 @  Change history:  12.03.2021 / Mony Nou / US-0009226 - [Ads 2020] Account Turnover - Migrate from EU
 */  
global without sharing class AccountTurnover implements Database.Batchable<SObject>, Schedulable{
    
    public Map<String, CurrencyType> allCurrencyTypeMap;

    private static final List<String> STAGENAMES    = new List<String>{'Closed Won'};
    private static final List<String> RECORDTYPES   = new List<String>{'eBay'};
    private static final Set<String>  ADSREGION     = new Set<String> {'EU'};

    private static final Integer ACCOUNT_TURNOVER_VALUES_SIZE   = 3;
    private static final Integer TURNOVER_180                   = 0;
    private static final Integer TURNOVER_YEAR                  = 1;
    private static final Integer TURNOVER_BY_DELIVERY           = 2;

    private static final Integer BATCH_SIZE                     = Integer.valueOf(System.Label.Ad_AccountTurnOverBatchSize);

    /* Class implementation */
    public AccountTurnover() {
        this.allCurrencyTypeMap = new Map<String, CurrencyType>();
        getCurrencyTypes(this.allCurrencyTypeMap); 
    }

    /* Schedule implementation */
    global void execute(SchedulableContext schedulableContext) {
        Database.executeBatch(this, BATCH_SIZE);
    }

    /* Batch implementation */
    global Database.QueryLocator start(Database.BatchableContext bc) {

        String query =      'SELECT Id, Turnover_actual_by_delivery__c, Turnover_180_Days__c, Turnover_Calendar_Year__c '
                        +   'FROM Account '
                        +   'WHERE Opportunities_Won__c > 0 AND Ads_Region__c IN:ADSREGION' 
                        +   (Test.isRunningTest() ? ' ORDER BY CreatedDate DESC limit 2' : '');
        return Database.getQueryLocator(query);
    }

    global void execute(Database.BatchableContext batchableContext, List<sObject> widenedAccounts){
        List<Account> accounts  = (List<Account>) widenedAccounts;
        this.start(accounts);
    }

    global void finish(Database.BatchableContext BC){}

    public void start(List<Account> queriedAccounts){

        Set<Id> accountIDs                      = new Set<Id>();
        Map<Id, Account> accountsBeforeUpdate   = new Map<Id, Account>();
        Map<Id, Account> accountsToBeUpdated    = new Map<Id, Account>();
        
        initializeAccounts(queriedAccounts, accountIDs, accountsBeforeUpdate, accountsToBeUpdated);
        
        updateTurnover(getLineItems(accountIDs), allCurrencyTypeMap, accountsToBeUpdated);
        
        removeAccountsWithNoChanges(accountsBeforeUpdate, accountsToBeUpdated);
        
        update accountsToBeUpdated.values();

    }

    private void initializeAccounts(List<Account> accounts, Set<Id> accountIDs, Map<Id, Account> accountsBeforeUpdate, Map<Id, Account> accountsToBeUpdated){
        
        for(Account account : accounts){
            accountIDs.add(account.Id);
            accountsBeforeUpdate.put(account.Id, account.clone());
            
            account.Turnover_180_Days__c            = 0.0;
            account.Turnover_Calendar_Year__c       = 0.0;
            account.Turnover_actual_by_delivery__c  = 0.0;
            accountsToBeUpdated.put(account.Id, account);
        }
    }

    private List<Ad_Product__c> getLineItems(Set<Id> accounts){
        return [SELECT  Id, Opportunity__c, Amount_Net_Net_Net__c, Total_price_incl_Targeting__c, Turnover_actual_by_delivery__c, until_Date__c,
                        Opportunity__r.AccountId, Opportunity__r.First_Booked_Date__c, Opportunity__r.CurrencyIsoCode, Opportunity__r.Account.CurrencyIsoCode, 
                        Opportunity__r.Account.Turnover_180_Days__c, Opportunity__r.Account.Turnover_Calendar_Year__c
                FROM Ad_Product__c 
                WHERE   Opportunity__r.AccountId IN :accounts
                    AND until_Date__c >= :(Date.today()-366)
                    AND Opportunity__r.StageName IN :STAGENAMES
                    AND Opportunity__r.RecordType.DeveloperName IN :RECORDTYPES
                    AND package_line_item__c = ''];
    }

    private void updateTurnover(List<Ad_Product__c> adProducts, Map<String, CurrencyType> allCurrencyTypeMap, Map<Id, Account> accountsToBeUpdated){
        
        for(Ad_Product__c adProduct : adProducts){
            
            if (!accountsToBeUpdated.containsKey(adProduct.Opportunity__r.AccountId)){ continue; }
            
            if(allCurrencyTypeMap.containsKey(adProduct.Opportunity__r.CurrencyIsoCode) && allCurrencyTypeMap.containsKey(adProduct.Opportunity__r.Account.CurrencyIsoCode)){
                
                double[] accountTurnoverValues = calculateAccountTurnoverValues(adProduct, allCurrencyTypeMap);
                
                /* Turnover of 180 days */
                if((adProduct.until_Date__c >= Date.today() - 180) && (accountTurnoverValues[TURNOVER_180] != null)){
                    accountsToBeUpdated.get(adProduct.Opportunity__r.AccountId).Turnover_180_Days__c += accountTurnoverValues[TURNOVER_180];
                }
                
                /* Turnover of a year*/
                if((adProduct.until_Date__c.year() >= Date.today().year()) && (accountTurnoverValues[TURNOVER_YEAR] != null)){
                    accountsToBeUpdated.get(adProduct.Opportunity__r.AccountId).Turnover_Calendar_Year__c += accountTurnoverValues[TURNOVER_YEAR];
                }
                
                /* Turnover by delivery */
                if(accountTurnoverValues[TURNOVER_BY_DELIVERY] != null){
                    accountsToBeUpdated.get(adProduct.Opportunity__r.AccountId).Turnover_actual_by_delivery__c += accountTurnoverValues[TURNOVER_BY_DELIVERY];
                }
                
            }
        }
    }

    private double[] calculateAccountTurnoverValues(Ad_Product__c adProduct, Map<String, CurrencyType> allCurrencyTypeMap){
        String accountCurrencyIsoCode                   = adProduct.Opportunity__r.Account.CurrencyIsoCode;
        String opportunityCurrencyIsoCode               = adProduct.Opportunity__r.CurrencyIsoCode;
        double conversionRateAccountCurrencyIsoCode     = allCurrencyTypeMap.get(accountCurrencyIsoCode).ConversionRate;
        double conversionRateOpportunityCurrencyIsoCode = allCurrencyTypeMap.get(opportunityCurrencyIsoCode).ConversionRate;
        double[] ret = new double[ACCOUNT_TURNOVER_VALUES_SIZE];
        
        /* ORIGINAL CODES
        if(accountCurrencyIsoCode.equals(opportunityCurrencyIsoCode)){
            ret[TURNOVER_180]           = adProduct.Amount_Net_Net_Net__c;
            ret[TURNOVER_YEAR]          = adProduct.Total_price_incl_Targeting__c;
            ret[TURNOVER_BY_DELIVERY]   = adProduct.Turnover_actual_by_delivery__c;
        }else{
            ret[TURNOVER_180]           = (adProduct.Amount_Net_Net_Net__c / conversionRateOpportunityCurrencyIsoCode) * conversionRateAccountCurrencyIsoCode;
            ret[TURNOVER_YEAR]          = (adProduct.Total_price_incl_Targeting__c / conversionRateOpportunityCurrencyIsoCode) * conversionRateAccountCurrencyIsoCode;
            ret[TURNOVER_BY_DELIVERY]   = (adProduct.Turnover_actual_by_delivery__c / conversionRateOpportunityCurrencyIsoCode) * conversionRateAccountCurrencyIsoCode;
        }
        */

        ret[TURNOVER_180]           = calculateAmount(adProduct.Amount_Net_Net_Net__c, accountCurrencyIsoCode, conversionRateAccountCurrencyIsoCode, opportunityCurrencyIsoCode, conversionRateOpportunityCurrencyIsoCode);
        ret[TURNOVER_YEAR]          = calculateAmount(adProduct.Total_price_incl_Targeting__c, accountCurrencyIsoCode, conversionRateAccountCurrencyIsoCode, opportunityCurrencyIsoCode, conversionRateOpportunityCurrencyIsoCode);
        ret[TURNOVER_BY_DELIVERY]   = calculateAmount(adProduct.Turnover_actual_by_delivery__c, accountCurrencyIsoCode, conversionRateAccountCurrencyIsoCode, opportunityCurrencyIsoCode, conversionRateOpportunityCurrencyIsoCode);
        
        return ret;
    }

    private double calculateAmount(Decimal val, String accCur, double accConRate, String oppCur, double oppConRate) {
        if (val == null) val = 0;
        return (accCur.equals(oppCur)?val:((val/oppConRate)*accConRate));
    }

    private void removeAccountsWithNoChanges(Map<Id, Account> accountsBeforeUpdate, Map<Id, Account> accountsToBeUpdated){
        for (Id accountIDs : accountsToBeUpdated.keySet()) {
            if (accountsBeforeUpdate.containsKey(accountIDs)) {
                if(accountsToBeUpdated.get(accountIDs).Turnover_180_Days__c             == accountsBeforeUpdate.get(accountIDs).Turnover_180_Days__c &&
                   accountsToBeUpdated.get(accountIDs).Turnover_Calendar_Year__c        == accountsBeforeUpdate.get(accountIDs).Turnover_Calendar_Year__c &&
                   accountsToBeUpdated.get(accountIDs).Turnover_actual_by_delivery__c   == accountsBeforeUpdate.get(accountIDs).Turnover_actual_by_delivery__c){
                   
                        accountsToBeUpdated.remove(accountIDs);
    
                }
            }
        }
    }

    private void getCurrencyTypes(Map<String, CurrencyType> allCurrencyTypeMap){
        for(CurrencyType currencyType : [SELECT ConversionRate, IsoCode FROM CurrencyType]){ 
            allCurrencyTypeMap.put(currencyType.IsoCode, currencyType);
        }
    }

    
}