/*********************************************************************************************************************************
@ Class:          BookingController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Class for booking ad product. It is called from BookingOppAdProdController.
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2021 / Sophal Noch / US-0009927 - Update PG Opportunity Flow 
*********************************************************************************************************************************/
/**  SFDC - DART mapping 
 
    1- Standard Opportunity
        Opportinity                 <------OrderId(Opt)------------     Order
        |----> LineItem1            <------AdId(*), OrderId(Opt)---     Ad1
        |----> LineItem2            <------AdId(*), OrderId(Opt)---     Ad2
          
    2- Mixed Opportunity
        Opportinity                 <------OrderId(Opt)------------     Order1
        |----> LineItem1            <------AdId(*), OrderId(Opt)---     Ad1.1
        |----> LineItem2            <------AdId(*), OrderId(Opt)---     Ad1.2
        |--> PackageMain            <------OrderId(*)--------------     Order2
        |----> PackageComponent1    <------AdId(*), OrderId(Opt)---     Ad2.1
        |----> PackageComponent2    <------AdId(*), OrderId(Opt)---     Ad2.2
     
    3-  Multi-Package Opportunity (Contains serveral packages)
        Opportunity
        |--> PackageMain1           <------OrderId(*)--------------     Order1
        |----> PackageComponent1.1  <------AdId(*), OrderId(Opt)---     Ad1.1
        |----> PackageComponent1.2  <------AdId(*), OrderId(Opt)---     Ad1.2
        |--> PackageMain2           <------OrderId(*)--------------     Order2
        |----> PackageComponent2.1  <------AdId(*), OrderId(Opt)---     Ad2.1
        |----> PackageComponent2.2  <------AdId(*), OrderId(Opt)---     Ad2.2
        
    4- Multiformat Opportunity
        Opportunity
        |--> LineItem1              <------OrderId(*)--------------     Order1
        |--> LineItem2              <------OrderId(*)--------------     Order2
        |--> LineItem3              <------OrderId(*)--------------     Order3
*/
public with sharing class BookingController {
    // list of order
    List<DARTObject.IDARTObjectOrder> lstOrder;

    // list of lineItem
    List<DARTObject.IDARTObjectAds> lstAds;

    // list of company(advertiser)
    List<DARTObject.IDARTObjectAdvertiser> lstDartAdvertiser;
    // list of existing company(advertiser)
    List<DARTObject.IDARTObjectAdvertiser> lstAdvsExist;
    // Adv Server    
    AdServer_Login__c credential;
    // invoking type
    String invokedMethod;
    // related account of opp
    Account[] lstAccs;

    private static final String PROPOSAL_LINEITEM_ID_FNAME = 'Proposal_Lineitem_Id__c';

    @TestVisible
    SObject lineItemRecord, 
            parentRecord;
            
    String  dartVersion, 
            dartCountry, 
            dartVerCountry, 
            adserverIDOrderID, 
            adserverAdvID, 
            advertiserID, 
            agency, 
            parentRecordOwnerName, 
            sobjectType;

    /** 
     * Contructor 
     * @param IO__c
     * @param IO_LineItem__c
     */
    public BookingController(SObject parentRecord, SObject lineItemRecord, String dartVersion, String dartCountry, String dartVerCountry, String advertiserID) {
        this.parentRecord = parentRecord;
        this.lineItemRecord = lineItemRecord;
        this.dartVersion = dartVersion;
        this.dartCountry = dartCountry;
        this.dartVerCountry = dartVerCountry;
        this.advertiserID = advertiserID;
        this.parentRecordOwnerName = UTIL.getString(GW_sObject.getFieldValueAsObject(parentRecord, 'Owner.Name'));
        credential = DARTUtil.getCredential(dartVersion, dartCountry);
        lstAccs = [Select id, Name, RecordType.name From Account Where Id =: advertiserID];
    }

    /** 
     * Request to create new Advertiser/Company 
     */
    public void requestCreateAdvertiser() {
        // Request to Create new Advertiser/Company
        if (lstAccs.size()> 0) {
            HTTPWrapper.IGenericRequest dartAdvRequest = FactoryDARTRequest.getInstance().createDartSubmitAdvertiserRequest(credential, lstAccs.get(0));
            DART6Parser.IDartParser dartAdvParser = FactoryParser.getInstance().createAdvertiserParser(lstAccs.get(0), dartVersion);
            DARTObject.IDARTConnector dartAdvCon = FactoryConnector.getInstance().createConnector(dartVersion, dartAdvRequest, dartAdvParser);
            dartAdvCon.connect();
            lstDartAdvertiser = (List<DARTObject.IDARTObjectAdvertiser>) dartAdvCon.getDartObjects();
            invokedMethod = dartAdvRequest.getInvokedMethod();
        } else {
            throw new ExceptionGroup.DARTException('No related Account for this Opportunity.');
        }
    }

    /**
     * This is call to  create order in DFP 
     * @param mapping of Advertiser
     */
    public void processAndSendOrder(Map<String, Advertiser__c> mapAdvertiser) {

        // Request person from dart5
        // Dart5: UserRoleId=1 => Salesperson
        // Dart5: UserRoleId=2 => Primary Traficker

        List<DARTObject.DARTPerson> listDartPerson = new List<DARTObject.DARTPerson>();
        Map<String, DARTObject.DARTPerson> mapDartUser = new Map<String, DARTObject.DARTPerson>();

        if (dartVersion.equals(DARTUtil.DART6)) {
            // Request to get User/Traficker ID (DART USER ID) 
            HTTPWrapper.IGenericRequest dartListSalesPerson = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest(credential, parentRecord);
            DART6Parser.IDartParser salespersonParser = FactoryParser.getInstance().createSalespersonParser(dartVersion);
            DARTObject.IDARTConnector personCon = FactoryConnector.getInstance().createConnector(dartVersion, dartListSalesPerson, salespersonParser);
            personCon.connect();
            listDartPerson.addAll((List<DARTObject.DARTPerson>)personCon.getDartObjects());
        }

        for (DARTObject.DARTPerson p: listDartPerson) {
            if (UserInfo.getName().equals(p.getDartName())) {
                mapDartUser.put(UserInfo.getName(), p);
            } 
            else if (UserInfo.getUserEmail().equals(p.getUserEmail())) { //MN-15062021-US-0009671 - [Ads 2020] Change to matching GAM trafficker to Hive user
                mapDartUser.put(UserInfo.getUserEmail(), p);
            }
            else if (!String.isEmpty(parentRecordOwnerName) && parentRecordOwnerName.equals(p.getDartName())) {
                mapDartUser.put(parentRecordOwnerName, p);
            }
            mapDartUser.put(p.getDartName(), p);
        }
       
        // Order Request 
        HTTPWrapper.IGenericRequest dartSubmitOrderReq = FactoryDARTRequest.getInstance().createDARTSubmitOrderRequest(credential, dartVerCountry, parentRecord, lineItemRecord, mapDartUser, mapAdvertiser);
        DART6Parser.IDartParser orderParser = FactoryParser.getInstance().createOrderParser(credential, dartVersion, parentRecord);
        DARTObject.IDARTConnector orderCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitOrderReq, orderParser);
        orderCon.connect(); 
        invokedMethod = dartSubmitOrderReq.getInvokedMethod();
        lstOrder = (List<DARTObject.IDARTObjectOrder>)orderCon.getDartObjects();
    }

    /*****************************************************************************************************************************
    @ Method:       processAndSendProposal
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      get DartUser and submit Proposal to GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public void processAndSendProposal(Map<String, Advertiser__c> mapAdvertiser) {

        Map<String, DARTObject.DARTPerson> mapDartUser = new Map<String, DARTObject.DARTPerson>();
        getDartUser(mapDartUser);
       
        // Proposal Request 
        HTTPWrapper.IGenericRequest dartSubmitProReq = FactoryDARTRequest.getInstance().createDARTSubmitProposalRequest(credential, dartVerCountry, parentRecord, lineItemRecord, mapDartUser, mapAdvertiser);
        DART6Parser.IDartParser proposalParser = FactoryParser.getInstance().createProposalParser(credential, dartVersion, parentRecord);
        DARTObject.IDARTConnector proposalCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitProReq, proposalParser);
        proposalCon.connect(); 
        invokedMethod = dartSubmitProReq.getInvokedMethod();
        lstOrder = (List<DARTObject.IDARTObjectOrder>)proposalCon.getDartObjects();
    }

    private void getDartUser(Map<String, DARTObject.DARTPerson> mapDartUser) {

        List<DARTObject.DARTPerson> listDartPerson = new List<DARTObject.DARTPerson>();
        
        if (dartVersion.equals(DARTUtil.DART6)) {
            HTTPWrapper.IGenericRequest dartListSalesPerson = FactoryDARTRequest.getInstance().createDartSubmitSalePersonRequest(credential, parentRecord);
            DART6Parser.IDartParser salespersonParser = FactoryParser.getInstance().createSalespersonParser(dartVersion);
            DARTObject.IDARTConnector personCon = FactoryConnector.getInstance().createConnector(dartVersion, dartListSalesPerson, salespersonParser);
            personCon.connect();
            listDartPerson.addAll((List<DARTObject.DARTPerson>)personCon.getDartObjects());
        }

        for (DARTObject.DARTPerson p: listDartPerson) {
            if (UserInfo.getName().equals(p.getDartName())) {mapDartUser.put(UserInfo.getName(), p);} 
            else if (UserInfo.getUserEmail().equals(p.getUserEmail())) {mapDartUser.put(UserInfo.getUserEmail(), p);}
            else if (!String.isEmpty(parentRecordOwnerName) && parentRecordOwnerName.equals(p.getDartName())) {mapDartUser.put(parentRecordOwnerName, p);}
            mapDartUser.put(p.getDartName(), p);
        }
        
    }


    /**
     * Request to get existing order by opportunity's name
     * @return DartObjectOrder
     */
    public List<DARTObject.IDARTObjectOrder> getExistOrder() {
        // 25-07-2014: #3657 - find order before create. if exists, take it, otherwise create new."
        List<DARTObject.IDARTObjectOrder> lstExistOrder = new List<DARTObject.IDARTObjectOrder> ();
        if (dartVersion.equals(DARTUtil.DART6)) {
            // Request to getOrder by opp's name
            HTTPWrapper.IGenericRequest dartGetOrderReq = FactoryDARTRequest.getInstance().createGetOrderRequest(credential, parentRecord);
            DART6Parser.IDartParser orderExtParser = FactoryParser.getInstance().createOrderParser(credential, dartVersion, parentRecord);
            DARTObject.IDARTConnector orderExtCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetOrderReq, orderExtParser);
            orderExtCon.connect(); 
            invokedMethod = dartGetOrderReq.getInvokedMethod(); 
            lstExistOrder = (List<DARTObject.IDARTObjectOrder>)orderExtCon.getDartObjects();
        }
        return lstExistOrder;
    }

    /*****************************************************************************************************************************
    @ Method:       getExistProposal
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      get existing Proposal from GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public List<DARTObject.IDARTObjectOrder> getExistProposal() {
        List<DARTObject.IDARTObjectOrder> lstExistProposal = new List<DARTObject.IDARTObjectOrder> ();
        if (dartVersion.equals(DARTUtil.DART6)) {
            HTTPWrapper.IGenericRequest dartGetProposalReq = FactoryDARTRequest.getInstance().createGetProposalRequest(credential, parentRecord);
            DART6Parser.IDartParser proposalExtParser = FactoryParser.getInstance().createProposalParser(credential, dartVersion, parentRecord);
            DARTObject.IDARTConnector proposalExtCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetProposalReq, proposalExtParser);
            proposalExtCon.connect(); 
            invokedMethod = dartGetProposalReq.getInvokedMethod(); 
            lstExistProposal = (List<DARTObject.IDARTObjectOrder>)proposalExtCon.getDartObjects();
        }
        return lstExistProposal;
    }


    /**
     * This is process to create lineItem in DFP
     * @param dartOrdr object
     * @param mapping of Advertiser 
     */
    public void processAndSendLineItem(DARTObject.IDARTObjectOrder dartOrder, Map<String, Advertiser__c> mapAdvertiser) {
        List<DARTObject.IDARTObjectAds> lstExistLineItem = new List<DARTObject.IDARTObjectAds> ();
        if (dartVersion.equals(DARTUtil.DART6) && String.isEmpty(UTIL.getString(GW_sObject.getFieldValueAsObject(lineItemRecord, 'Ad_Id__c')))) {
            // Search lineItem before creating
            HTTPWrapper.IGenericRequest dartGetLineItemReq = FactoryDARTRequest.getInstance().createGetLineItemRequest(credential, lineItemRecord, dartOrder);
            DART6Parser.IDartParser getLineItemParser = FactoryParser.getInstance().createAdsParser(credential, dartVersion, lineItemRecord, mapAdvertiser);
            DARTObject.IDARTConnector getItemCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetLineItemReq, getLineItemParser);
            getItemCon.connect();
            invokedMethod = dartGetLineItemReq.getInvokedMethod();
            lstExistLineItem = (List<DARTObject.IDARTObjectAds>)getItemCon.getDartObjects();
        }
        
        if (lstExistLineItem.isEmpty()) {
            // LineItem Request to create
            HTTPWrapper.IGenericRequest dartSubmitAdsReq = FactoryDARTRequest.getInstance().createDARTSubmitAdsRequest(credential, lineItemRecord, dartOrder);
            DART6Parser.IDartParser adsParser = FactoryParser.getInstance().createAdsParser(credential, dartVersion, lineItemRecord, mapAdvertiser);
            DARTObject.IDARTConnector adsCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitAdsReq, adsParser);
            adsCon.connect();
            invokedMethod = dartSubmitAdsReq.getInvokedMethod();
            lstAds = (List<DARTObject.IDARTObjectAds>) adsCon.getDartObjects();
        } else {
            lstAds = new List<DARTObject.IDARTObjectAds>();
            lstAds.AddAll(lstExistLineItem);
        }
    }

    /*****************************************************************************************************************************
    @ Method:       processAndSendProposalLineItem
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      get and submit Proposal to GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created the method. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public void processAndSendProposalLineItem(DARTObject.IDARTObjectOrder dartProposal, Map<String, Advertiser__c> mapAdvertiser) {
        List<DARTObject.IDARTObjectAds> lstExistLineItem = new List<DARTObject.IDARTObjectAds> ();
        if (dartVersion.equals(DARTUtil.DART6) && String.isEmpty(UTIL.getString(GW_sObject.getFieldValueAsObject(lineItemRecord, PROPOSAL_LINEITEM_ID_FNAME)))) {
            // Search lineItem before creating
            HTTPWrapper.IGenericRequest dartGetLineItemReq = FactoryDARTRequest.getInstance().createGetProposalLineItemRequest(credential, lineItemRecord, dartProposal);
            DART6Parser.IDartParser getLineItemParser = FactoryParser.getInstance().createProposalLineItemParser(credential, dartVersion, lineItemRecord, mapAdvertiser);
            DARTObject.IDARTConnector getItemCon = FactoryConnector.getInstance().createConnector(dartVersion, dartGetLineItemReq, getLineItemParser);
            getItemCon.connect();
            invokedMethod = dartGetLineItemReq.getInvokedMethod();
            lstExistLineItem = (List<DARTObject.IDARTObjectAds>)getItemCon.getDartObjects();
        }

        if (lstExistLineItem.isEmpty()) {
            HTTPWrapper.IGenericRequest dartSubmitProposalLineItemReq = FactoryDARTRequest.getInstance().createDARTSubmitProposalLineitemsRequest(credential, lineItemRecord, dartProposal);
            DART6Parser.IDartParser proposalLineitemParser = FactoryParser.getInstance().createProposalLineItemParser(credential, dartVersion, lineItemRecord, mapAdvertiser);
            DARTObject.IDARTConnector proposalLineItemCon = FactoryConnector.getInstance().createConnector(dartVersion, dartSubmitProposalLineItemReq, proposalLineitemParser);
            proposalLineItemCon.connect();
            invokedMethod = dartSubmitProposalLineItemReq.getInvokedMethod();
            lstAds = (List<DARTObject.IDARTObjectAds>) proposalLineItemCon.getDartObjects();
        } else {
            lstAds = new List<DARTObject.IDARTObjectAds>();
            lstAds.AddAll(lstExistLineItem);
        }
    }



    /**
     * This is the process to search Advertiser in DFP by Account's name 
     */
    public void processSearchAdvertiser() {
        HTTPWrapper.IGenericRequest dartAdvRequest = FactoryDARTRequest.getInstance().createDartGetAdvertiserRequest(credential, lineItemRecord, lstAccs.get(0), dartCountry);
        DART6Parser.IDartParser dartAdvParser = FactoryParser.getInstance().createAdvertiserParser(lstAccs.get(0), dartVersion);
        DARTObject.IDARTConnector dartAdvCon = FactoryConnector.getInstance().createConnector(dartVersion, dartAdvRequest, dartAdvParser);
        dartAdvCon.connect();
        lstAdvsExist = (List<DARTObject.IDARTObjectAdvertiser>) dartAdvCon.getDartObjects();
        invokedMethod = dartAdvRequest.getInvokedMethod();
    }

    /**
     * @return existing Advertiser
     */
    public List<DARTObject.IDARTObjectAdvertiser> getListAdvertiserExist() {
        return lstAdvsExist;
    }

    /**
     * return list of responsed advertiser object after created in DFP
     */
    public List<DARTObject.IDARTObjectAdvertiser> getListAdvertiser() {
        return lstDartAdvertiser;
    }

    /**
     * @return list of lineItem responsed after created in DFP
     */
    public List<DARTObject.IDARTObjectAds> getListAds() {
        return lstAds;
    }

    /**
     * @return list of order responsed after created in DFP
     */
    public List<DARTObject.IDARTObjectOrder> getListOrder() {
        return lstOrder;
    }

    /**
     * @return type of invoking methode, ex: getOrder, createOrder,....
     */
    public String getInvokedMethod() {
        return invokedMethod;
    }
}