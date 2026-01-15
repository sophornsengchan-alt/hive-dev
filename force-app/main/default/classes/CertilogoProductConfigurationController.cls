/*********************************************************************************************************************************
@ Class:          CertilogoProductConfigurationController
@ Version:        1.0
@ Author:         Mony Nou (mony.nout@gaea-sys.com)
@ Purpose:        Handle the Product Configuration functionality
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.09.2024 / Mony Nou / US-0015764 Create the class
@                 15.10.2024 / Mony Nou / US-0015948 - Certilogo - Product Selector and Configurator Part 4a - Product Configurator - Top Button Actions & Popup
@                 28.10.2024 / Acmatac Seing / US-0015949 - Certilogo - Product Selector and Configurator Part 5 - Product Configurator - Side Button Visibility
@                 06.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations
@                 12.11.2024 / Veenus Gollapalli / US-0015966 - Certilogo - Docgen - 4 docs to be generated
@				  21.11.2024 / Mony Nou / US-0016253 - Certilogo - updates to Product Configurator
@                 17.01.2025 / Veenus Gollapalli / US-0016570 - Certilogo - Docgen Format Updates
@                 06.03.2025 / Mony Nou / US-0016869 - Certilogo - P1 - Split Lines for Shipping
@                 18.04.2025 / SRONG TIN / US-0017105 - Certilogo - Allow Deliver To to be entered for Freight
@                 19.08.2025 / Mony Nou / US-0033383 - P1-Conga Documents not generating correctly - process hangs
*********************************************************************************************************************************/
public with sharing class CertilogoProductConfigurationController {
    
    //MN-06112024-US-0016092-Added Product2.IsDiscount__c to below query SOQL_OPPORTUNITYLINEITEM & SOQL_PRODUCT2
    //MN-21112024-US-0016253-Added SUB Query of OpportunityProductDocument__r to below query SOQL_OPPORTUNITYLINEITEM
    private static final String SOQL_OPPORTUNITYLINEITEM = 'SELECT id, Quantity, UnitPrice, TotalPrice, InvoiceStatus__c, Description, DeliveryTo__c, DeliveryTo__r.Name, Frequency__c, PricebookEntryId, PricebookEntry.Pricebook2Id, PricebookEntry.CurrencyIsoCode, Product2Id, Product2.Description, Product2.ProductCode, Product2.Name, Product2.BillingType__c, Product2.Billing_Category__c, Product2.QuantityUnitOfMeasure, Product2.Family, Product2.IsDiscount__c, Product2.Manufacturer__c, Product2.Manufacturer__r.Name, (select id, OpportunityProductDocument__c from OpportunityProductDocument__r where OpportunityProductDocument__r.Status__c =:ACTIVE_STATUS AND OpportunityProductDocument__r.RecordType.DeveloperName=:RT_CONFIRMORDER) FROM OpportunityLineItem WHERE OpportunityId =:opportunityId ORDER BY CreatedDate ASC';
    private static final String SOQL_PRODUCT2 = 'SELECT id, ProductCode, Name, Description, BillingType__c, Billing_Category__c, QuantityUnitOfMeasure, Family, IsDiscount__c, Manufacturer__c, Manufacturer__r.Name, (select Id, CurrencyIsoCode, UnitPrice from PricebookEntries where id in:sPricebookEntrytIds) FROM Product2 WHERE Id in (Select Product2Id from PricebookEntry where id in:sPricebookEntrytIds)';
    private static final String ACTIVE_STATUS = 'Active';
    private static final String SOQL_PRODUCT_DOCUMENT_LINE = 'SELECT id, OpportunityProduct__c, OpportunityProductDocument__c, OpportunityProductDocument__r.RecordType.DeveloperName FROM OpportunityProductDocumentLine__c WHERE OpportunityProduct__c IN: oppLineIds AND OpportunityProductDocument__r.Status__c =: ACTIVE_STATUS';
    private static final String PRODUCTFAMILY_SAAS = 'SaaS';
    private static final String PRODUCTFAMILY_FREIGHT = 'Freight';//SRONG 18.04.2025 - US-0017105
    private static final String DEF_FREQUENCY = 'Yearly';
    private static final String CLASSNAME_PREFIX = 'CertilogoButtonService.';
    private static final String SOQL_CONTENTDOCUMENTLINK = 'SELECT Id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId IN:allLinkedEntityId AND ContentDocument.FileType IN:allowedFileType ORDER BY SystemModstamp ASC';
    private static final String SOQL_BILLING_INVOICE_LINE = 'SELECT Id, BillingInvoice__c, OpportunityProduct__c FROM BillingInvoiceLine__c WHERE OpportunityProduct__c IN: oppLineIds';
    private static final string RT_PURCHASEORDER = 'PurchaseOrder';
    private static final string RT_SHIPPINGDOC = 'ShippingDocument';
    private static final string RT_PROFORMAINV = 'ProFormaInvoice';
    private static final string RT_CONFIRMORDER = 'ConfirmationOrder';
    private static final string PURCHASEORDER = 'Purchase Order';
    private static final string SHIPPINGDOC = 'Shipping Document';
    private static final string PROFORMAINV = 'Proforma';
    private static final string CONFIRMORDER = 'Confirmation Order';
    //MN-06032025-US-0016869
    private static final String INVOICESTATUS_DRAFT = 'Draft'; 
    private static final String OPPSTAGE_CLOSEDWON = 'Closed Won';
    private static final String SIDEBUTTON_SPLITLINE = 'SplitLine';
    private static final String SOQL_ELIGIBLESPLT_LINEITEM = 'SELECT id FROM OpportunityLineItem WHERE Quantity > 1 AND Id IN:oppLineIds AND Product2.RequiresManufacture__c = true AND Opportunity.StageName =:OPPSTAGE_CLOSEDWON AND Opportunity.StockOnlyOrder__c = FALSE AND InvoiceStatus__c =:INVOICESTATUS_DRAFT AND Id NOT IN (SELECT OpportunityProduct__c FROM OpportunityProductDocumentLine__c WHERE (OpportunityProductDocument__r.RecordType.DeveloperName =:RT_SHIPPINGDOC OR OpportunityProductDocument__r.RecordType.DeveloperName =:RT_PROFORMAINV) AND OpportunityProductDocument__r.Status__c =:ACTIVE_STATUS )';
    private static final Map<String, String> MAP_OPPORTUNITY_PRODUCT_BUTTON_NAME = new Map<String, String>{'SplitLine' => 'Split Line', 'ProFormaInvoice'=>'View Shipping', 'ShippingDocument'=>'View Shipping', 'PurchaseOrder'=>'View PO', 'ConfirmationOrder'=>'View Order Confirmation', 'BillingInvoice'=>'View Invoice'};
    /*********************************************************************************************************************************
    @ Method:       initData
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Initialize the Product Configuration Screen
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.09.2024 / Mony Nou / Created the Method.
    @                 28.10.2024 / Acmatac Seing / US-0015949 - Certilogo - Product Selector and Configurator Part 5 - Product Configurator - Side Button Visibility
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> initData(String opportunityId, String pricebookId, Object sPricebookEntrytIds){

        Map<String,Object> mapResult = new Map<String,Object>();
        mapResult.put('status','success');

        try {
            
            Sobject[] oliList = ApexSafe.query().doQuery(SOQL_OPPORTUNITYLINEITEM, new Map<String, Object> {'opportunityId' => opportunityId, 'ACTIVE_STATUS' => ACTIVE_STATUS, 'RT_CONFIRMORDER' => RT_CONFIRMORDER}); //MN-21112024-US-0016253-pass 2 more params: ACTIVE_STATUS & RT_CONFIRMORDER
            
            List<ProductsConfigurationWrapper> listOPW = new List<ProductsConfigurationWrapper>();
            Integer index = 0;

            OpportunityLineItemWrapper oppLineItemWrapper = prepareOppProductDocumentLine((List<OpportunityLineItem>)oliList);
            oppLineItemWrapper.sEligibleSplitOLI.addAll(prepareSplitLine((List<OpportunityLineItem>)oliList)); //MN-06032025-US-0016869

            Map<String, Object> mapOPLIandFile = oppLineItemWrapper.mapOpportunityProductDocumentWithFileId;
            Set<Id> opptyProdLineIdSet = oppLineItemWrapper.opportunityLineItemIds;

            Boolean hasActiveConfirmOrder = false; //MN-21112024-US-0016253-Check if there is any active Confirmation Order

            for (OpportunityLineItem oli : (List<OpportunityLineItem>)oliList) {

                ProductsConfigurationWrapper opw = new ProductsConfigurationWrapper(oli, null, opportunityId, null);
                opw.index = ++index;
                opw.currencyCode = oli.PricebookEntry.CurrencyIsoCode;
                opw.hasAnyActiveOppProdDocument = opptyProdLineIdSet.contains(oli.Id);
                for(String opdRT : MAP_OPPORTUNITY_PRODUCT_BUTTON_NAME.keySet()) {
                    //MN-06032025-US-0016869
                    if (opdRT == SIDEBUTTON_SPLITLINE && oppLineItemWrapper.sEligibleSplitOLI.contains(oli.Id)) { 
                        RowButtonWrapper rbw = new RowButtonWrapper(MAP_OPPORTUNITY_PRODUCT_BUTTON_NAME.get(opdRT), null);
                        rbw.isSplitLine = true;
                        rbw.oli = oli;
                        opw.listRowButton.add(rbw);
                    }
                    else if (mapOPLIandFile.containsKey(opdRT+'#'+oli.Id)) {
                        opw.listRowButton.add(new RowButtonWrapper(MAP_OPPORTUNITY_PRODUCT_BUTTON_NAME.get(opdRT), String.valueOf(mapOPLIandFile.get(opdRT+'#'+oli.Id))));
                    }
                }
                listOPW.add(opw);

                //MN-21112024-US-0016253-Check if there is any active Confirmation Order
                if (!oli.OpportunityProductDocument__r.isEmpty() && !hasActiveConfirmOrder) { hasActiveConfirmOrder = true; } 
            }
            
            if (sPricebookEntrytIds != null) { //Selected Products (PricebookEntry & Pricebook) from Product Selection Screen

                List<String> pbeIds = (List<String>) JSON.deserialize(JSON.serialize(sPricebookEntrytIds), List<String>.class);

                //Get Product2 Information from PricebookEntry
                Sobject[] prodList = ApexSafe.query().doQuery(SOQL_PRODUCT2, new Map<String, Object> {'sPricebookEntrytIds' => pbeIds});
                for(Product2 prod : (List<Product2>)prodList) {
                    String pbeId = prod.PricebookEntries.get(0).Id;
                    ProductsConfigurationWrapper opw = new ProductsConfigurationWrapper(null, prod, opportunityId, pbeId);
                    opw.index = ++index;
                    opw.currencyCode = prod.PricebookEntries.get(0).CurrencyIsoCode;
                    listOPW.add(opw);
                }
            }
    
            mapResult.put('data',listOPW);
            mapResult.put('hasActiveConfirmOrder', hasActiveConfirmOrder); //MN-21112024-US-0016253-Check if there is any active Confirmation Order 

            //MN-15102024-US-0015948-Initialize buttons
            initButtons(mapResult, opportunityId);

        }catch(Exception ex){
            mapResult.put('status','error'); mapResult.put('error',ex.getMessage());//EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoProductConfigurationController','initData');
        }
        
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:       initButtons
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Initialize the Buttons to dipslay on screen
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.10.2024 / Mony Nou / Created the Method.
    *********************************************************************************************************************************/
    public static void initButtons(Map<String,Object> mapResult, String opportunityId) {

        List<ButtonWrapper> listTopButtons = new List<ButtonWrapper>();
        Map<String, CertilogoButtonConfiguration__mdt> mAllMetaData = CertilogoButtonConfiguration__mdt.getAll();
        Map<String, List<CertilogoButtonConfiguration__mdt>> mButtonValidation = new Map<String, List<CertilogoButtonConfiguration__mdt>>();
        
        for (CertilogoButtonConfiguration__mdt metadata : mAllMetaData.values()) {

            if (!metadata.Active__c) { continue; }

            if (metadata.Top_Button__c) { 
                initButton(opportunityId, metadata, listTopButtons);
            } 
            else if (metadata.DeveloperName.contains('_Validation')) {
                initButtonValidation(metadata, mButtonValidation);
            }
            
        }

        mapResult.put('topButtons',listTopButtons);
        mapResult.put('buttonValidation',mButtonValidation);
    }

    /*********************************************************************************************************************************
    @ Method:       initButton
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Initialize ButtonWrapper for each button
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.10.2024 / Mony Nou / Created the Method.
    *********************************************************************************************************************************/
    public static void initButton (String opportunityId, CertilogoButtonConfiguration__mdt metadata, List<ButtonWrapper> listButtons) {

        Boolean isDisplay = false;
                
        try{

            String className = CLASSNAME_PREFIX + metadata.DeveloperName;
            CertilogoButtonService.ICertilogoButton button = (CertilogoButtonService.ICertilogoButton) Type.forName(className).newInstance();
            isDisplay = button.getButtonVisibility(new Map<String, Object> {'opportunityId' => opportunityId, 'buttonVisibilityQuery' => metadata.ButtonVisibilityQuery__c});

        }catch(Exception ex){ isDisplay = false; }

        if (isDisplay) {
            ButtonWrapper button = new ButtonWrapper(metadata);
            listButtons.add(button);
        }

    }

    /*********************************************************************************************************************************
    @ Method:       initButtonValidation
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Initialize Button Validation for each button
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.10.2024 / Mony Nou / Created the Method.
    *********************************************************************************************************************************/
    public static void initButtonValidation (CertilogoButtonConfiguration__mdt metadata, Map<String, List<CertilogoButtonConfiguration__mdt>> mButtonValidation) {

        if (!mButtonValidation.containsKey(metadata.MasterLabel)) {
            mButtonValidation.put(metadata.MasterLabel, new List<CertilogoButtonConfiguration__mdt>());
        }
        mButtonValidation.get(metadata.MasterLabel).add(metadata);
    }

    /*********************************************************************************************************************************
    @ Method:       saveRecords
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Save Records from Product Configuration Screen
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.10.2024 / Mony Nou / Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> saveRecords(List<OpportunityLineItem> listRecord){

        Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
        
        try{
            
            mapResult.put('status','success');

            Database.UpsertResult[] upsertResult = ApexSafe.dml().doUpsert(listRecord, OpportunityLineItem.Id , true);
            List<Database.Error> listException = new List<Database.Error>();

            for (Database.UpsertResult upRe : upsertResult) {
                if (!upRe.isSuccess()) {
                    listException.addAll(upRe.getErrors());
                }
            }

            if(!listException.isEmpty()) {
                mapResult.put('status','error');
                mapResult.put('errorRecs',listException);
                EBH_ApexLogger.logError(listException, 'CertilogoProductConfigurationController','saveRecords');
            } 

            
            
        }catch(Exception ex){ Database.rollback(sp); mapResult.put('status','error'); mapResult.put('error',ex.getMessage()); EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoProductConfigurationController','saveRecords');}

        //MN-08112024-US-0016092
        if (mapResult.containsKey('error')) { mapResult.put('error', checkCustomErrorMessages(String.valueOf(mapResult.get('error')))); }

        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:       validateProducts
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Validating Products from Product Configuration Screen
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 16.10.2024 / Mony Nou / US-0015948: Created the Method.
    @                 21.11.2024 / Mony Nou / US-0016253 - Certilogo - updates to Product Configurat
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> validateProducts(String oppId, List<String> oppLineIds, String buttonName, List<CertilogoButtonConfiguration__mdt> validations){

        Map<String,Object> mapResult = new Map<String,Object>();

        try{
            
            mapResult.put('status','success');

            Boolean isPass = true;

            for (CertilogoButtonConfiguration__mdt validation : validations) {

                String className = CLASSNAME_PREFIX + buttonName;
                CertilogoButtonService.ICertilogoButton button = (CertilogoButtonService.ICertilogoButton) Type.forName(className).newInstance();
                //MN-21112024-US-0016253-Added oppId to the map
                isPass = button.validate(new Map<String, Object> {'opportunityId' => oppId, 'oppLineIds' => oppLineIds, 'validationQuery' => validation.ValidationQuery__c, 'evalCriteria' => validation.Evaluation_Criteria__c});

                if (!isPass) { 

                    mapResult.put('validationMessage', validation.ValidationErrorMessage__c);
                    break; 
                }
            }

            mapResult.put('isPass',isPass);

        }catch(Exception ex){ mapResult.put('status','error'); mapResult.put('error',ex.getMessage()); EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoProductConfigurationController','validateProducts');}
        
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:       getFieldSetFields
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Get FieldSet Fields from Object
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.10.2024 / Mony Nou / US-0015948: Created the Method.
    *********************************************************************************************************************************/
    @AuraEnabled(cacheable=true)
    public static List<String> getFieldSetFields(String objectName, String fieldSetName) {
        Schema.FieldSet fieldSet = Schema.getGlobalDescribe()
            .get(objectName)
            .getDescribe()
            .fieldSets
            .getMap()
            .get(fieldSetName);
        
        List<String> fieldNames = new List<String>();
    
        for (Schema.FieldSetMember f : fieldSet.getFields()) {
            fieldNames.add(f.getFieldPath()+';'+f.getRequired());
        }
        return fieldNames;
    }



    /*********************************************************************************************************************************
    @ Method:       submitProducts
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Submit Products and action as per button clicked
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.10.2024 / Mony Nou / US-0015957: Created the Method.
    @                 07.03.2025 / Mony Nou / US-0016869: Added mAdditionalParams
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> submitProducts(List<String> oppLineIds, String buttonName, OpportunityProductDocument__c oppProdDoc, Map<String, Object> mAdditionalParams){

        Map<String,Object> mapResult = new Map<String,Object>();

        try{
            
            String className = CLASSNAME_PREFIX + buttonName;
            CertilogoButtonService.ICertilogoButton button = (CertilogoButtonService.ICertilogoButton) Type.forName(className).newInstance();
            mapResult = button.submitAction(new Map<String, Object> {'oppLineIds' => oppLineIds, 'oppProdDoc' => oppProdDoc, 'additionalParams' => mAdditionalParams});

        }catch(Exception ex){ mapResult.put('status','error'); mapResult.put('error',ex.getMessage()); EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoProductConfigurationController','validateProducts');}
        
        //MN-08112024-US-0016092
        if (mapResult.containsKey('error')) { mapResult.put('error', checkCustomErrorMessages(String.valueOf(mapResult.get('error')))); }

        return mapResult;
    }

    //MN-08112024-US-0016092
    private static Set<String> sCustomErrorMessage {
        get {
            if (sCustomErrorMessage == null) {
                sCustomErrorMessage = new Set<String>{System.Label.Certilogo_Lock_Product_Error_Message, System.Label.Certilogo_Lock_Product_Error_Message_Delete, System.Label.Certilogo_Lock_Product_Error_Message_LockRecord};
            }
            return sCustomErrorMessage;
        }

        private set;
    }

    /*********************************************************************************************************************************
    @ Method:       checkCustomErrorMessages
    @ Version:      1.0
    @ Author:       Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:      Beautify the error message if it is a custom error message
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.11.2024 / Mony Nou / Created the Method.
    *********************************************************************************************************************************/
    private static String checkCustomErrorMessages(String errorMessage) {
        
        for (String customErrorMessage : sCustomErrorMessage) {
            if (errorMessage.contains(customErrorMessage)) {
                errorMessage = customErrorMessage;
            }
        }

        return errorMessage;

    }

    /*********************************************************************************************************************************
    @ Method:       prepareOppProductDocumentLine
    @ Version:      1.0
    @ Author:       Anujit (US0015950)
    @ Purpose:      get active opportunity product document for each Oppty line items
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.10.2024 / Mony Nou / US-0015957: Created the Method.
    @                 28.10.2024 / Acmatac Seing / US-0015949 - Certilogo - Product Selector and Configurator Part 5 - Product Configurator - Side Button Visibility
    *********************************************************************************************************************************/
    private static OpportunityLineItemWrapper prepareOppProductDocumentLine(List<OpportunityLineItem> oliList){
        OpportunityLineItemWrapper oLIWrapper = new OpportunityLineItemWrapper();
        Set<String> allowedFileType = new Set<String>{'PDF'};
        Set<Id> allOLIIds = new Set<Id>();
        Set<Id> allLinkedEntityId = new Set<Id>();
        Set<Id> oliIdSet = new Set<Id>();

        Map<String, String> mapLinkedEntityIdandFile = new Map<String, String>();

        // {'ProFormaInvoice#OpportunityProductId' => 'FileId'}
        Map<String, String> mapOPLIandFile = new Map<String, String>();

        for (OpportunityLineItem oli : oliList) {
            oliIdSet.add(oli.id);
        }

        List<OpportunityProductDocumentLine__c> listProductDocLine = (List<OpportunityProductDocumentLine__c>) ApexSafe.query().doQuery(SOQL_PRODUCT_DOCUMENT_LINE, new Map<String, Object> {'oppLineIds' => oliIdSet,'ACTIVE_STATUS' => ACTIVE_STATUS});
        List<BillingInvoiceLine__c> listBillingInvoiceLine = (List<BillingInvoiceLine__c>)ApexSafe.query().doQuery(SOQL_BILLING_INVOICE_LINE, new Map<String, Object> {'oppLineIds' => oliIdSet});

        // Loop through each OpportunityProductDocumentLine__c to store OpportunityProductDocument Id
        for(OpportunityProductDocumentLine__c eachOpptyProdLine : listProductDocLine){
            allOLIIds.add(eachOpptyProdLine.OpportunityProduct__c);
            allLinkedEntityId.add(eachOpptyProdLine.OpportunityProductDocument__c);
        }

        // Loop through each BillingInvoiceLine__c to store BillingInvoice__c Id
        for(BillingInvoiceLine__c eachBillingInvLine : listBillingInvoiceLine){
            allLinkedEntityId.add(eachBillingInvLine.BillingInvoice__c);
        }

        // Check !isEmpty to prevent this error "ContentDocumentLink requires a filter by a single Id on ContentDocumentId or LinkedEntityId using the equals operator or multiple Id's using the IN operator."
        if (!allLinkedEntityId.isEmpty()) {
            // Loop through each ContentDocumentLink record to store mapping of LinkedEntityId and ContentDocument Id
            for(ContentDocumentLink singleFile : (List<ContentDocumentLink>) ApexSafe.query().doQuery(SOQL_CONTENTDOCUMENTLINK, new Map<String, Object> {'allLinkedEntityId' => allLinkedEntityId, 'allowedFileType' => allowedFileType})){
                mapLinkedEntityIdandFile.put(singleFile.LinkedEntityId, singleFile.ContentDocumentId);
            }
        }

        // Loop through each OpportunityProductDocumentLine__c record again to put into mapOPLIandFile
        for(OpportunityProductDocumentLine__c eachOpptyProdLine : listProductDocLine){
            if(mapLinkedEntityIdandFile.containsKey(eachOpptyProdLine.OpportunityProductDocument__c)){
                mapOPLIandFile.put(eachOpptyProdLine.OpportunityProductDocument__r.RecordType.DeveloperName + '#' + eachOpptyProdLine.OpportunityProduct__c, mapLinkedEntityIdandFile.get(eachOpptyProdLine.OpportunityProductDocument__c));
            }
        }

        // Loop through each BillingInvoiceLine__c record again to put into mapOPLIandFile
        for(BillingInvoiceLine__c eachBillingInvLine : listBillingInvoiceLine){
            if(mapLinkedEntityIdandFile.containsKey(eachBillingInvLine.BillingInvoice__c)){
                mapOPLIandFile.put('BillingInvoice#' + eachBillingInvLine.OpportunityProduct__c, mapLinkedEntityIdandFile.get(eachBillingInvLine.BillingInvoice__c));
            }
        }


        oLIWrapper.opportunityLineItemIds = allOLIIds;
        oLIWrapper.mapOpportunityProductDocumentWithFileId = mapOPLIandFile;
        
        return oLIWrapper;
    
    }

    
    /*********************************************************************************************************************************
    @ Method:       prepareSplitLine
    @ Version:      1.0
    @ Author:       Mony Nou (US-0016869)
    @ Purpose:      get opporutnity product line that eligible for split line
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.03.2025 / Mony Nou / US-0016869: Created the Method.
    *********************************************************************************************************************************/
    private static Set<Id> prepareSplitLine(List<OpportunityLineItem> oliList){

        OpportunityLineItemWrapper oLIWrapper = new OpportunityLineItemWrapper();
        
        // Get Eligible Split Line Opporutnity Line Item: a manufacture line where invoice_status = Draft AND there is no active Shipping Document
        Map<Id, OpportunityLineItem> mEligibleSplitOLI = new Map<Id, OpportunityLineItem>((List<OpportunityLineItem>) ApexSafe.query().doQuery(SOQL_ELIGIBLESPLT_LINEITEM, new Map<String, Object> {'oppLineIds' => oliList,'INVOICESTATUS_DRAFT' => INVOICESTATUS_DRAFT, 'OPPSTAGE_CLOSEDWON' => OPPSTAGE_CLOSEDWON, 'RT_SHIPPINGDOC' => RT_SHIPPINGDOC, 'RT_PROFORMAINV' => RT_PROFORMAINV, 'ACTIVE_STATUS' => ACTIVE_STATUS}));
        
        return mEligibleSplitOLI.keySet();
    
    }

    /*********************************************************************************************************************************  
    @ Method:      getSessionIdFromVFPage
    @ Purpose:     This Method is used to fetch current user session id using visualforce page
    *********************************************************************************************************************************/
    public static String getSessionIdFromVFPage(){
        If(!Test.isRunningTest()){
          String content = Page.APISESSION.getContent().toString();
          Integer s = content.indexOf('Start_Of_Session_Id') + 'Start_Of_Session_Id'.length(),
                e = content.indexOf('End_Of_Session_Id');  
            return content.substring(s, e);
        }else{
            return 'testsession';
        }
        
        
    }
    /*********************************************************************************************************************************  
    @ Method:      settemplateandfilename
    @ Purpose:     This Method is used to set conga templateid and filename of the conga document
    *********************************************************************************************************************************/
    public static Map<String,Object> settemplateandfilename(List<OpportunityProductDocument__c> oppProdDoc, String docRecordType){
        String offernumber = oppProdDoc[0].Opportunity__r.Offer_Number__c;
        String createddate = oppProdDoc[0].CreatedDate.date().format();
        Id templateId;
        String fileName;
        Map<String,Object> mapReturnValue = new Map<String,Object>();
        If(docRecordType == RT_CONFIRMORDER){
            templateId = System.Label.CO_Conga_TempId;
            fileName = CONFIRMORDER+' '+offernumber+' '+createddate;
        }else if(docRecordType == RT_PROFORMAINV){
            templateId = System.Label.PFI_Conga_TempId;
            fileName = PROFORMAINV+' '+oppProdDoc[0].Name+' '+createddate;
        }else if(docRecordType == RT_SHIPPINGDOC){
            templateId = System.Label.SD_Conga_TempId;
            fileName = SHIPPINGDOC+' '+oppProdDoc[0].DDTNumber__c+' '+oppProdDoc[0].DDTYear__c+' '+createddate;
        }else{
            templateId = System.Label.PO_Conga_TempId;
            fileName = PURCHASEORDER+' '+oppProdDoc[0].Name+' '+createddate;
        }
        mapReturnValue.put('templateId',templateId);
        mapReturnValue.put('fileName',fileName);
        return mapReturnValue;
        
    }
   
    /*********************************************************************************************************************************
    @ Method:       mergeDocument
    @ Version:      1.0
    @ Author:       Veenus G (US0015966)
    @ Purpose:      Certilogo - Docgen - 4 docs to be generated - This Method is used to Generate and Merge Conga document to 
                    Opportunity Product Document
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 12.11.2024 / Veenus Gollapalli / US-0015966: Created the Method.
    @ Change history: 17.01.2025 / Veenus Gollapalli / US-0016570 - Certilogo - Docgen Format Updates
    @                 19.08.2025 / Mony Nou / US-0033383 - P1-Conga Documents not generating correctly - process hangs
    *********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> mergeDocument(Id oppProdDocId, String docRecordType) {
        Map<String,Object> mapResult = new Map<String,Object>();
        Id templateId;
        String fileName;
        String sessionId;
        String query;
        String customQueryId;
        String baseEndPoint;
        String endPoint;
        String cultureCode;
        Id contentVersion;
        List<ContentVersion> contentVersionDetails;
        List<OpportunityProductDocument__c> oppProdDoc;
        Map<String, Object> templateAndFileDetails;
        try{
            sessionId = getSessionIdFromVFPage(); 
            query = 'SELECT Id,CreatedDate,Name,DDTNumber__c,DDTYear__c,Opportunity__r.Offer_Number__c,Culture_Code__c FROM OpportunityProductDocument__c WHERE Id =:oppProdDocId';
            oppProdDoc = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppProdDocId' => oppProdDocId});
            If(!oppProdDoc.isempty()){
                templateAndFileDetails = settemplateandfilename(oppProdDoc,docRecordType);
                templateId =(Id) templateAndFileDetails.get('templateId');
                fileName = (String)templateAndFileDetails.get('fileName'); 
                cultureCode = oppProdDoc[0].Culture_Code__c;
            }
            customQueryId = System.Label.Cetilogo_Query; 
            Http h = new Http();
            HttpRequest req = new HttpRequest();
            HttpResponse res = new HttpResponse(); 
            baseEndPoint = 'https://composer.congamerge.com/composer8/index.html';
            endPoint = baseEndPoint +  '?sessionId=' + EncodingUtil.urlEncode(sessionId, 'UTF-8') +
                '&serverUrl=' + EncodingUtil.urlEncode(System.Url.getOrgDomainUrl().toExternalForm() + '/services/Soap/u/51.0/' + UserInfo.getOrganizationId(), 'UTF-8')  + 
                '&id=' + EncodingUtil.urlEncode(oppProdDocId, 'UTF-8') +	
                '&templateid='+EncodingUtil.urlEncode(templateId, 'UTF-8')+
                '&QueryId='+EncodingUtil.urlEncode(customQueryId, 'UTF-8')+
                '&DefaultPDF=1' +
                '&SC0=1'+ 
                '&SC1=SalesforceFile'+
                '&OFN='+ EncodingUtil.urlEncode(fileName, 'UTF-8')+
                '&CurrencyCulture='+EncodingUtil.urlEncode(cultureCode, 'UTF-8')+  //US-0016570
                '&APIMode=1';
                                            
            req.setEndpoint(endPoint);
            req.setMethod('GET');
            req.setTimeout(60000);
            res = h.send(req);     

            contentVersion= (Id) res.getBody();
            //contentVersionDetails=[select id, ContentDocumentId from ContentVersion where id=:contentVersion];
            //MN-21112024: Query with ApexSafe
            query = 'select id, ContentDocumentId from ContentVersion where id=:contentVersion';
            contentVersionDetails = (List<ContentVersion>) ApexSafe.query().doQuery(query, new Map<String,Object>{'contentVersion' => contentVersion});

            if(!contentVersionDetails.isempty()){
                mapResult.put('status','success');
                mapResult.put('cdid',contentVersionDetails[0].ContentDocumentId); 
            }else{
                    mapResult.put('status','error');
            }		
        }catch(Exception ex){ 
            mapResult.put('status','error'); 
            mapResult.put('error',ex.getMessage()); 
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'CertilogoProductConfigurationController','mergeDocument');
        }
        if (mapResult.containsKey('error')) { mapResult.put('error', checkCustomErrorMessages(String.valueOf(mapResult.get('error')))); }
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Class:       ButtonWrapper
    @ Purpose:     Wrapper class for Button
    *********************************************************************************************************************************/
    class ButtonWrapper {

        @AuraEnabled 
        public CertilogoButtonConfiguration__mdt metadata {get; set;}

        public ButtonWrapper(CertilogoButtonConfiguration__mdt metadata) {
            this.metadata = metadata;
        }
    }
    
    /*********************************************************************************************************************************
    @ Class:       ProductsConfigurationWrapper
    @ Purpose:     Wrapper class for Product Configuration
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 04.11.2024 / Sambath Seng / US-0016089 - Certilogo - updates to Product Configurator - post Sprint 113
    @               : 18.04.2025 / SRONG TIN / US-0017105 - Certilogo - Allow Deliver To to be entered for Freight
    *********************************************************************************************************************************/
    class ProductsConfigurationWrapper {

        @AuraEnabled
        public OpportunityLineItem oli {get; set;}

        @AuraEnabled
        public Product2 prod {get; set;}
        
        @AuraEnabled
        public String productCode {get; set;}

        @AuraEnabled
        public String deliverTo {get; set;}

        @AuraEnabled
        public String manufacurer {get; set;}

        @AuraEnabled
        public Boolean hasManufacturer {get; set;}

        @AuraEnabled
        public Boolean isProdFamilyFreight {get; set;} //SRONG 18.04.2025 - US-0017105

        @AuraEnabled
        public Boolean showFrequency {get; set;}

        @AuraEnabled
        public Integer index {get; set;}

        @AuraEnabled
        public String prodUrl {get; set;}

        @AuraEnabled
        public Id pbeId {get; set;}

        @AuraEnabled
        public String currencyCode {get; set;}

        @AuraEnabled
        public Boolean isNew {get; set;}

        @AuraEnabled
        public Boolean selected {get; set;}

        @AuraEnabled
        public Boolean hasAnyActiveOppProdDocument {get; set;}

        @AuraEnabled
        public Boolean isDiscount {get; set;} //MN-21112024-US-0016253

        @AuraEnabled
        public List<RowButtonWrapper> listRowButton = new List<RowButtonWrapper>();

        ProductsConfigurationWrapper (OpportunityLineItem oli, Product2 prod, String opportunityId, String pricebookId) {
            this.selected = false;

            this.isNew = oli == null;

            // Sambath 04.11.2024 US-0016089 Add Quantity = 1 for new Oli and UnitPrice
            OpportunityLineItem tmpOLI = (this.isNew)?new OpportunityLineItem(OpportunityId = opportunityId, Product2Id = prod.Id, PricebookEntryId = pricebookId, TotalPrice = prod.PricebookEntries.get(0).UnitPrice, Quantity = 1, UnitPrice = prod.PricebookEntries.get(0).UnitPrice):oli;
            this.oli = tmpOLI;

            Product2 tmpProd = (this.isNew)?prod:(Product2) oli.Product2;
            this.prod = tmpProd;

            this.productCode = this.prod.ProductCode;
            //SRONG 18.04.2025 - US-0017105 - Certilogo - Allow Deliver To to be entered for Freight
            this.isProdFamilyFreight = (this.prod.Family != null) && (this.prod.Family.equals(PRODUCTFAMILY_FREIGHT));
            this.hasManufacturer = (this.prod.Manufacturer__c != null);
            
            this.manufacurer = (this.hasManufacturer)? this.prod.Manufacturer__r.Name : '';

            this.deliverTo = String.isNotBlank(this.oli.DeliveryTo__c)?this.oli.DeliveryTo__r.Name : '';

            this.showFrequency = String.isNotBlank(this.prod.Family) && this.prod.Family.equals(PRODUCTFAMILY_SAAS);
            this.oli.Frequency__c = (this.showFrequency && String.isBlank(this.oli.Frequency__c))?DEF_FREQUENCY:this.oli.Frequency__c;
            this.oli.InvoiceStatus__c = (String.isBlank(this.oli.InvoiceStatus__c))?'Draft':this.oli.InvoiceStatus__c;
            this.oli.Description = (String.isBlank(this.oli.Description))?this.prod.Description:this.oli.Description;
            this.pbeId = (this.isNew)?pricebookId:oli.PricebookEntryId;

            this.prodUrl = '/' + ((this.isNew)?pricebookId:oli.Id);

            //MN-06112024-US-0016092-For discount Product, we need to display it as POSITIVE value on screen only. But in the record it will be NEGATIVE value.
            this.isDiscount = (this.isNew)?prod.IsDiscount__c:oli.Product2.IsDiscount__c; //MN-21112024-US-0016253: added "this."
            if (this.isDiscount) { //MN-21112024-US-0016253: added "this."
                this.oli.UnitPrice = Math.abs(this.oli.UnitPrice); 
                this.oli.TotalPrice = Math.abs(this.oli.TotalPrice);
            } 

        }


    }

    /*********************************************************************************************************************************
    @ Class:       RowButtonWrapper
    @ Purpose:     Wrapper class for Row Button
    *********************************************************************************************************************************/
    class RowButtonWrapper {
        @AuraEnabled
        public String buttonName {get; set;}
        
        @AuraEnabled
        public Boolean isSplitLine {get; set;} //MN-06032025-US-0016869

        @AuraEnabled
        public OpportunityLineItem oli {get;set;} //MN-06032025-US-0016869

        @AuraEnabled
        public String fileId {get; set;}
        
        public RowButtonWrapper(String buttonName, String fileId){
            this.buttonName = buttonName;
            this.fileId = fileId;
            this.isSplitLine = false; //MN-06032025-US-0016869
        }
    }

    /*********************************************************************************************************************************
    @ Class:       OpportunityLineItemWrapper
    @ Purpose:     Wrapper class for OpportunityLineItem
    *********************************************************************************************************************************/
    class OpportunityLineItemWrapper {
        Set<Id> opportunityLineItemIds = new Set<Id>();

        Map<String, String> mapOpportunityProductDocumentWithFileId = new Map<String, String>();

        Set<Id> sEligibleSplitOLI = new Set<Id>(); //MN-06032025-US-0016869

        OpportunityLineItemWrapper(){}
    }

}