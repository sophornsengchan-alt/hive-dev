/*********************************************************************************************************************************
@ Class:          BatchGetProposalLineItem
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test class for getting propsoal lineitem and order from GAM to populate on sf records
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2021 / Sophal Noch / Created Class. US-0009927 - Update PG Opportunity Flow 
*********************************************************************************************************************************/
global with sharing class BatchGetProposalLineItem implements Database.Batchable<SObject>, Database.AllowsCallouts, Schedulable, Database.Stateful{

    private String oppPgRtId = ApexUtil.getRecordTypeByName('Opportunity','Programmatic').Id;

    private String adProdQuery  = 'Select Id, Name, FromDateUntilDate_Days__c, Opportunity__r.Buyer_Accepted__c, Proposal_Lineitem_Id__c, Opportunity__c, Opportunity__r.Order_Id__c,Opportunity__r.Proposal_Id__c, Product2__r.RecordType.Name, Product2__r.RecordType.DeveloperName, Product2__r.Site__r.Name From Ad_Product__c Where Opportunity__r.RecordTypeId =:oppPgRtId And Ad_Id__c = NULL AND Proposal_Lineitem_Id__c != NULL AND Product2__c != NULL AND Product2__r.Site__c != NULL';
    private final static String ORDER_BY_QUERY = ' Order By Product2__r.RecordType.DeveloperName, Product2__r.Site__r.Name, Opportunity__c, Id';

    private Set<String> setOppId = new Set<String>();
    private Set<String> setAdProdId = new Set<String>();
    private Boolean isOppParam = true;
    private Set<String> setSObjectId = new Set<String>();

    private final static String PROPOSAL_LINEITEM_SERVICE_APPNAME = 'ProposalLineItemService';
    private final static String PROPOSAL_SERVICE_APPNAME = 'ProposalService';
    private final static String ORDER_SERVICE_APPNAME = 'OrderService';

    private final static String PROPOSAL_NEGO_STATUS_FINALIZED = 'FINALIZED';

    private static final Integer TIMEOUT = 120000;
    private final static String WHERE_ID_IN = 'Where id in ';

    public static final Integer BATCH_SIZE = Integer.valueOf(Label.Proposal_Lineitem_Batch_Size);
    public static Integer RG_DML_CHUNK_LIMIT = Integer.valueOf(Label.RG_DML_CHUNK_LIMIT);

    public BatchGetProposalLineItem() {
        adProdQuery += ORDER_BY_QUERY;
    }
    public BatchGetProposalLineItem(Set<String> sobjIds, Boolean isOpp) {
        if(!sobjIds.isEmpty() && isOpp){
            this.setOppId = sobjIds;
            adProdQuery += ' AND Opportunity__c IN: setOppId' + ORDER_BY_QUERY;
        }else if(!sobjIds.isEmpty() && !isOpp){
            this.setAdProdId = sobjIds;
            adProdQuery += ' AND Id IN: setAdProdId' + ORDER_BY_QUERY;
        }else{
            adProdQuery += ORDER_BY_QUERY;
        }

    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        return Database.getQueryLocator(adProdQuery);
    }
    
    global void execute(Database.BatchableContext BC, List<Ad_Product__c> scope){

        Map<String,Set<String>> mapProdKeyToSetPropLineItemIds = new Map<String,Set<String>>();
        Map<String,Ad_Product__c> mapPropLineItemToAdProd = new Map<String,Ad_Product__c>();
        Integer numberRevenueDaily = 0;
        for(Ad_Product__c adp : scope){

            if(numberRevenueDaily > RG_DML_CHUNK_LIMIT){ // limit reach, store opp id to run antoher batch
                numberRevenueDaily += Integer.valueOf(adp.FromDateUntilDate_Days__c);
                isOppParam = false;
                setSObjectId.add(adp.Id);
                continue;
            }

            // Acmatac SEING, 2 March 2022 US-0010618 - Changed from RecordType.Name to RecordType.DeveloperName
            String credentialKey = adp.Product2__r.RecordType.DeveloperName + '_' +  adp.Product2__r.Site__r.Name;
            Set<String> setPropLineItemIds = mapProdKeyToSetPropLineItemIds.get(credentialKey);

            if(setPropLineItemIds == null){
                setPropLineItemIds = new Set<String>{adp.Proposal_Lineitem_Id__c};
                mapProdKeyToSetPropLineItemIds.put(credentialKey, setPropLineItemIds);
            }else{
                setPropLineItemIds.add(adp.Proposal_Lineitem_Id__c);
            }
            mapPropLineItemToAdProd.put(adp.Proposal_Lineitem_Id__c, adp);

            numberRevenueDaily += Integer.valueOf(adp.FromDateUntilDate_Days__c);
        }


        Map<String, Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>> mapAllPropToMapLitem = new Map<String, Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>>();
        Map<String, DART6_ProposalService.Proposal> mapAllProposal = new Map<String, DART6_ProposalService.Proposal>();
        Map<String, DART6_ORDERSERVICE.Order> mapAllOrder = new Map<String, DART6_ORDERSERVICE.Order>();

        // different proposal country, different credential
        for( AdServer_Login__c login: [SELECT RecordType.name,Name,Login_URL__c, User_Name__c, Password__c, Network_ID__c, Refresh_Token__c, Client_Id__c, Client_Secret__c, Timezone__c, ExternalLineDescriptionId__c  FROM AdServer_Login__c WHERE Active__c=true AND isDeleted=false])
        {
            DARTUtil.clearAccessToken();

            String credentialKey = login.RecordType.name + '_' + login.Name;
            Set<String> setPropLineItemIds = mapProdKeyToSetPropLineItemIds.get(credentialKey);
            if(setPropLineItemIds == null) continue;
           
            String strListLineItem = prepareStrList(setPropLineItemIds);
            Map<String, Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>> mapPropToMapLitemPerAdserv = new Map<String, Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>>();
            
            // request proposal lineitem from GAM
            requestLineItems(login, strListLineItem, mapPropToMapLitemPerAdserv);
            if(mapPropToMapLitemPerAdserv.isEmpty()) continue;

            for(String proposalId : mapPropToMapLitemPerAdserv.keySet()){
                Map<String,DART6_LINEITEMSERVICE.ProposalLineItem> mapProposalItemPerAdserv = mapPropToMapLitemPerAdserv.get(proposalId);
                Map<String,DART6_LINEITEMSERVICE.ProposalLineItem> mapProposalItem = mapAllPropToMapLitem.get(proposalId);
                if(mapProposalItem != null){
                    mapProposalItem.putAll(mapProposalItemPerAdserv);
                }else{
                    mapAllPropToMapLitem.put(proposalId, mapProposalItemPerAdserv);
                }
            }
            
            
            String strListProposal = prepareStrList(mapPropToMapLitemPerAdserv.keySet());
            Map<String, DART6_ProposalService.Proposal> mapProposalPerAdserv = new Map<String, DART6_ProposalService.Proposal>();
            // request proposal from GAM
            requestProposals(login, strListProposal, mapProposalPerAdserv);
            if(mapProposalPerAdserv.isEmpty()) continue;
            mapAllProposal.putAll(mapProposalPerAdserv);
            

            String strListOrders = prepareStrList(mapProposalPerAdserv.keySet());
            Map<String, DART6_ORDERSERVICE.Order> mapOrderPerAdserv = new Map<String, DART6_ORDERSERVICE.Order>();
            // request order from GAM
            requestOrders(login, strListOrders, mapOrderPerAdserv);
            mapAllOrder.putAll(mapOrderPerAdserv);

        }
        
        if(mapAllPropToMapLitem.isEmpty()) return;
        if(mapAllProposal.isEmpty()) return;

        List<Ad_Product__c> listAdProductToUpdate = new List<Ad_Product__c>();
        Map<Id,Opportunity> mapOppToUpdate = new Map<Id,Opportunity>();
        for(DART6_ProposalService.Proposal proposal : mapAllProposal.values()){

            String proposalId = proposal.Id+'';
            // proposal need to be finalized first. 
            if(proposal.marketplaceInfo.negotiationStatus != PROPOSAL_NEGO_STATUS_FINALIZED) continue;

            Map<String, DART6_LINEITEMSERVICE.ProposalLineItem> mapProposalLineItem = mapAllPropToMapLitem.get(proposalId);
            for(DART6_LINEITEMSERVICE.ProposalLineItem lineItem : mapProposalLineItem.values()){
                
                String lineItemId = lineItem.Id+'';
                Ad_Product__c adProd = mapPropLineItemToAdProd.get(lineItemId);
                if(adProd != null){ 

                    String orderId = proposal.dfpOrderId+'';
                    String orderLineItemId = lineItem.dfpLineItemId +'';

                    adProd.Adserver_ID_Order_ID__c = orderId;
                    adProd.Ad_Id__c = orderLineItemId;
                    DART6_ORDERSERVICE.Order order = mapAllOrder.get(orderId);
                    if(order != null) adProd.Adserver_Adv_Advertiser_ID__c = order.advertiserId+'';
                    
                    listAdProductToUpdate.add(adProd);
                    if(adProd.Opportunity__r.Proposal_Id__c == proposalId && (adProd.Opportunity__r.Order_Id__c == null || adProd.Opportunity__r.Buyer_Accepted__c == false)){
                        mapOppToUpdate.put(adProd.Opportunity__c, new Opportunity(Id=adProd.Opportunity__c, Buyer_Accepted__c = true, Order_Id__c = orderId));
                    } 
                }
            }
            
        }


        if(!mapOppToUpdate.isEmpty()){
            update mapOppToUpdate.values();
        }
        if(!listAdProductToUpdate.isEmpty()){
            update listAdProductToUpdate;
        }


       
    }

    private String prepareStrList(Set<String> setValues){
        String result = '(';
        for(String val : setValues){
            result += (val + ',');
        }
        result = result.removeEnd(',');
        result += ')';
        return result;
    }

    private Map<String,String> prepareInputHttpHeadersX(AdServer_Login__c login){
        String authToken = DARTUtil.getAccessToken(login);
        Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
        inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);
        return inputHttpHeaders_x;
    }

    private void requestLineItems(AdServer_Login__c login, String strListLineItem, Map<String, Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>> mapPropToMapLitemPerAdserv){
        
        DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
        header.applicationName = PROPOSAL_LINEITEM_SERVICE_APPNAME;
        header.networkCode = login.Network_ID__c;

        DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort();
        lineItemService.RequestHeader = header;
        lineItemService.timeout_x = TIMEOUT;
        lineItemService.inputHttpHeaders_x = prepareInputHttpHeadersX(login);

        DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
        // filterItem.query = WHERE_ID_IN + strListLineItem + ' AND dfpLineItemId != NULL';
        filterItem.query = WHERE_ID_IN + strListLineItem;

        DART6_LINEITEMSERVICE.ProposalLineItemPage itemPage = lineItemService.getProposalLineItemsByStatement(filterItem);

        if (itemPage.totalResultSetSize>0) {
            for (DART6_LINEITEMSERVICE.ProposalLineItem itemRes: itemPage.results) {
                if(itemRes.dfpLineItemId != null){
                    String proposalLineItemId = itemRes.id+'';
                    String proposalId = itemRes.proposalId+'';
                    Map<String, DART6_LINEITEMSERVICE.ProposalLineItem> mapPropLine = mapPropToMapLitemPerAdserv.get(proposalId);
                    if(mapPropLine == null){
                        mapPropToMapLitemPerAdserv.put(proposalId, new Map<String, DART6_LINEITEMSERVICE.ProposalLineItem>{proposalLineItemId => itemRes});
                    }else{
                        mapPropLine.put(proposalLineItemId, itemRes);
                    }
                }
            }
        }

    }

    private void requestProposals(AdServer_Login__c login, String strListProposal, Map<String,DART6_ProposalService.Proposal> mapProposalPerAdserv) {

        DART6_ProposalService.SoapRequestHeader header = new DART6_ProposalService.SoapRequestHeader();
        header.applicationName = PROPOSAL_SERVICE_APPNAME;
        header.networkCode = login.Network_ID__c;

        DART6_ProposalService.ProposalServiceInterfacePort proposalRequest = new DART6_ProposalService.ProposalServiceInterfacePort();
        proposalRequest.RequestHeader = header;
        proposalRequest.timeout_x = TIMEOUT;
        proposalRequest.inputHttpHeaders_x = prepareInputHttpHeadersX(login);

        DART6_ProposalService.Statement filterPros = new DART6_ProposalService.Statement();
        //filterPros.query =  WHERE_ID_IN + strListProposal + ' AND dfpOrderId != NULL';
        filterPros.query =  WHERE_ID_IN + strListProposal;

        DART6_ProposalService.ProposalPage proposalPage = proposalRequest.getProposalsByStatement(filterPros);

        List<DART6_ProposalService.Proposal>lstDartProposals = new List<DART6_ProposalService.Proposal>();
        if (proposalPage.totalResultSetSize>0) {
            for (DART6_ProposalService.Proposal prosRes: proposalPage.results) {
                if(prosRes.dfpOrderId != null){
                    mapProposalPerAdserv.put(prosRes.id+'', prosRes);
                }
                
            }
        }
    }

    private void requestOrders(AdServer_Login__c login, String strListOrders, Map<String, DART6_ORDERSERVICE.Order> mapOrderPerAdserv) {
        
        DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
        header.applicationName = ORDER_SERVICE_APPNAME;
        header.networkCode = login.Network_ID__c;
    
        DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
        orderRequest.RequestHeader = header;
        orderRequest.timeout_x = TIMEOUT;
        orderRequest.inputHttpHeaders_x = prepareInputHttpHeadersX(login);
    
        DART6_ORDERSERVICE.Statement filterOrder = new DART6_ORDERSERVICE.Statement();
        filterOrder.query = WHERE_ID_IN + strListOrders;
    
        DART6_ORDERSERVICE.OrderPage orderPage = orderRequest.getOrdersByStatement(filterOrder);
        if (orderPage.totalResultSetSize>0) {
            for (DART6_ORDERSERVICE.Order orderRes: orderPage.results) {
                mapOrderPerAdserv.put(orderRes.Id+'', orderRes);
            }
        }
    }

    global void finish(Database.BatchableContext BC){
        if(!setSObjectId.isEmpty() && !isOppParam){
            BatchGetProposalLineItem sch = new BatchGetProposalLineItem(setSObjectId, isOppParam);
            Database.executeBatch(sch, BATCH_SIZE);
        }
    }

    global void execute(SchedulableContext sc) 
    {
        BatchGetProposalLineItem sch = new BatchGetProposalLineItem();
        Database.executeBatch(sch, BATCH_SIZE);
    }

}