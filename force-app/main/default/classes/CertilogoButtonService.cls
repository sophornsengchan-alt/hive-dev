/*********************************************************************************************************************************
@ Class:          CertilogoButtonService
@ Version:        1.0
@ Author:         Mony Nou (mony.nout@gaea-sys.com)
@ Purpose:        This class is used to handle below functionalities of each buttons on Product Configuration Screen
                    - Get button visibility
                    - Validation
                    - Submit Action
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.10.2024 / Mony Nou / US-0015948 - create the class       
@                 21.10.2024 / Mony Nou / US-0015957 - Add Submit Action for all Buttons    
@                 09.11.2024 / Mony Nou / US-0016092 - Certilogo - Approval Process for Pricing Variations
@				  12.11.2024 / Veenus Gollapalli / US-0015966 - Certilogo - Docgen - 4 docs to be generated
@				  21.11.2024 / Mony Nou / US-0016253 - Certilogo - updates to Product Configurator
@                 22.11.2024 / Mony Nou / US-0016281 - Certilogo - general usability updates after initial testing
@                 02.01.2025 / Mony Nou / US-0016398 - Certilogo - UAT saving records from product configurator feedback
@                 16.01.2025 / Mony Nou / US-0016584 - Certilogo - not press Generate Proforma if no Confirmation Order
@                 07.03.2025 / Mony Nou / US-0016869 - Certilogo - P1 - Split Lines for Shipping
@                 10.03.2025 / Mony Nou / US-0016856 - Certilogo - Cannot Add Shipping Details when Approved
@                 01.04.2025 / Sambath Seng / US-0016927 - Certilogo - show existing documents on split lines.
*********************************************************************************************************************************/
public with sharing class CertilogoButtonService {
    
    private static final string STATUS_ACTIVE = 'Active';
    private static final string RT_PURCHASEORDER = 'PurchaseOrder';
    private static final string RT_SHIPPINGDOC = 'ShippingDocument';
    private static final string RT_PROFORMAINV = 'ProFormaInvoice';
    private static final string RT_CONFIRMORDER = 'ConfirmationOrder';
    private static final string RT_CERTILOGO = 'Certilogo';
    private static final string ENTITY_0140 = '0140';
    private static final string ENTITY_0146 = '0146';
    private static final string INVOICE_STATUS_READY = 'Ready for Invoice';
    private static final string INVOICE_STATUS_DRAFT = 'Draft';
    private static final string STR_DDT = 'DDT'; //MN-02012025-US-0016398
    private static final string STR_PROFORMA = 'Proforma'; //MN-02012025-US-0016398
    private static final string STR_DEL = 'del:'; //MN-02012025-US-0016398
    
    /*********************************************************************************************************************************
    @ Class:       GeneratePO
    @ Purpose:     This class is used to handle Generate PO button functionalities
    *********************************************************************************************************************************/
    public class GeneratePO extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){

            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String opportunityId = (String) mapParams.get('opportunityId'); //MN-21112024-US-0016253
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds, 'opportunityId' => opportunityId}); //MN-21112024-US-0016253: added oppId in the parameter});
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){ 

            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            OpportunityProductDocument__c oppProdDoc = (OpportunityProductDocument__c) mapParams.get('oppProdDoc');
            
            try {
                //MN-02012025-US-0016398: Added Product2.Manufacturer__c to below query
                String query = 'SELECT Id, DeliveryTo__c, Opportunity.AccountId, Opportunity.Account.Entity__c, Product2.Manufacturer__c,Product2.Manufacturer__r.CurrencyISOCode FROM OpportunityLineItem WHERE Id in:oppLineIds';
                List<OpportunityLineItem> oppLineItems = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppLineIds' => oppLineIds});

                //Set Opportunity Product Document Generic fields for all buttons        
                setOpportunityProductDocument(oppProdDoc, oppLineItems[0], RT_PURCHASEORDER);

                //Set Opportunity Product Document specific fields for PO
                Boolean isINC = oppLineItems[0].Opportunity.Account.Entity__c == ENTITY_0140; //MN-02012025-US-0016398: Check if Entity on account is 0140 - Certilogo INC => Enity Account = 0146 (Certilogo SPA)
                Id entityAccount = getEntityAccount(isINC, oppLineItems[0].Opportunity.Account.Entity__c); //MN-02012025-US-0016398: Added this line
                if (entityAccount != null) { oppProdDoc.Entity_Account__c = entityAccount; }

                //MN-02012025-US-0016398: Set Receiver Account to be Manufacturer
                Id manufacturer = oppLineItems[0].Product2.Manufacturer__c;
                if (manufacturer != null) { 
                    oppProdDoc.ReceiverAccount__c = manufacturer; 
                    oppProdDoc.CurrencyISOCode = oppLineItems[0].Product2.Manufacturer__r.CurrencyISOCode; //US0016649
                
                }

                //Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doInsert(new List<SObject>{oppProdDoc}, true); 
                //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                Database.SaveResult[] result = WithoutSharing.doInsert(new List<SObject>{oppProdDoc}, true);
                if (result[0].isSuccess()) {

                    Id oppProdDocId = result[0].getId();
                    mapResult.put('opdId',oppProdDocId);
					mapResult.put('opdIdtype',RT_PURCHASEORDER); //US-0015966
                    List<OpportunityProductDocumentLine__c> lstOppProdDocLine = generateOpportunityProductDocumentLine(oppLineItems, oppProdDocId,true);

                    //Create Opportunity Product Document Line
                    //ApexSafe.dml().secCheck(false).doInsert(lstOppProdDocLine, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document Line, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                    WithoutSharing.doInsert(lstOppProdDocLine, true);
                    mapResult.put('status','success'); 
                    
                } else {
                    mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                }

            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************
    @ Class:       GenerateShippingDoc
    @ Purpose:     This class is used to handle Generate Shipping Doc button functionalities
    *********************************************************************************************************************************/
    public class GenerateShippingDoc extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String opportunityId = (String) mapParams.get('opportunityId'); //MN-21112024-US-0016253
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds, 'opportunityId' => opportunityId}); //MN-21112024-US-0016253: added oppId in the parameter});});
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){

            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            OpportunityProductDocument__c oppProdDoc = (OpportunityProductDocument__c) mapParams.get('oppProdDoc');
            
            String query = 'SELECT Id, DeliveryTo__c, Opportunity.AccountId, Opportunity.Account.Entity__c,Opportunity.CurrencyISOCode FROM OpportunityLineItem WHERE Id in:oppLineIds';
            
            try {

                List<OpportunityLineItem> oppLineItems = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppLineIds' => oppLineIds});

                //Set Opportunity Product Document Generic fields for all buttons    
                setOpportunityProductDocument(oppProdDoc, oppLineItems[0], RT_SHIPPINGDOC);

                //Set Opportunity Product Document specific fields for Shipping Doc
                oppProdDoc.DDTYear__c = String.valueOf(Date.today().year());
                oppProdDoc.DDTNumber__c = getDDTNumber(oppProdDoc.Opportunity__c, oppProdDoc.DDTYear__c);
                oppProdDoc.CurrencyISOCode = oppLineItems[0].Opportunity.CurrencyISOCode; //US0016649

                Id entityAccount = getEntityAccount(false, oppLineItems[0].Opportunity.Account.Entity__c);
                if (entityAccount != null) { oppProdDoc.Entity_Account__c = entityAccount; }
                
                
                OpportunityLineItemTriggerHandler.isUnlockProduct = true; //MN-10032025-US-0016856

                //Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doInsert(new List<SObject>{oppProdDoc}, true); 
                //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                Database.SaveResult[] result = WithoutSharing.doInsert(new List<SObject>{oppProdDoc}, true);

                if (result[0].isSuccess()) {

                    Id oppProdDocId = result[0].getId();
                    mapResult.put('opdId',oppProdDocId);
                    mapResult.put('opdIdtype',RT_SHIPPINGDOC);//US-0015966

                    List<OpportunityProductDocumentLine__c> lstOppProdDocLine = generateOpportunityProductDocumentLine(oppLineItems, oppProdDocId,false);

                    //Create Opportunity Product Document Line
                    //ApexSafe.dml().secCheck(false).doInsert(lstOppProdDocLine, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document Line, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                    result = WithoutSharing.doInsert(lstOppProdDocLine, true); //MN-02012025-US-0016398: Use result variable to return the result of insert

                    //MN-02012025-US-0016398: If successful, update the Opportunity Line Item -- START
                    if (result[0].isSuccess()) {

                        String shipDateStr = '';
                        if (oppProdDoc.ShippingDate__c != null) {
                            DateTime dt = DateTime.newInstance(oppProdDoc.ShippingDate__c.year(), oppProdDoc.ShippingDate__c.month(),oppProdDoc.ShippingDate__c.day());
                            shipDateStr = dt.format('dd/MM/yyy');
                        }

                        String billingInfor = STR_DDT + ' ' + oppProdDoc.DDTNumber__c + ' ' + STR_DEL + ' ' + shipDateStr;

                        List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();

                        for (OpportunityLineItem oli : oppLineItems) {
                            lstOppLineItems.add(new OpportunityLineItem(Id = oli.Id, Additional_Billing_Information_1__c = billingInfor));
                        }

                        WithoutSharing.doUpdate(lstOppLineItems, true);

                        mapResult.put('status','success');
                    } else {
                        mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                    }
                    //-- END

                    //mapResult.put('status','success'); //MN-02012025-US-0016398: Commented this line
                    
                } else {
                    mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                }

            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }

        private Integer getDDTNumber(Id opportunityId, String currentYear){
            String query = 'SELECT MAX(DDTNumber__c) max FROM OpportunityProductDocument__c WHERE DDTYear__c =:currentYear AND RecordType.DeveloperName=:RT_SHIPPINGDOC';
            List<AggregateResult> aggRes = ApexSafe.query().doQuery(query, new Map<String,Object>{'currentYear' => currentYear, 'RT_SHIPPINGDOC' => RT_SHIPPINGDOC});
            Integer maxnum = (aggRes[0].get('max') != null)?Integer.valueOf(String.valueOf(aggRes[0].get('max'))):0;
            return maxnum + 1; //Need to wait BA clarify this point, for now set it to 1
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       GenerateProFormaDoc
    @ Purpose:     This class is used to handle Generate Pro Forma Doc button functionalities
    *********************************************************************************************************************************/
    public class GenerateProFormaDoc extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String opportunityId = (String) mapParams.get('opportunityId'); //MN-16012025-US-0016584
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds, 'opportunityId' => opportunityId}); //MN-16012025-US-0016584: added oppId in the parameter
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){

            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            OpportunityProductDocument__c oppProdDoc = (OpportunityProductDocument__c) mapParams.get('oppProdDoc');
            
            try {
                
                String query = 'SELECT Id, DeliveryTo__c, Opportunity.AccountId, Opportunity.Account.Entity__c,Opportunity.CurrencyISOCode FROM OpportunityLineItem WHERE Id in:oppLineIds';
                List<OpportunityLineItem> oppLineItems = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppLineIds' => oppLineIds});

                //Set Opportunity Product Document Generic fields for all buttons        
                setOpportunityProductDocument(oppProdDoc, oppLineItems[0], RT_PROFORMAINV);

                //Set Opportunity Product Document specific fields for Pro Forma Invoice

                //Check if Entity on account is 0140 - Certilogo INC
                Boolean isProformaINC = oppLineItems[0].Opportunity.Account.Entity__c == ENTITY_0140;

                if (isProformaINC) { //Set Set Receiver Account to be Certilogo Inc - Certilogo Account where Entity_Account = TRUE and Entity_c = 0140 (Inc)
                    Id receiverAcc = getEntityAccount(false, ENTITY_0140);
                    if (receiverAcc != null) { oppProdDoc.ReceiverAccount__c = receiverAcc; }
                }

                Id entityAccount = getEntityAccount(isProformaINC, oppLineItems[0].Opportunity.Account.Entity__c);
                if (entityAccount != null) { oppProdDoc.Entity_Account__c = entityAccount; }
                oppProdDoc.CurrencyISOCode = oppLineItems[0].Opportunity.CurrencyISOCode; //US0016649

                OpportunityLineItemTriggerHandler.isUnlockProduct = true; //MN-10032025-US-0016856

                //Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doInsert(new List<SObject>{oppProdDoc}, true); 
                //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                Database.SaveResult[] result = WithoutSharing.doInsert(new List<SObject>{oppProdDoc}, true);

                if (result[0].isSuccess()) {

                    Id oppProdDocId = result[0].getId();
                    mapResult.put('opdId',oppProdDocId);
					mapResult.put('opdIdtype',RT_PROFORMAINV);//US-0015966
                    List<OpportunityProductDocumentLine__c> lstOppProdDocLine = generateOpportunityProductDocumentLine(oppLineItems, oppProdDocId,false);

                    //Create Opportunity Product Document Line
                    //ApexSafe.dml().secCheck(false).doInsert(lstOppProdDocLine, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document Line, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                    result = WithoutSharing.doInsert(lstOppProdDocLine, true); //MN-02012025-US-0016398: Use result variable to return the result of insert

                    //MN-02012025-US-0016398: If successful, update the Opportunity Line Item -- START
                    if (result[0].isSuccess()) {

                        String shipDateStr = '';
                        if (oppProdDoc.ShippingDate__c != null) {
                            DateTime dt = DateTime.newInstance(oppProdDoc.ShippingDate__c.year(), oppProdDoc.ShippingDate__c.month(),oppProdDoc.ShippingDate__c.day());
                            shipDateStr = dt.format('dd/MM/yyy');
                        }

                        query = 'SELECT Name FROM OpportunityProductDocument__c WHERE Id =:oppProdDocId';
                        List<OpportunityProductDocument__c> opd = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppProdDocId' => oppProdDocId});

                        String billingInfor = STR_PROFORMA + ' ' + opd[0].Name + ' ' + STR_DEL + ' ' + shipDateStr;

                        List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();

                        for (OpportunityLineItem oli : oppLineItems) {
                            lstOppLineItems.add(new OpportunityLineItem(Id = oli.Id, Additional_Billing_Information_1__c = billingInfor));
                        }

                        WithoutSharing.doUpdate(lstOppLineItems, true);

                        mapResult.put('status','success');
                    } else {
                        mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                    }
                    //-- END

                    // mapResult.put('status','success'); //MN-02012025-US-0016398 - Commented this line
                    
                } else {
                    mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                }

            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       GenerateOrderConfirmation
    @ Purpose:     This class is used to handle Generate Order Confirmation button functionalities
    *********************************************************************************************************************************/
    public class GenerateOrderConfirmation extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds});
            return evaluateResult(criteria, count, totalRecord);
        }
		 
        public Map<String, Object> submitAction(Map<String, Object> mapParams){

            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            OpportunityProductDocument__c oppProdDoc = (OpportunityProductDocument__c) mapParams.get('oppProdDoc');
            
            try {
                
                String query = 'SELECT Id, DeliveryTo__c, Opportunity.AccountId, Opportunity.Account.Entity__c,Opportunity.CurrencyISOCode FROM OpportunityLineItem WHERE Id in:oppLineIds';
                List<OpportunityLineItem> oppLineItems = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppLineIds' => oppLineIds});

                //Set Opportunity Product Document Generic fields for all buttons        
                setOpportunityProductDocument(oppProdDoc, oppLineItems[0], RT_CONFIRMORDER);

                //Set Opportunity Product Document specific fields for Order Confirmation
                oppProdDoc.DestinationAccount__c = oppLineItems[0].Opportunity.AccountId;
                oppProdDoc.CurrencyISOCode = oppLineItems[0].Opportunity.CurrencyISOCode; //US0016649

                Id entityAccount = getEntityAccount(false, oppLineItems[0].Opportunity.Account.Entity__c);
                if (entityAccount != null) { oppProdDoc.Entity_Account__c = entityAccount; }
                
                //Database.SaveResult[] result = ApexSafe.dml().secCheck(false).doInsert(new List<SObject>{oppProdDoc}, true); 
                //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                Database.SaveResult[] result = WithoutSharing.doInsert(new List<SObject>{oppProdDoc}, true); 

                if (result[0].isSuccess()) {

                    Id oppProdDocId = result[0].getId();
                    mapResult.put('opdId',oppProdDocId);
                    mapResult.put('opdIdtype',RT_CONFIRMORDER);//US-0015966

                    List<OpportunityProductDocumentLine__c> lstOppProdDocLine = generateOpportunityProductDocumentLine(oppLineItems, oppProdDocId,false);

                    //Create Opportunity Product Document Line
                    //ApexSafe.dml().secCheck(false).doInsert(lstOppProdDocLine, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to create Opportunity Product Document Line, we need to use WithoutSharing.doInsert to avoid Lock Record Error
                    WithoutSharing.doInsert(lstOppProdDocLine, true);
                    
                    //mergeDocument(oppProdDocId,RT_CONFIRMORDER);

                    mapResult.put('status','success');
                    
                } else {
                    mapResult.put('status','error'); mapResult.put('message',result[0].getErrors()[0].getMessage());
                }

            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }
    
    
    /*********************************************************************************************************************************  
    @ Class:       MarkasReadyforInvoice
    @ Purpose:     This class is used to handle Mark as Ready for Invoice button functionalities
    *********************************************************************************************************************************/
    public class MarkasReadyforInvoice extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String opportunityId = (String) mapParams.get('opportunityId'); //MN-21112024-US-0016253
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds,  'opportunityId' => opportunityId}); //MN-21112024-US-0016253: added oppId in the parameter
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){
            
            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            
            try {
                
                    List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();
                    Datetime dtNow = Datetime.now(); 
                    for (String oliId : oppLineIds) {
                        
                        lstOppLineItems.add(new OpportunityLineItem(Id = oliId, InvoiceStatus__c = INVOICE_STATUS_READY, ReadytoInvoiceTimestamp__c = dtNow));
                    }

                    //Update Opportunity Line Item
                    //ApexSafe.dml().secCheck(false).doUpdate(lstOppLineItems, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to update Opportunity Product, we need to use WithoutSharing.doUpdate to avoid Lock Record Error
                    WithoutSharing.doUpdate(lstOppLineItems, true);

                    mapResult.put('status','success');
                
            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       UndoReadyforInvoice
    @ Purpose:     This class is used to handle Undo Ready for Invoice button functionalities
    *********************************************************************************************************************************/
    public class UndoReadyforInvoice extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return getVisibility(mapParams);
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds});
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){
            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            
            try {
                
                    List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();

                    for (String oliId : oppLineIds) {
                        lstOppLineItems.add(new OpportunityLineItem(Id = oliId, InvoiceStatus__c = INVOICE_STATUS_DRAFT, ReadytoInvoiceTimestamp__c = null));
                    }

                    //Update Opportunity Line Item
                    //ApexSafe.dml().secCheck(false).doUpdate(lstOppLineItems, true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to update Opportunity Product, we need to use WithoutSharing.doUpdate to avoid Lock Record Error
                    WithoutSharing.doUpdate(lstOppLineItems, true);

                    mapResult.put('status','success');
                
            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       DeleteButton
    @ Purpose:     This class is used to handle Delete button functionalities
    *********************************************************************************************************************************/
    public class DeleteButton extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return true;
        }

        public Boolean validate(Map<String,Object> mapParams){
            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            String  vQuery = (String) mapParams.get('validationQuery');
            Integer totalRecord = oppLineIds.size();
            String  criteria = (String) mapParams.get('evalCriteria');
            Integer count = getRecordCount(vQuery, new Map<String,Object>{'oppLineIds' => oppLineIds});
            return evaluateResult(criteria, count, totalRecord);
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){
            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            
            try {
                
                    List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();

                    for (String oliId : oppLineIds) { lstOppLineItems.add(new OpportunityLineItem(Id = oliId)); }

                    //Delete Opportunity Line Item
                    //ApexSafe.dml().secCheck(false).doDelete(lstOppLineItems,true);
                    //MN-09112024-US-0016092: Once Opportunity is approved via Approval Process, record will be locked and to allow user to delete Opportunity Product, we need to use WithoutSharing.doDelete to avoid Lock Record Error
                    OpportunityLineItemTriggerHandler.isDeleteViaProductConfiguration = true; //MN-22112024-US-0016281: Only allow to delete from Product Configuration Screen
                    WithoutSharing.doDelete(lstOppLineItems,true);

                    mapResult.put('status','success');
                
            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       SplitLineButton
    @ Purpose:     This class is used to handle Split Lines functionalities
    @ History:     01.04.2025 / Sambath Seng / US-0016927 - Certilogo - show existing documents on split lines.
    *********************************************************************************************************************************/
    public class SplitLineButton extends CertilogoButton implements ICertilogoButton{
        
        public Boolean getButtonVisibility(Map<String,Object> mapParams){
            return true;
        }

        public Boolean validate(Map<String,Object> mapParams){
            return true;
        }

        public Map<String, Object> submitAction(Map<String, Object> mapParams){
            Map<String, Object> mapResult = new Map<String, Object>();

            List<String> oppLineIds = (List<String>) mapParams.get('oppLineIds');
            Map<String, Object> mAdditionalParams = (Map<String, Object>) mapParams.get('additionalParams');
            
            try {
                    String query = 'SELECT Id, Quantity, UnitPrice, InvoiceStatus__c, Description, DeliveryTo__c, Frequency__c, PricebookEntryId, Product2Id, OpportunityId, (SELECT Id, OpportunityProduct__c, OpportunityProductDocument__c FROM OpportunityProductDocument__r) FROM OpportunityLineItem WHERE Id IN:oppLineIds';
                    List<OpportunityLineItem> lstOppLineItems = new List<OpportunityLineItem>();
                    List<OpportunityLineItem> lstOppLineItems2Upsert = new List<OpportunityLineItem>();
                    List<OpportunityProductDocumentLine__c> lstClonedDocLines = new List<OpportunityProductDocumentLine__c>();
                    Map<Id, List<OpportunityProductDocumentLine__c>> docLinesToCloneMap = new Map<Id, List<OpportunityProductDocumentLine__c>>(); // 01.04.2025 Sambath Seng US-0016927 Map to store document lines for cloning
                    Map<Id, Id> originalToClonedLineItemMap = new Map<Id, Id>(); // 1.04.2025 Sambath Seng US-0016927 Map to track original to cloned OpportunityLineItem IDs
                    lstOppLineItems = ApexSafe.query().secCheck(false).doQuery(query, new Map<String,Object>{'oppLineIds' => oppLineIds});
                    
                    Map<OpportunityLineItem, List<OpportunityProductDocumentLine__c>> mapOLItoOPDL = new Map<OpportunityLineItem, List<OpportunityProductDocumentLine__c>>();

                    for (OpportunityLineItem oli : lstOppLineItems) {
                        OpportunityLineItem cloneOLI = oli.clone(false, false, false, false);

                        cloneOLI.Quantity = Decimal.valueOf(String.valueOf(mAdditionalParams.get('splitqty')));

                        lstOppLineItems2Upsert.add(cloneOLI);

                        oli.Quantity = oli.Quantity - cloneOLI.Quantity;
                        lstOppLineItems2Upsert.add(oli);

                        // 01.04.2025 Sambath Seng US-0016927 Prepare related document lines for cloning
                        if (!oli.OpportunityProductDocument__r.isEmpty()) {
                            docLinesToCloneMap.put(oli.Id, oli.OpportunityProductDocument__r);
                        }
                    }
                    
                OpportunityLineItemTriggerHandler.isUnlockProduct = true; //MN-10032025-US-0016856
                
                //Once Opportunity is approved via Approval Process, record will be locked and  we need to use WithoutSharing.doUpsert to avoid Lock Record Error
                WithoutSharing.doUpsert(lstOppLineItems2Upsert);

                // 01.04.2025 Sambath Seng US-0016927 map original OpportunityLineItem Id to cloned OpportunityLineItem Id
                for (Integer i = 0; i < lstOppLineItems.size(); i++) {
                    originalToClonedLineItemMap.put(lstOppLineItems[i].Id, lstOppLineItems2Upsert[i].Id);
                }

                // 01.04.2025 Sambath Seng US-0016927 Clone OpportunityProductDocumentLine__c records and link to cloned OpportunityLineItems
                for (Id originalLineItemId : docLinesToCloneMap.keySet()) {
                    List<OpportunityProductDocumentLine__c> relatedDocLines = docLinesToCloneMap.get(originalLineItemId);

                    for (OpportunityProductDocumentLine__c docLine : relatedDocLines) {
                        OpportunityProductDocumentLine__c clonedDocLine = docLine.clone(false, false, false, false);
                        clonedDocLine.OpportunityProduct__c = originalToClonedLineItemMap.get(originalLineItemId);
                        lstClonedDocLines.add(clonedDocLine);
                    }
                }

                // 01.04.2025 Sambath Seng US-0016927 Insert cloned OpportunityProductDocumentLine__c records
                WithoutSharing.doInsert(lstClonedDocLines);

                mapResult.put('status','success');
                
                
            } catch(Exception ex){ throw ex; } //Throw exception to the outer try-catch block in Controller class

            return mapResult;
        }
    }

    /*********************************************************************************************************************************  
    @ Class:       CertilogoButton
    @ Purpose:     This class is used to handle common functionalities of each buttons
    *********************************************************************************************************************************/
    public virtual class CertilogoButton {
        
        /*********************************************************************************************************************************
        @ Method:       evaluateResult
        @ Parameters:   criteria - String, queryRecord - Integer, selectedRecord - Integer
        @ Purpose:      This method is used to evaluate the result based on the criteria
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history: 21.11.2024 / Mony Nou / US-0016253: correct 'One or More' criteria
        *********************************************************************************************************************************/
        public Boolean evaluateResult(String criteria, Integer queryRecord, Integer selectedRecord) {

            Boolean result;
        
            switch on criteria {
                
                when 'One or More' { //Pass validation if query record is more than 1
                    result = queryRecord >= 1 ; //MN-21112024-US-0016253: updated to ">=" from ">"
                }
                when 'One' { //Pass validation if query record is 1
                    result = queryRecord == 1 ;
                }
                when 'None' { //Pass validation if query record is 0
                    result = queryRecord == 0;
                }
                when else { //Pass validation if query record is equal to selected record
                    result = queryRecord == selectedRecord;
                }
            }
            
            return result;

        }

        /*********************************************************************************************************************************
        @ Method:       getRecordCount
        @ Parameters:   query - String, mapParams - Map<String,Object>
        @ Purpose:      This method is used to get the record count based on the query
        *********************************************************************************************************************************/
        public Integer getRecordCount(String query, Map<String,Object> mapParams){
            Integer count = 0;
            try {
                count = ApexSafe.query().doCount(query, mapParams);
            }catch(QueryException qex) { //If Validate Query is not COUNT query then using non-count query
                count = (ApexSafe.query().doQuery(query, mapParams)).size();    
            }
            return count;
        }

        /*********************************************************************************************************************************
        @ Method:       getVisibility
        @ Parameters:   mapParams - Map<String,Object>
        @ Purpose:      This method is used to get the visibility of the button
        *********************************************************************************************************************************/
        public Boolean getVisibility(Map<String,Object> mapParams){
            String opportunityId = (String) mapParams.get('opportunityId');
            String cQuery = (String) mapParams.get('buttonVisibilityQuery');
            Integer count = String.isBlank(cQuery)?1:getRecordCount(cQuery, new Map<String,Object>{'opportunityId' => opportunityId});
            return count > 0; //Button will be visible if the count is more than 0
        }

        /*********************************************************************************************************************************
        @ Method:       getEntityAccount
        @ Parameters:   isProformaINC - Boolean, oppAccountEntity - String
        @ Purpose:      This method is used to get the Entity Account based on the Entity__c field
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history: 21.10.2024 / Mony Nou / US-0015957 - create the method
        *********************************************************************************************************************************/
        public Id getEntityAccount(Boolean isProformaINC, String oppAccountEntity) {

            RecordType recType = ApexUtil.getRecordTypeByName('Account', RT_CERTILOGO);

            Id rtCertilogo = recType.Id;
            String entity = (isProformaINC)?ENTITY_0146:oppAccountEntity;

            String query = 'SELECT Id FROM Account WHERE RecordTypeId=:rtCertilogo AND Entity_Account__c = TRUE AND Entity__c=:entity LIMIT 1';
            List<Account> result = ApexSafe.query().doQuery(query, new Map<String,Object>{'rtCertilogo' => rtCertilogo, 'entity' => entity});
            return (result.size() > 0)?result.get(0).Id:null;

        }

        /*********************************************************************************************************************************
        @ Method:       setOpportunityProductDocument
        @ Parameters:   oppProdDoc - OpportunityProductDocument__c, oli - OpportunityLineItem
        @ Purpose:      This method is used to set the OpportunityProductDocument__c fields
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history: 21.10.2024 / Mony Nou / US-0015957 - create the method
        *********************************************************************************************************************************/
        public void setOpportunityProductDocument(OpportunityProductDocument__c oppProdDoc, OpportunityLineItem oli, String recordType){

            RecordType recType = ApexUtil.getRecordTypeByName('OpportunityProductDocument__c', recordType);

            oppProdDoc.ReceiverAccount__c = oli.Opportunity.AccountId;
            oppProdDoc.Opportunity__c = oli.OpportunityId;
            oppProdDoc.DestinationAccount__c = (oli.DeliveryTo__c != null)?oli.DeliveryTo__c:oli.Opportunity.AccountId;
            oppProdDoc.Status__c = STATUS_ACTIVE;
            oppProdDoc.RecordTypeId = recType.Id;
        }

        /*********************************************************************************************************************************
        @ Method:       generateOpportunityProductDocumentLine
        @ Parameters:   oppLineItems - List<OpportunityLineItem>, oppProdDocId - Id
        @ Purpose:      This method is used to generate List of OpportunityProductDocumentLine__c records
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history: 21.10.2024 / Mony Nou / US-0015957 - create the method
        *********************************************************************************************************************************/
        public List<OpportunityProductDocumentLine__c> generateOpportunityProductDocumentLine(List<OpportunityLineItem> oppLineItems, Id oppProdDocId,boolean isPOButton){
            
            List<OpportunityProductDocumentLine__c> tmpList = new List<OpportunityProductDocumentLine__c>();

            for (OpportunityLineItem oli : oppLineItems) {
                OpportunityProductDocumentLine__c newOpdl = new OpportunityProductDocumentLine__c();
                newOpdl.OpportunityProductDocument__c = oppProdDocId;
                newOpdl.OpportunityProduct__c = oli.Id;
                if(!isPOButton){
                    newOpdl.CurrencyISOCode = oli.Opportunity.CurrencyIsoCode;
                }else if(oli.Product2.Manufacturer__c != NULL && isPOButton){
                    newOpdl.CurrencyISOCode = oli.Product2?.Manufacturer__r?.CurrencyISOCode;
                }
                tmpList.add(newOpdl); //US0016649
                
                //tmpList.add(new OpportunityProductDocumentLine__c(OpportunityProductDocument__c = oppProdDocId, OpportunityProduct__c = oli.Id,CurrencyISOCode = oli.Product2?.Manufacturer__r?.CurrencyISOCode));
            }

            return tmpList;
        }
        
 

    }
   
    
    /*********************************************************************************************************************************  
    @ interface:    ICertilogoButton
    @ Purpose:      This interface is used to define the common methods for each button classes
    *********************************************************************************************************************************/
    public interface ICertilogoButton{

        //Method to get button visibility
        Boolean getButtonVisibility(Map<String,Object> mapParams);

        //Method to validate the button
        Boolean validate(Map<String,Object> mapParams);

        //Method to submit the action
        Map<String, Object> submitAction(Map<String, Object> mapParams); //MN-21102024-US-0015957
    }


}