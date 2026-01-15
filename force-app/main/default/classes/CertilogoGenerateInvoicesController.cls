/*********************************************************************************************************************************
@ Class:          CertilogoGenerateInvoicesController
@ Version:        1.0
@ Author:         LoumAng SENG
@ Purpose:        11.11.2024 / LoumAng SENG / This class is used to handle Generate Invoices functionality
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.11.2024 / LoumAng SENG / US-0015494 - create the class
@                  11.11.2024 / LoumAng SENG / US-0016115 - data creation
@                  02.04.2025 / Bora CHHORN / US-0016999 - Certilogo - Invoice Total Amount Incorrect on Billing Invoice
@				   22.04.2025 / LoumAng SENG / US-0032977 - Certilogo - create DUE DATE field on Billing Invoice - billing date + payment terms
*********************************************************************************************************************************/
public with sharing class CertilogoGenerateInvoicesController {
    private static final String RT_CERTILOGO = 'Certilogo';
    private static final String INVOICE_STATUS_READY = 'Ready for Invoice';
    private static final String INVOICE_STATUS_INVOICED = 'Invoiced';
    private static final String SAAS_BILLINGTYPE = 'SaaS';
    private static final Id RT_CERTILOGO_ID = ApexUtil.getRecordTypeByName('Opportunity',RT_CERTILOGO).Id;
    private static final Id RT_SAPINVOICE_ID= ApexUtil.getRecordTypeByName('BillingInvoice__c','SAPInvoice').Id;
    private static final String OR_ORDERTYPE = 'OR';
    private static final String PRICING_CONDITION ='PR00';
    private static final String YEARLY ='Yearly';
    private static final String QUARTERLY ='Quarterly';
    private static final String SEMI_YEARLY ='Semi-Yearly';
    private static final String SPLIT_CHAR = '#';
	//LA-18-07-2025-US-0032977: add Opportunity.Account.Payment_Terms__c to query
    private static final String SOQL_OPPORTUNITYLINEITEM = 'SELECT Id,Opportunity.Account.Payment_Terms__c,LastBilledDate__c,Frequency__c,InvoiceStatus__c,Quantity,UnitPrice,OpportunityId,ReadytoInvoiceTimestamp__c,Opportunity.Offer_Number__c,CurrencyIsoCode,Opportunity.Account.Name FROM OpportunityLineItem';

    private static final String CLASS_NAME = 'CertilogoGenerateInvoicesController';

    private static final String METHOD_GENERATE_BILL_INV = 'generateBillInv';
    private static final String METHOD_GENERATE_FREQUENCY_BILL_INV = 'generateFrequencyBillInv';

    /*********************************************************************************************************************************
    @ Method:         generateBillInv
    @ Version:        1.0
    @ Author:         LoumAng SENG
    @ Purpose:        11.11.2024 / LoumAng SENG / US-0015494 , US-0016115: auto gerenate billing invoice and billing invoice line
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   11.11.2024 / LoumAng SENG / Created the method.
    @                   02.04.2025 / Bora CHHORN / US-0016999 - Certilogo - Invoice Total Amount Incorrect on Billing Invoice
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> generateBillInv() {
        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status','ok');
        Savepoint sp = Database.setSavepoint();
        try{
        
            String sWhere = ' WHERE (Opportunity.RecordTypeId =:RT_CERTILOGO_ID) AND (InvoiceStatus__c =:INVOICE_STATUS_READY) Order By OpportunityId, ReadytoInvoiceTimestamp__c ASC';
            List<OpportunityLineItem> listAllOLI = ApexSafe.query().doQuery(SOQL_OPPORTUNITYLINEITEM + sWhere, new Map<String, Object> {'RT_CERTILOGO_ID' => RT_CERTILOGO_ID , 'INVOICE_STATUS_READY' => INVOICE_STATUS_READY});
            Map<String, List<OpportunityLineItem>> mapOppLinePerInvoice = new Map<String, List<OpportunityLineItem>>();
            Map<String, Decimal> mapKeyToTotalAmount = new Map<String, Decimal>();
            for (OpportunityLineItem oli : listAllOLI) {
                String key = oli.OpportunityId + SPLIT_CHAR + oli.ReadytoInvoiceTimestamp__c;
                if (!mapOppLinePerInvoice.containsKey(key)) { mapOppLinePerInvoice.put(key, new List<OpportunityLineItem>()); }
                if (!mapKeyToTotalAmount.containsKey(key)) { mapKeyToTotalAmount.put(key, 0); }
    
                mapOppLinePerInvoice.get(key).add(oli);
                Decimal totalAmount = mapKeyToTotalAmount.get(key);
                //BR-02-04-2025-US-0016999 Update totalAmount += oli.UnitPrice; -> totalAmount += oli.UnitPrice*oli.Quantity;
                totalAmount += oli.UnitPrice*oli.Quantity;
                mapKeyToTotalAmount.put(key, totalAmount);
    
    
            }
            if(mapOppLinePerInvoice.isEmpty()){return mapResult; }
    
            Map<String, BillingInvoice__c> mapBillInv = new Map<String, BillingInvoice__c>();
            for (String key: mapOppLinePerInvoice.keySet()) {
                List<OpportunityLineItem> listOLI =  (List<OpportunityLineItem>) mapOppLinePerInvoice.get(key);
                Decimal totalAmount = mapKeyToTotalAmount.get(key);
                mapBillInv.put(key, setBillInv(listOLI[0], totalAmount));   
            }   
            if(mapBillInv.isEmpty()){ return mapResult; }
            
            //Create Billing Invoice
            Map<String, BillingInvoice__c> mapInsertedBillInv = createBillingInvoice(mapBillInv, METHOD_GENERATE_BILL_INV);
            if(mapInsertedBillInv.isEmpty()){ return mapResult; }
    
            //Create Billing Invoice Line
            List<OpportunityLineItem> listOppLineToUpdate = createBillingInvoiceLine(mapInsertedBillInv, mapOppLinePerInvoice, METHOD_GENERATE_BILL_INV);
            if(listOppLineToUpdate.isEmpty()){ return mapResult; }
    
            //Update Opporutnity Line
            for(OpportunityLineItem oli : listOppLineToUpdate){
                oli.InvoiceStatus__c = INVOICE_STATUS_INVOICED;
            }
            updateOppLine(listOppLineToUpdate, METHOD_GENERATE_BILL_INV);

        }catch(Exception e){
            mapResult.put('status','ko'); mapResult.put('error',e.getMessage()); EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, METHOD_GENERATE_BILL_INV); Database.rollback(sp);
        }
            
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         generateFrequencyBillInv
    @ Version:        1.0
    @ Author:         LoumAng SENG
    @ Purpose:        11.11.2024 / LoumAng SENG / US-0015494 , US-0016115: auto gerenate frequency billing invoice and billing invoice line 
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:   11.11.2024 / LoumAng SENG / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> generateFrequencyBillInv() {

        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status','ok');
        Savepoint sp = Database.setSavepoint();

        try{
            String sWhere = ' WHERE (Opportunity.RecordTypeId =:RT_CERTILOGO_ID) AND (InvoiceStatus__c =:INVOICE_STATUS_INVOICED) AND (BillingType__c=:SAAS_BILLINGTYPE) AND (AutoRenewal__c= true) Order By OpportunityId, ReadytoInvoiceTimestamp__c ASC';
            List<OpportunityLineItem> listAllOLI = ApexSafe.query().doQuery(SOQL_OPPORTUNITYLINEITEM + sWhere, new Map<String, Object> {'RT_CERTILOGO_ID' => RT_CERTILOGO_ID , 'INVOICE_STATUS_INVOICED' => INVOICE_STATUS_INVOICED,'SAAS_BILLINGTYPE'=>SAAS_BILLINGTYPE});
            Map<String, List<OpportunityLineItem>> mapOppLinePerInvoice = new Map<String, List<OpportunityLineItem>>();
            Map<String, Decimal> mapKeyToTotalAmount = new Map<String, Decimal>();
            
            for (OpportunityLineItem oli : listAllOLI) {
    
                Date prevYearly = Date.today().addYears(-1);
                Date prevQuarterly = Date.today().addMonths(-3);
                Date prevSemiYearly = Date.today().addMonths(-6);
                
                if((oli.Frequency__c == YEARLY && (oli.LastBilledDate__c.year() == prevYearly.year()) && (oli.LastBilledDate__c.month() == prevYearly.month()))
                    || (oli.Frequency__c == QUARTERLY && oli.LastBilledDate__c.month() == prevQuarterly.month())
                    || (oli.Frequency__c == SEMI_YEARLY && oli.LastBilledDate__c.month() == prevSemiYearly.month())
                ){
                    mapFrequencyBillInv(mapOppLinePerInvoice, mapKeyToTotalAmount, oli);
                }
                
            }
    
            Map<String, BillingInvoice__c> mapBillInv = new Map<String, BillingInvoice__c>();
            for (String key: mapOppLinePerInvoice.keySet()) {
                List<OpportunityLineItem> listOLI =  (List<OpportunityLineItem>) mapOppLinePerInvoice.get(key);
                Decimal totalAmount = mapKeyToTotalAmount.get(key);
                mapBillInv.put(key, setBillInv(listOLI[0], totalAmount));   
            }   
            if(mapBillInv.isEmpty()){ return mapResult; }
            
            //Create Billing Invoice
            Map<String, BillingInvoice__c> mapInsertedBillInv = createBillingInvoice(mapBillInv, METHOD_GENERATE_FREQUENCY_BILL_INV);
            if(mapInsertedBillInv.isEmpty()){ return mapResult; }
    
            //Create Billing Invoice Line
            List<OpportunityLineItem> listOppLineToUpdate = createBillingInvoiceLine(mapInsertedBillInv, mapOppLinePerInvoice, METHOD_GENERATE_FREQUENCY_BILL_INV);
            if(listOppLineToUpdate.isEmpty()){ return mapResult; }
    
             //Update OpporutnityLineItem
            updateOppLine(listOppLineToUpdate,  METHOD_GENERATE_FREQUENCY_BILL_INV);

        }catch(Exception e){
            mapResult.put('status','ko'); mapResult.put('error',e.getMessage()); EBH_ApexLogger.logError(new List<Exception>{e}, CLASS_NAME, METHOD_GENERATE_FREQUENCY_BILL_INV); Database.rollback(sp);
        }
        return mapResult;

    }

    public static void mapFrequencyBillInv(Map<String, List<OpportunityLineItem>> mapOppLinePerInvoice, Map<String, Decimal> mapKeyToTotalAmount, OpportunityLineItem oli) {
        String key = oli.Frequency__c +SPLIT_CHAR+ oli.OpportunityId + SPLIT_CHAR + oli.ReadytoInvoiceTimestamp__c;
        if (!mapOppLinePerInvoice.containsKey(key)) { mapOppLinePerInvoice.put(key, new List<OpportunityLineItem>()); }
        if (!mapKeyToTotalAmount.containsKey(key)) { mapKeyToTotalAmount.put(key, 0); }

        mapOppLinePerInvoice.get(key).add(oli);
        Decimal totalAmount = mapKeyToTotalAmount.get(key);
        totalAmount += oli.UnitPrice;
        mapKeyToTotalAmount.put(key, totalAmount);
    }

    // This method is used to create billing invoice
    private static Map<String, BillingInvoice__c> createBillingInvoice(Map<String, BillingInvoice__c> mapBillInvToInsert, String methodName){

        Map<String, BillingInvoice__c> mapInsertedBillInv = new Map<String, BillingInvoice__c>();

        List<Database.SaveResult> listBillInvResult = ApexSafe.dml().secCheck(false).doInsert(mapBillInvToInsert.values(), true);
        List<Database.Error> listError = new  List<Database.Error>();
        for(Database.SaveResult result : listBillInvResult){
            if(!result.isSuccess()){
                listError.addAll(result.getErrors());
            }
        }
        if(!listError.isEmpty()){
            EBH_ApexLogger.logError(listError, CLASS_NAME, methodName + '_' + 'createBillingInvoice');
        }
        for(String key : mapBillInvToInsert.keySet()){
            BillingInvoice__c billInv = mapBillInvToInsert.get(key);
            if(billInv.Id != null){
                mapInsertedBillInv.put(key, billInv);
            }
        }

        return mapInsertedBillInv;
    }

    // This method is used to create billing invoice line
    private static List<OpportunityLineItem> createBillingInvoiceLine(Map<String, BillingInvoice__c> mapInsertedBillInv, Map<String, List<OpportunityLineItem>> mapOppLinePerInvoice, String methodName){
        List<BillingInvoiceLine__c> listBillInvLineToInsert = new List<BillingInvoiceLine__c>();
        Map<Id, OpportunityLineItem> mapOppLineToUpdate = new Map<Id, OpportunityLineItem>();
        for(String key : mapInsertedBillInv.keySet()){
            BillingInvoice__c billInv = mapInsertedBillInv.get(key);
            for (OpportunityLineItem oli : mapOppLinePerInvoice.get(key)) {
                listBillInvLineToInsert.add(setBillInvLine(oli, mapInsertedBillInv.get(key).Id));
                mapOppLineToUpdate.put(oli.Id, oli);
            }
        }
        List<Database.SaveResult> listBillInvLineResult = ApexSafe.dml().secCheck(false).doInsert(listBillInvLineToInsert, true);
        List<Database.Error> listError = new  List<Database.Error>();
        for(Database.SaveResult result : listBillInvLineResult){
            if(!result.isSuccess()){
                listError.addAll(result.getErrors());
            }
        }
        if(!listError.isEmpty()){
            EBH_ApexLogger.logError(listError,CLASS_NAME, methodName + '_' + 'createBillingInvoiceLine');
        }

        List<OpportunityLineItem> listOppLineToUpdate = new List<OpportunityLineItem>();
        for(BillingInvoiceLine__c billInvLIne : listBillInvLineToInsert){
            if(billInvLIne.Id == null){ continue; }
            OpportunityLineItem oli = mapOppLineToUpdate.get(billInvLine.OpportunityProduct__c);
            oli.LastBilledDate__c = Date.today();
            listOppLineToUpdate.add(oli);
        }

        return listOppLineToUpdate;
    }

    // This method is used to update OpporutnityLineItem
    private static void updateOppLine(List<OpportunityLineItem> listOppLineToUpdate, String methodName){
        //Once Opportunity is approved via Approval Process, record will be locked and to allow user to update OpportunityLineItem, we need to use WithoutSharing.doUpdate to avoid Lock Record Error
        List<Database.SaveResult> listOppLineResult = WithoutSharing.doUpdate(listOppLineToUpdate, true);
        List<Database.Error> listError = new  List<Database.Error>();
        for(Database.SaveResult result : listOppLineResult){
            if(!result.isSuccess()){
                listError.addAll(result.getErrors());
            }
        }
        if(!listError.isEmpty()){
            EBH_ApexLogger.logError(listError, CLASS_NAME, methodName + '_' + 'updateOppLine');
        }
    }

    // This method is used to set billing invoice data
    private static BillingInvoice__c setBillInv(OpportunityLineItem oli , Decimal totalOLIAmount){
        
        String sOfferNumber = oli.Opportunity.Offer_Number__c;// Example: Offer_Number__c= NO-000001
        String[] offerNumbers = sOfferNumber.split('-');

        BillingInvoice__c bi = new BillingInvoice__c();
            bi.OrderType__c = OR_ORDERTYPE;
            bi.RecordTypeId = RT_SAPINVOICE_ID;
            bi.BillingDate__c = Date.today();
            bi.PricingCondition__c = PRICING_CONDITION;
            bi.BillingStatus__c = Label.BillingStatus;//Draft or Approved(based on a setting)
            bi.CurrencyIsoCode = oli.CurrencyIsoCode;
            bi.RelatedBillingOpportunity__c = oli.OpportunityId;
            bi.SalesOrder__c = Integer.valueOf(offerNumbers[1]);// Example: Offer_Number__c= NO-000001 -> then SalesOrder__c= 000001
            bi.TotalInvoiceAmount__c = totalOLIAmount;
            bi.AlternativeInvoiceNumber__c = '';
            bi.PaymentTerms__c = oli.Opportunity.Account?.Payment_Terms__c; //LA-22-07-2025-US-0032977: Payment term of Billing Invoice populates value from related opportunity Account Payment term

        return bi;
    }

    // This method is used to set billing invoice Line data
    private static BillingInvoiceLine__c setBillInvLine(OpportunityLineItem oli, Id billInvId){
        BillingInvoiceLine__c bil = new BillingInvoiceLine__c();
        bil.OpportunityProduct__c = oli.Id;
        bil.BillingInvoice__c = billInvId;
        bil.InvoiceQuantity__c= oli.Quantity;
        bil.InvoiceUnitPrice__c = oli.UnitPrice;
        bil.Account__c = oli.Opportunity.Account.Name;
        return bil;
    }

}