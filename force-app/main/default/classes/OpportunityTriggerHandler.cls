/*****************************************************************************************************************************
@ Class:          OpportunityTriggerHandler
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Handler Class for opportunityMain.trigger
------------------------------------------------------------------------------------------------------------------------------
@ Change history:  24.08.2020 / Sophal Noch / Created the class.
@               :  24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
@               :  25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
@               :   22.10.2024 / Vimean Heng / US-0015586 - SAP for ADS - Duration Formula enhancement.
@*****************************************************************************************************************************/
public without sharing class OpportunityTriggerHandler {

    // 24.04.2024 / Sophal Noch / US-0014879 :
    private final static String SOBJ_OPP_APINAME = 'Opportunity';
    private final static Set<Id> SET_RTYPE_ID_BILLINV = new Set<Id>{ 
        ApexUtil.getRecordTypeByName(SOBJ_OPP_APINAME,'eBay')?.Id,
        ApexUtil.getRecordTypeByName(SOBJ_OPP_APINAME,'eBay_Ads_Promoted_Listings')?.Id
    };
    private final static String OPP_STATUS_CLOSED_WON = 'Closed Won';
    // 25.04.2024 / Bora Chhorn / US-0015099
    private final static String BILL_TO_PARTY_ADVERTISER = 'Advertiser';
    private final static String BILL_TO_PARTY_AGENCY = 'Agency';
    private final static Set<String> SET_OPP_BILLING_TO_PARTY = new Set<String>{BILL_TO_PARTY_ADVERTISER,BILL_TO_PARTY_AGENCY};
    public static RecordType opportunityRecTypeBD = ApexUtil.getRecordTypeByName('Opportunity','eBay_Business_Development');
    /*****************************************************************************************************************************
    @ Method:       manageAdsProduct
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      US-0008007
    @               Summary: Create a Ad Product record for an Opportunity whenever a new Opportunity is created.
    @               AC 1) When a new Opportunity is created, a new Ad Product record (without a Product) is created where the 'Total Price' value is automatically populated based on the Opportunity Amount.
    @               AC 2) A roll-up summary field is created on the Opportunity to count the number of (Ad Products with Products)
    @               AC 3) When an Opportunity is updated and the amount is changed and the roll-up summary count = 0, than update the total price to the new amount.
    @               AC 4) Create a new checkbox 'Quote Sync In Progress' on Opportunity that does not appear on any page layouts, default is 'False' Field Level Security should be read/write to System Admin Profile
    @               AC 5) Validation Rule to prevent changing the Opportunity Amount when the Amount is changed, the roll-up summary count >0 and the checkbox 'Quote' Is Syncing is False'
    @               Validation Rule Error Message: "The Total Amount cannot be updated for this opportunity"
    @ Event:		after insert, after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Opportunity Trigger.New, Trigger.oldMap, Trigger.isInsert
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  24.08.2020 / Sophal Noch / Created the method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  15.10.2020  / Sophal Noch / US-0008451 allow field populating logic to run when opp start and end date changed.
    @*****************************************************************************************************************************/
    public static void manageAdsProduct(List<Opportunity> listNewOpp, Map<Id, Opportunity> mapOldOpp){

        if(mapOldOpp == null){
            // US-0008007 insert default Ad_Product__c when Opportunity is inserted
            createDefaultProduct(listNewOpp);

        }else{
             // US-0008007 update Ad_Product__c.TotalPrice__c when Opportunity.Amount is updated and Opportunity.Ad_Products_with_Products__c == 0
            Map<Id,Opportunity> mapOppToRecal = new  Map<Id,Opportunity>();
            for(Opportunity eachOpp : listNewOpp){

                if(
                    (
                        eachOpp.Amount != mapOldOpp.get(eachOpp.Id).Amount
                        // US-0008451 allow fields below to trigger the populating ad product
                        || eachOpp.Start_Date__c != mapOldOpp.get(eachOpp.Id).Start_Date__c
                        || eachOpp.End_Date__c != mapOldOpp.get(eachOpp.Id).End_Date__c
                        || eachOpp.CurrencyISOCode != mapOldOpp.get(eachOpp.Id).CurrencyISOCode //MN-22062021-Sync CurrencyISOCode from Opp to Default AP
                    )
                    // US-0008451 the one line below can be removed later if we need to update some other fields beside Amount,Start_Date__c,End_Date__c.
                    && (eachOpp.Number_of_Primary_Quotes__c == 0 && !eachOpp.Quote_Sync_In_Progress__c)
                ){
                    mapOppToRecal.put(eachOpp.Id,eachOpp);
                }
            }

            if(!mapOppToRecal.isEmpty()){
                updateProduct(mapOppToRecal);
            }

        }

    }

    private static void createDefaultProduct(List<Opportunity> listNewOpp){

        List<Ad_Product__c> listAdProdToInsert = new List<Ad_Product__c>();

        for(Opportunity eachOpp : listNewOpp){

                Ad_Product__c initAdProd = new Ad_Product__c(Opportunity__c = eachOpp.Id , Quantity__c = 0, CurrencyISOCode=eachOpp.CurrencyISOCode); //MN-22062021-Sync Currency from OPP to Default AP

                // US-0008451 populating field "from and until date" of ad product when opp init
                updateAdProdFromAndUntilDate(initAdProd,eachOpp);

                listAdProdToInsert.add(initAdProd);
        }

        insert listAdProdToInsert;


    }

    private static void updateProduct(Map<Id,Opportunity> mapOppToRecal){
        
        List<Ad_Product__c> listAdProdToUpdate = new List<Ad_Product__c>();

        for(Ad_Product__c eachAdProd : [SELECT Id, TotalPrice__c, Quote_Line_Item__c, Opportunity__c From Ad_Product__c Where Opportunity__c IN : mapOppToRecal.keySet()]){
                
            if(eachAdProd.Quote_Line_Item__c == null){ // only intial ad product can be updated from opp

                Opportunity eachOpp = mapOppToRecal.get(eachAdProd.Opportunity__c);

                // US-0008451 populating field "from and until date" of ad product when opp start and end date are changed
                updateAdProdFromAndUntilDate(eachAdProd,eachOpp);
    
                listAdProdToUpdate.add(eachAdProd);
            }

        }


        if(!listAdProdToUpdate.isEmpty()){
            update listAdProdToUpdate;
        }

    }


    private static void updateAdProdFromAndUntilDate(Ad_Product__c eachAdProd, Opportunity eachOpp){
        // US-0008451 populating field "from and until date" of ad product
        
        // eachOpp.Number_of_Primary_Quotes__c is roll-up summary field, having no child records is equal to 0
        if(eachOpp.Number_of_Primary_Quotes__c == 0 && !eachOpp.Quote_Sync_In_Progress__c){

            eachAdProd.from_Date__c = eachOpp.Start_Date__c;
            eachAdProd.until_Date__c = eachOpp.End_Date__c;

            // eachOpp.Ad_Products_with_Products__c is roll-up summary field, having no child records is equal to 0
            if(eachOpp.Ad_Products_with_Products__c == 0){ eachAdProd.TotalPrice__c = eachOpp.Amount; }

            //MN-22062021-Sync CurrencyISOCode from Opp to Default AP
            eachAdProd.CurrencyISOCode = eachOpp.CurrencyISOCode;

        }

    }


    /*********************************************************************************************************************************
    @ Method:         populateBillInvClosedWon
    @ Version:        1.0
    @ Author:         Sophal Noch
    @ Purpose:        24.04.2024 / Sophal Noch / US-0014879 - 2.1 SAP for ADS - Billing Invoice record creation (monthly)
    @ Event:		  after update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Opportunity Trigger.New, Trigger.oldMap, Trigger.isUpdate
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   24.04.2024 / Sophal Noch / Created the method.
    @               :   25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    *********************************************************************************************************************************/
    public static void populateBillInvClosedWon(List<Opportunity> listNewOpp, Map<Id, Opportunity> mapOldOpp){

        if(QueueGenerateRevenue.isRunning){
            return;
        }

        Map<Id, Id> mapOppIdToAccId = new Map<Id, Id>();

        for(Opportunity newOpp : listNewOpp){
            Opportunity oldOpp = mapOldOpp.get(newOpp.Id);
            if(newOpp.StageName == OPP_STATUS_CLOSED_WON && (newOpp.StageName != oldOpp.StageName || newOpp.Bill_To_Party__c != oldOpp.Bill_To_Party__c ) && SET_RTYPE_ID_BILLINV.contains(newOpp.RecordTypeId)){
                if(BillingInvoiceGenerator.checkOppBillToParty(newOpp) != null){
                    mapOppIdToAccId.put(newOpp.Id, BillingInvoiceGenerator.checkOppBillToParty(newOpp));
                }
            }
        }

        if(mapOppIdToAccId.isEmpty()){
            return;
        }

        Map<Id, Id> mapOppIdToConId = BillingInvoiceGenerator.getMapOppIdToConId(mapOppIdToAccId);

        if(mapOppIdToConId.isEmpty()){
            return;
        }

        Boolean isAsyncRunning = System.isFuture() || System.isBatch() || System.isQueueable();
        if(isAsyncRunning){
            new QueueGenerateBillingInvoice(mapOppIdToConId.keySet()).execute(null);
        }else{
            System.enqueueJob(new QueueGenerateBillingInvoice(mapOppIdToConId.keySet()));
        }

    }

    /*********************************************************************************************************************************
    @ Method:         validateOppClosedWon
    @ Version:        1.0
    @ Author:         Bora Chhorn
    @ Purpose:        25.04.2024 / Bora Chhorn / US-0015099 - 3.2 SAP for ADS - Billing Invoice field automations - recipient
    @ Event:		  before update
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	Opportunity Trigger.New, Trigger.oldMap, Trigger.isUpdate
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   25.04.2024 / Bora Chhorn / Created the method.
    @               :   22.10.2024 / Vimean Heng / US-0015586 - SAP for ADS - Duration Formula enhancement.
    *********************************************************************************************************************************/
    public static void validateOppClosedWon(List<Opportunity> listNewOpp, Map<Id, Opportunity> mapOldOpp){

        Map<Id, Opportunity> mapOpp = new Map<Id, Opportunity>();
        Map<Id, Id> mapOppIdToAccId = new Map<Id, Id>();

        for(Opportunity newOpp : listNewOpp){
            Opportunity oldOpp = mapOldOpp.get(newOpp.Id);
            if(newOpp.StageName == OPP_STATUS_CLOSED_WON && newOpp.StageName != oldOpp.StageName && SET_RTYPE_ID_BILLINV.contains(newOpp.RecordTypeId)){
                if(String.isBlank(newOpp.Bill_to_Payment_Terms__c)){
                    newOpp.addError(System.Label.Error_Closed_Won_No_Payment_Term);
                }else if(SET_OPP_BILLING_TO_PARTY.contains(newOpp.Bill_To_Party__c)){
                    if(BillingInvoiceGenerator.checkOppBillToParty(newOpp) != null){
                        mapOppIdToAccId.put(newOpp.Id, BillingInvoiceGenerator.checkOppBillToParty(newOpp));
                    }
                    mapOpp.put(newOpp.Id, newOpp);
                }
            }
        }
        
        if(mapOppIdToAccId.isEmpty()){
            return;
        }

        Map<Id, Id> mapOppIdToConId = BillingInvoiceGenerator.getMapOppIdToConId(mapOppIdToAccId);

        for(Opportunity opp : mapOpp.values()){
            if(!mapOppIdToConId.containsKey(opp.Id)){
                opp.addError(System.Label.Error_Message_No_Billing_Contact);
            }
        }
    }

}