/*********************************************************************************************************************************
@ Class:          BillingInvoiceGenerator
@ Version:        1.0
@ Author:         Sophal Noch
@ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  24.04.2024 / Sophal Noch / Created the class.
@               :  25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
@               :  22.05.2024 / Acmatac Seing / US-0015036 - 2.2 SAP for ADS - Billing Invoice record creation (quarterly)
*********************************************************************************************************************************/
public inherited sharing class BillingInvoiceGenerator {

    private Map<Id, Opportunity> mapOpp;
    private Map<Id, List<Ad_Revenue_Monthly__c>> mapOppIdToListMonthly = new Map<Id, List<Ad_Revenue_Monthly__c>>();
    private Map<String, BillingInvoice__c> mapKeyToBillInv = new Map<String, BillingInvoice__c>();
    private Map<String, BillingInvoice__c> mapKeyToBillInvToUpsert = new Map<String, BillingInvoice__c>();
    private Map<String, List<Ad_Revenue_Monthly__c>> mapKeyToListMonthly = new Map<String, List<Ad_Revenue_Monthly__c>>();

    Map<Id, Id> mapOppIdToConId = new Map<Id, Id>();

    private final Id RTYPE_ID_BILLINV = ApexUtil.getRecordTypeByName('BillingInvoice__c','SAPInvoice')?.Id;

    private final String OPP_STATUS_CLOSED_WON = 'Closed Won';
    private final String BILLINV_PT_MONTHLY = 'Monthly in arrears';
    private final String BILLINV_PT_QUARTERLY = 'quarterly';
    private final String BILLINV_STATUS_DRAFT = 'Draft';
    private final String BILLINV_STATUS_NEW = 'New';
    private final static String BILLING_CONTACT_ROLE = 'Billing Contact';
    private final static String BILL_TO_PARTY_ADVERTISER = 'Advertiser';
    private final static String BILL_TO_PARTY_AGENCY = 'Agency';

    private final String SOQL_RMONTHLY = 'SELECT Id, Opportunity__c, Transaction_Date__c, Amount__c, BillingInvoice__c, Billing_Quarter__c FROM Ad_Revenue_Monthly__c Where Opportunity__c IN: setOppId Order By Transaction_Date__c ASC';
    private final String SOQL_BILLINV = 'Select Id, RelatedBillingOpportunity__c, Unique_Key__c, BillingStatus__c, TotalInvoiceAmount__c, BillingPeriod_StartDate__c, BillingPeriod_EndDate__c, InvoiceRecipient__c from BillingInvoice__c Where RelatedBillingOpportunity__c IN: setOppId Order by Id ASC';
    private final static String SOQL_CONTACT = 'SELECT Id, Contact_Role__c, AccountId FROM Contact WHERE AccountId IN :mapAccId AND Contact_Role__c INCLUDES (:contactRole) ORDER BY Id ASC';

    public BillingInvoiceGenerator(Map<Id, Opportunity> mapOpp){
        this.mapOpp = mapOpp;
    }

    /*********************************************************************************************************************************
    @ Method:         retrieveExistingRMonthly
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   24.04.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public BillingInvoiceGenerator retrieveExistingRMonthly(){

        if(mapOpp == null){
            return this;
        }
        
        List<Ad_Revenue_Monthly__c> listRMonthly = (List<Ad_Revenue_Monthly__c>) ApexSafe.query().secCheck(false).doQuery(SOQL_RMONTHLY,new Map<String, Object> {'setOppId' => mapOpp.keySet()});

        if(!listRMonthly.isEmpty()){ // get Ad_Revenue_Monthly__c records and map to Parent Opportunity
            for(Ad_Revenue_Monthly__c monthly : listRMonthly){
                List<Ad_Revenue_Monthly__c> listRMonthlyPerOpp = mapOppIdToListMonthly.get(monthly.Opportunity__c);
                if(listRMonthlyPerOpp == null){
                    listRMonthlyPerOpp = new List<Ad_Revenue_Monthly__c>();
                    mapOppIdToListMonthly.put(monthly.Opportunity__c, listRMonthlyPerOpp);
                }
                listRMonthlyPerOpp.add(monthly);

            }
        }  

        // get exist BillingInvoice__c records from its Parent Opportunity and map to its Unique_Key__c
        for(BillingInvoice__c billInv : (List<BillingInvoice__c>)ApexSafe.query().secCheck(false).doQuery(SOQL_BILLINV,new Map<String, Object> {'setOppId' => mapOpp.keySet()})){
            mapKeyToBillInv.put(billInv.Unique_Key__c, billInv);
        }

        
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         populateBillingInvoice
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   24.04.2024 / Sophal Noch / Created the method.
    @               :  22.05.2024 / Acmatac Seing / US-0015036 - 2.2 SAP for ADS - Billing Invoice record creation (quarterly)
    *********************************************************************************************************************************/    
    public BillingInvoiceGenerator populateBillingInvoice(){

        if(mapOppIdToListMonthly.isEmpty()){ 
            return this;
        }

        Map<Id, Id> mapOppIdToAccId = new Map<Id, Id>();

        for(Id oppId : mapOppIdToListMonthly.keySet()){
            Opportunity opp = mapOpp.get(oppId);

            if(checkOppBillToParty(opp) != null){
                mapOppIdToAccId.put(opp.Id, checkOppBillToParty(opp));
            }
        }

        if(!mapOppIdToAccId.isEmpty()){
            mapOppIdToConId = getMapOppIdToConId(mapOppIdToAccId);
        }

        for(Id oppId : mapOppIdToListMonthly.keySet()){

            List<Ad_Revenue_Monthly__c> listRMonthly = mapOppIdToListMonthly.get(oppId);

            Opportunity opp = mapOpp.get(oppId);

            if(getPaymentTerm(opp) == BILLINV_PT_MONTHLY){  // generate monthly billing invoice when Oppotunity.Payment_Terms__c = 'Monthly in arrears'
                generateBillMonthly(opp, listRMonthly);
            }
            // 22.05.2024 / Acmatac Seing / US-0015036 - 2.2 SAP for ADS - Billing Invoice record creation (quarterly)
            else if(getPaymentTerm(opp) == BILLINV_PT_QUARTERLY){  // generate billing invoice when Oppotunity.Payment_Terms__c = 'Quarterly'
                generateBillInvByQuarterly(opp, listRMonthly);
            }
        }

        upsertBillInv(); // upsert BillingInvoice__c and 
        updateRMonthly(); // update Ad_Revenue_Monthly__c

        return this;
    }

    private BillingInvoiceGenerator generateBillMonthly(Opportunity opp, List<Ad_Revenue_Monthly__c> listRMonthly){
        
        for(Ad_Revenue_Monthly__c monthly : listRMonthly){
            
            String uniqueKey = getBillInvMonthlyUniqueKey(opp, monthly); // generate unique key for BillingInvoice__c
            
            BillingInvoice__c billInv = mapKeyToBillInv.get(uniqueKey);
            if(billInv == null){ // when BillingInvoice__c is not exist, create new BillingInvoice__c
                billInv = new BillingInvoice__c(Unique_Key__c = uniqueKey, BillingStatus__c = BILLINV_STATUS_DRAFT, RecordTypeId = RTYPE_ID_BILLINV);
                mapKeyToBillInv.put(billInv.Unique_Key__c, billInv);
                mapKeyToBillInvToUpsert.put(billInv.Unique_Key__c, billInv);
            }
    
            // store record into a temporary variable
            BillingInvoice__c oldBillInv = generateBillInv(billInv);

            // update new values to BillingInvoice__c
            billInv.RelatedBillingOpportunity__c = opp.Id;
            billInv.BillingStatus__c = poplateBillInvStatus(opp, billInv); // populate BillingInvoice__c.BillingStatus__c based on conditions
            billInv.TotalInvoiceAmount__c = opp.Amount;
            if(isOppClosedWon(opp)){ // populate BillingInvoice__c.BillingPeriod_StartDate__c and BillingInvoice__c.BillingPeriod_EndDate__c when Opportunity.StageName = 'Closed Won'
                populateBillInvPeriodDate(monthly, billInv);
                populateBillingInvRecipient(opp, billInv);
            }

            if(!mapKeyToBillInvToUpsert.containsKey(uniqueKey) 
                && isBillingInvoiceChanged(oldBillInv, billInv)
            ){ // when exist BillingInvoice__c has values changed, add to mapKeyToBillInvToUpsert to upsert later
                mapKeyToBillInvToUpsert.put(billInv.Unique_Key__c, billInv);
            }

            if(isOppClosedWon(opp)){
                populateKeyToListRMonthly(uniqueKey, monthly);
            }
        }

        return this;
    }

    /*********************************************************************************************************************************
    @ Author:         Acmatac Seing
    @ Purpose:        US-0015036 - Using for generate billing invoice by Quarterly
    -----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2024 / Acmatac Seing / Created the method.
    *********************************************************************************************************************************/
    private BillingInvoiceGenerator generateBillInvByQuarterly(Opportunity opp, List<Ad_Revenue_Monthly__c> listRMonthly){
        Map<String, List<Ad_Revenue_Monthly__c>> mapQuarterly_ARM = splitList(listRMonthly);
        for(String quarterlyKey : mapQuarterly_ARM.keySet()){
            List<Ad_Revenue_Monthly__c> chunkedMonthly = mapQuarterly_ARM.get(quarterlyKey);
            Ad_Revenue_Monthly__c firstRM = chunkedMonthly.get(0);
            Ad_Revenue_Monthly__c lastRM = chunkedMonthly.get(chunkedMonthly.size()-1);
            String uniqueKey = getBillInvQuarterlyUniqueKey(opp, firstRM); // generate unique key for BillingInvoice__c
            BillingInvoice__c billInv = mapKeyToBillInv.get(uniqueKey);
            if(billInv == null){ // when BillingInvoice__c is not exist, create new BillingInvoice__c
                billInv = new BillingInvoice__c(Unique_Key__c = uniqueKey, BillingStatus__c = BILLINV_STATUS_DRAFT, RecordTypeId = RTYPE_ID_BILLINV);
                mapKeyToBillInv.put(billInv.Unique_Key__c, billInv);
                mapKeyToBillInvToUpsert.put(billInv.Unique_Key__c, billInv);
            }

            // store record into a temporary variable
            BillingInvoice__c oldBillInv = generateBillInv(billInv);

            // update new values to BillingInvoice__c
            billInv.RelatedBillingOpportunity__c = opp.Id;
            billInv.BillingStatus__c = poplateBillInvStatus(opp, billInv); // populate BillingInvoice__c.BillingStatus__c based on conditions
            billInv.TotalInvoiceAmount__c = opp.Amount;

            if(isOppClosedWon(opp)){ // populate BillingInvoice__c.BillingPeriod_StartDate__c and BillingInvoice__c.BillingPeriod_EndDate__c when Opportunity.StageName = 'Closed Won'
                populateBillInvPeriodDate(firstRM, lastRM, billInv);
                populateBillingInvRecipient(opp, billInv);
                
                for(Ad_Revenue_Monthly__c monthly : chunkedMonthly){
                    populateKeyToListRMonthly(uniqueKey, monthly);
                }
            }
            
            if(!mapKeyToBillInvToUpsert.containsKey(uniqueKey) 
                && isBillingInvoiceChanged(oldBillInv, billInv)
            ){ // when exist BillingInvoice__c has values changed, add to mapKeyToBillInvToUpsert to upsert later
                mapKeyToBillInvToUpsert.put(billInv.Unique_Key__c, billInv);
            }
        }

        return this;
    }

    private void upsertBillInv(){
        ApexSafe.dml().secCheck(false).doUpsert(mapKeyToBillInvToUpsert.values(), BillingInvoice__c.Unique_Key__c, true);
    }

    private void updateRMonthly(){
        if(!mapKeyToListMonthly.isEmpty()){ // update Ad_Revenue_Monthly__c.BillingInvoice__c with BillingInvoice__c.Id that we get from BillingInvoice__c.Unique_Key__c
            List<Ad_Revenue_Monthly__c> listRMonthlyToUpdate = new List<Ad_Revenue_Monthly__c>();
            for(String uniqueKey : mapKeyToListMonthly.keySet()){
                BillingInvoice__c billInv = mapKeyToBillInv.get(uniqueKey);
                List<Ad_Revenue_Monthly__c> listRMonthly = mapKeyToListMonthly.get(uniqueKey);
                for(Ad_Revenue_Monthly__c monthly : listRMonthly){
                    if(monthly.BillingInvoice__c != billInv.Id){ // if Ad_Revenue_Monthly__c.BillingInvoice__c is changed, we need to update Ad_Revenue_Monthly__c
                        monthly.BillingInvoice__c = billInv.Id;
                        listRMonthlyToUpdate.add(monthly);
                    }
                }
            }
            ApexSafe.dml().secCheck(false).doUpdate(listRMonthlyToUpdate, true);
        }
    }

    private String getPaymentTerm(Opportunity opp){ // get Payment_Terms__c from Opportunity, if it is blank, return 'Monthly in arrears'
        return String.isBlank(opp.Payment_Terms__c) ? BILLINV_PT_MONTHLY : opp.Payment_Terms__c;
    }

    private String getBillInvMonthlyUniqueKey(Opportunity opp, Ad_Revenue_Monthly__c monthly){ // generate unique key for BillingInvoice__c.Unique_Key__c, example : 006WG000003FFufYAG.Monthly in arrears_2024.4.1
        String invoiceTerm = getPaymentTerm(opp);
        return opp.Id + '.' + invoiceTerm + '_' + monthly.Transaction_Date__c.year() + '.' + monthly.Transaction_Date__c.month() + '.' + monthly.Transaction_Date__c.day();
    }

    private String getBillInvQuarterlyUniqueKey(Opportunity opp, Ad_Revenue_Monthly__c monthly){ // generate unique key for BillingInvoice__c.Unique_Key__c, example : 006VE000005yiumYAA.quarterly_2025.Q1
        return opp.Id + '.' + getPaymentTerm(opp) + '_' + monthly.Transaction_Date__c.year() + '.' + monthly.Billing_Quarter__c;
    }

    private String poplateBillInvStatus(Opportunity opp, BillingInvoice__c billInv){
        String billInvStatus = billInv.BillingStatus__c;
        if(isOppClosedWon(opp) && (billInvStatus == BILLINV_STATUS_DRAFT || String.isBlank(billInvStatus))){
            billInvStatus = BILLINV_STATUS_NEW;
        }
        return billInvStatus;
    }
    
    private Boolean isOppClosedWon(Opportunity opp){
        return opp.StageName == OPP_STATUS_CLOSED_WON;
    }

    private void populateBillInvPeriodDate(Ad_Revenue_Monthly__c monthly, BillingInvoice__c billInv){

        billInv.BillingPeriod_StartDate__c = monthly.Transaction_Date__c.toStartOfMonth(); // populate the first day of the Ad_Revenue_Monthly__c.Transaction_Date__c

        Integer daysInMonth = Date.daysInMonth(monthly.Transaction_Date__c.year(), monthly.Transaction_Date__c.month());
        Date endOfMonth = Date.newInstance(monthly.Transaction_Date__c.year(), monthly.Transaction_Date__c.month(), daysInMonth);
        billInv.BillingPeriod_EndDate__c = endOfMonth; //  populate the last day of the Ad_Revenue_Monthly__c.Transaction_Date__c
    }

    /*********************************************************************************************************************************
    @ Author:         Acmatac Seing
    @ Purpose:        US-0015036 - Using for populate Billing Invoice Startdate and Enddate 
    -----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2024 / Acmatac Seing / Created the method.
    *********************************************************************************************************************************/
    private void populateBillInvPeriodDate(Ad_Revenue_Monthly__c firstMonthly, Ad_Revenue_Monthly__c lastMonthly, BillingInvoice__c billInv){
        billInv.BillingPeriod_StartDate__c = firstMonthly.Transaction_Date__c.toStartOfMonth(); // populate the first day of the Ad_Revenue_Monthly__c.Transaction_Date__c
        billInv.BillingPeriod_EndDate__c = lastMonthly.Transaction_Date__c.addMonths(1).toStartofMonth().addDays(-1);
    }

    private void populateKeyToListRMonthly(String uniqueKey, Ad_Revenue_Monthly__c monthly){
        // store list of Ad_Revenue_Monthly__c and map to its BillingInvoice__c.Unique_Key__c so we can update Ad_Revenue_Monthly__c.BillingInvoice__c later
        List<Ad_Revenue_Monthly__c> listRMonthlyFromMap = mapKeyToListMonthly.get(uniqueKey);
        if(listRMonthlyFromMap == null){
            listRMonthlyFromMap = new List<Ad_Revenue_Monthly__c>();
            mapKeyToListMonthly.put(uniqueKey, listRMonthlyFromMap);
        }
        listRMonthlyFromMap.add(monthly);
    }
    
    /*********************************************************************************************************************************
    @ Method:         populateBillingInvRecipient
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   25.04.2024 / Bora Chhorn / Created the method.
    *********************************************************************************************************************************/
    private void populateBillingInvRecipient(Opportunity opp, BillingInvoice__c billInv){
        if(mapOppIdToConId.containsKey(opp.Id)){
            billInv.InvoiceRecipient__c = mapOppIdToConId.get(opp.Id);
        }
    }

    /*********************************************************************************************************************************
    @ Method:         getMapOppIdToConId
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   25.04.2024 / Bora Chhorn / Created the method.
    *********************************************************************************************************************************/
    public static Map<Id, Id> getMapOppIdToConId(Map<Id, Id> mapOppIdToAccId) {

        Map<Id, Id> mapAccIdToConId = new Map<Id, Id>();
        List<Contact> listCont = (List<Contact>) ApexSafe.query().secCheck(false).doQuery(SOQL_CONTACT, new Map<String, Object>{'mapAccId' => mapOppIdToAccId.values(),'contactRole' => BILLING_CONTACT_ROLE});
        for(Contact con : listCont){
            if(!mapAccIdToConId.containsKey(con.AccountId)){
                mapAccIdToConId.put(con.AccountId, con.Id);
            }
        }
        Map<Id, Id> mapOppIdToConId = new Map<Id, Id>();

        for(Id oppId : mapOppIdToAccId.keySet()){
            Id accId = mapOppIdToAccId.get(oppId);
           if(mapAccIdToConId.containsKey(accId)){
                mapOppIdToConId.put(oppId, mapAccIdToConId.get(accId));
              
           }
        }
        return mapOppIdToConId;
    }

    /*********************************************************************************************************************************
    @ Method:         checkOppBillToParty
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   25.04.2024 / Bora Chhorn / Created the method.
    *********************************************************************************************************************************/
    public static Id checkOppBillToParty(Opportunity opp){
        Id accId;
        if(opp.Agency__c != null && opp.Bill_To_Party__c == BILL_TO_PARTY_AGENCY){
            accId = opp.Agency__c;
        }else if(opp.Bill_To_Party__c == BILL_TO_PARTY_ADVERTISER){
            accId = opp.AccountId;
        }
        return accId;
    }

    /*********************************************************************************************************************************
    @ Author:         Acmatac Seing
    @ Purpose:        US-0015036 - Using for splitting the list of record into List of List
    -----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 22.05.2024 / Acmatac Seing / Created the method.
    *********************************************************************************************************************************/
    private Map<String, List<Ad_Revenue_Monthly__c>> splitList(List<Ad_Revenue_Monthly__c> listItem) {
        // ARM Can be the same month but for different Ad Product. We need to group it by Quarterly.
        // Example of ARM:
        // TransactionDate     UniqueKey (AdProduct Id + Transaction Date)  Billing_Quarter__c
        // 2024-06-01	       a5gVE00000077XpYAI_2024_6                    Q2 
        // 2024-07-01	       a5gVE0000007MlNYAU_2024_7                    Q3
        // 2024-07-01	       a5gVE00000077XpYAI_2024_7                    Q3
        // 2024-08-01	       a5gVE0000007MlNYAU_2024_8                    Q3
        Map<String, List<Ad_Revenue_Monthly__c>> mapQuarterly_ARM = new Map<String, List<Ad_Revenue_Monthly__c>>();
        for(Ad_Revenue_Monthly__c oneARM: listItem){
            String mKey = oneARM.Transaction_Date__c.year()+ '.' +oneARM.Billing_Quarter__c;
            if(mapQuarterly_ARM.containsKey(mKey)){
                mapQuarterly_ARM.get(mKey).add(oneARM);
            }else{
                mapQuarterly_ARM.put(mKey, new List<Ad_Revenue_Monthly__c>{oneARM});
            }
        }
        return mapQuarterly_ARM;
    }

    // This method is used to store the prior values of a billing invoice before it is changed.
    private BillingInvoice__c generateBillInv(BillingInvoice__c billInv){
        return new BillingInvoice__c(
            RelatedBillingOpportunity__c = billInv.RelatedBillingOpportunity__c,
            BillingStatus__c = billInv.BillingStatus__c,
            TotalInvoiceAmount__c = billInv.TotalInvoiceAmount__c,
            BillingPeriod_StartDate__c = billInv.BillingPeriod_StartDate__c,
            BillingPeriod_EndDate__c = billInv.BillingPeriod_EndDate__c,
            InvoiceRecipient__c = billInv.InvoiceRecipient__c
        );
    }

    // This method is used to check the if the billing invoice has changed
    private Boolean isBillingInvoiceChanged(BillingInvoice__c oldBillInv, BillingInvoice__c newBillInv){
        return (
            oldBillInv.RelatedBillingOpportunity__c != newBillInv.RelatedBillingOpportunity__c || oldBillInv.BillingStatus__c != newBillInv.BillingStatus__c || 
            oldBillInv.TotalInvoiceAmount__c != newBillInv.TotalInvoiceAmount__c || oldBillInv.BillingPeriod_StartDate__c !=  newBillInv.BillingPeriod_StartDate__c || 
            oldBillInv.BillingPeriod_EndDate__c != newBillInv.BillingPeriod_EndDate__c || oldBillInv.InvoiceRecipient__c != newBillInv.InvoiceRecipient__c
        );
    }
}