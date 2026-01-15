/*********************************************************************************************************************************
@ Class:          DART6Message
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Class for handle requests to GAM
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  01.12.2021 / Sophal Noch / US-0009927 - Update PG Opportunity Flow 
@               :  25.03.2021 / Sophal Noch /US-0011408 - Upgrade API version of DFP
@				: 11.09.2023 /vadhanak voun/ US-0013940 - PART 2 - Upgrade API version of all classes having an API version lower than 31
*********************************************************************************************************************************/
public with sharing class DART6Message {
    public final static String DART6_WS_ERROR_PATTERN = 'Web service callout failed: WebService returned a SOAP Fault: \\[(.*?)\\] faultcode=soap:Server faultactor=';
    public final static Map<String, String> MAP_TIME_UNITS = new Map<String, String> {
        'Minutes' => 'MINUTE',
        'Hours' => 'HOUR',
        'Days' => 'DAY',
        'Weeks' => 'WEEK',
        'Months' => 'MONTH',
        'Minute' => 'MINUTE',
        'Hour' => 'HOUR',
        'Day' => 'DAY',
        'Week' => 'WEEK',
        'Month' => 'MONTH',
        'Lifetime' => 'LIFETIME',
        'POD' => 'POD',
        'STREAM' => 'STREAM',
        'UNKNOWN' => 'UNKNOWN',
        '' => 'UNKNOWN',
        null => 'UNKNOWN'
    };


    public final static String BILLING_CATE_FIX_PRICE = 'Fix Price';
    public final static String LINEITEM_TYPE_NETWORK = 'NETWORK';
    public final static String LINEITEM_TYPE_HOUSE = 'HOUSE';
    public final static String LINEITEM_TYPE_AD_EXCHANGE = 'Ad Exchange';
    public final static String LINEITEM_TYPE_ADSENSE = 'AdSense';
    public final static String LINEITEM_TYPE_SPONSERSHIP = 'SPONSORSHIP';

    final static String INVENTORY_SIZE_TYPE_COM = 'Companion';
    final static String INVENTORY_SIZE_TYPE_VID = 'Video VAST';

    public final static String BREAKDOWN_DAILY = 'Daily';
    public final static String BREAKDOWN_MONTHLY = 'Monthly';
    public final static String DATERANGE_YESTERDAY = 'Yesterday';
    public final static String DATERANGE_LASTMONTH = 'LastMonth';
    //@updated Chr-28-08-2015: #7820 Runscope proxy for DFP
    //User proxy runscope to monitor traffice between SF and DFP
    public static final String ENDPOINT_RUNSCOPE_PROXY = '';
    public DART6Message() {
        String s;
    }

    private static final Map<String, String> MAP_COST_TYPES = new Map<String, String> {
        'CPM' => 'CPM',
        'CPC' => 'CPC',
        'CPA' => 'CPA',
        'CPD' => 'CPD',
        'Subscription' => 'CPM',
        'ServiceFee' => 'CPM',
        'Fix Price' => 'CPD',
        'CPO' => 'CPO'
    };

    private final static String STR_BROWSER = 'Browser';
    private final static String STR_BROWSER_LANGUAGE = 'BrowserLanguage';
    private final static String STR_DEVICE_CAPABILITY = 'DeviceCapability';
    private final static String STR_DEVICE_MANUFACTURER = 'DeviceManufacturer';
    private final static String STR_OPERATING_SYSTEM = 'OperatingSystem';
    private final static String STR_OPERATING_SYSTEM_VERSION = 'OperatingSystemVersion';
    private final static String STR_MOBILE_DEVICE = 'MobileDevice';
    private final static String STR_MOBILE_DEVICE_SUBMODEL = 'MobileDeviceSubmodel';

    private final static String STR_BANDWIDTH_GROUP = 'BandwidthGroup';
    private final static String STR_MOBILE_CARRIER = 'MobileCarrier';

    private final static String STR_ZERO = 'ZERO';

    private final static String SITE_ID_FNAME = 'siteId';
    private final static String AD_UNIT_ID_FNAME = 'adUnitId';

    private final static Set<String> LINEITEM_STATUSES = new Set<String>{
        'READY',
        'DELIVERING',
        'COMPLETED'
    };

    private final static LONG EXCLUDE_MOBILE_TARGETING_ID = Long.valueOf(Label.EXCLUDE_MOBILE_TARGETING_ID);

    public abstract class AbstractDFPRequest extends AbstractDARTRequest implements HTTPWrapper.IInvoker {}

    /** 
     * @description request to create companay in DFP
     */
    public class DFPCompanyRequest extends AbstractDFPRequest {

        List<DART6_COMPANYSERVICE.Company>newCompanies;
        Account acc;
        AdServer_Login__c login;

        public DFPCompanyRequest(Account acc, AdServer_Login__c login) {
            this.acc = acc;
            this.login = login;
        }

        public void invoke() {

            newCompanies = new List<DART6_COMPANYSERVICE.Company>();
            String authToken = DARTUtil.getAccessToken(login);

            DART6_COMPANYSERVICE.SoapRequestHeader header = new DART6_COMPANYSERVICE.SoapRequestHeader();
            header.applicationName = 'OrderService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_COMPANYSERVICE.CompanyServiceInterfacePort companyRequest = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            companyRequest.RequestHeader = header;
            companyRequest.inputHttpHeaders_x = inputHttpHeaders_x;

            DARTObject.DARTAdvertiser dartAdvt = new DARTObject.DARTAdvertiser(acc);

            DART6_COMPANYSERVICE.Company com = new DART6_COMPANYSERVICE.Company();
            com.name = dartAdvt.getAccountName();
            com.externalId = dartAdvt.getAccountId();
            com.type_x = 'ADVERTISER';
            com.creditStatus = 'ACTIVE';

            try {
                List<DART6_COMPANYSERVICE.Company>cmps = companyRequest.createCompanies(new List<DART6_COMPANYSERVICE.Company>{
                    com
                });
                newCompanies.addAll(cmps);
            } catch (System.CalloutException cex) {
                throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
            }
            invokedMethod = 'Create Advertiser';
        }

        public Object getResponseObject() {
            return newCompanies;
        }
    }


    /** 
     * @description request to get company(Advertiser) from DFP that filter by Account's name 
     */
    public class DFPGetAdvertiserRequest extends AbstractDFPRequest {
        SObject contextRecord;
        Account acc;
        List<DART6_COMPANYSERVICE.Company>dartAdvs;
        String dartCountry;
        
        public DFPGetAdvertiserRequest(SObject contextRecord, Account acc) {
            this.contextRecord = contextRecord;
            this.acc = acc;
        }
        
        public DFPGetAdvertiserRequest(SObject contextRecord, Account acc, String dartCountry) {
            this.contextRecord = contextRecord;
            this.acc = acc;
            this.dartCountry = dartCountry;
        }

        public void invoke() {
            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, dartCountry);
            String authToken = DARTUtil.getAccessToken(login);
            DART6_COMPANYSERVICE.SoapRequestHeader header = new DART6_COMPANYSERVICE.SoapRequestHeader();
            header.applicationName = 'CompanyService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_COMPANYSERVICE.CompanyServiceInterfacePort companyRequest = new DART6_COMPANYSERVICE.CompanyServiceInterfacePort();
            companyRequest.RequestHeader = header;
            companyRequest.inputHttpHeaders_x = inputHttpHeaders_x;

            String accName = (acc.Name + '').replace('\'', '\'\'').replace('"', '""');
            String querySt = 'WHERE name = \'' + accName + '\'';

            // Advertiser id
            DART6_COMPANYSERVICE.Statement filterAdv = new DART6_COMPANYSERVICE.Statement();
            filterAdv.query = querySt;


            DART6_COMPANYSERVICE.CompanyPage advPage = companyRequest.getCompaniesByStatement(filterAdv);
            dartAdvs = new List<DART6_COMPANYSERVICE.Company>();
            if (advPage.totalResultSetSize>0) {
                for (DART6_COMPANYSERVICE.Company cmp: advPage.results) {
                    DART6_COMPANYSERVICE.Company dartAd = new DART6_COMPANYSERVICE.Company();
                    dartAd.id = cmp.id;
                    dartAd.name = cmp.name;
                    dartAdvs.add(dartAd);
                }
            }
            invokedMethod = 'getAdvertiser';

        }

        public Object getResponseObject() {
            return dartAdvs;
        }
    }

    /** 
     * @createdDate - 25-07-2014
     * @escription request to DFP to get Order that filter by Opportunity's name
     */
    public class DFPGetOrderRequest extends AbstractDFPRequest {

        SObject contextRecord;
        DART6_ORDERSERVICE.Order existOrder;
        AdServer_Login__c login;

        public DFPGetOrderRequest(SObject contextRecord, AdServer_Login__c login) {
            this.contextRecord = contextRecord;
            this.login = login;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login);

            DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
            header.applicationName = 'OrderService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            orderRequest.RequestHeader = header;
            orderRequest.inputHttpHeaders_x = inputHttpHeaders_x;

            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(contextRecord);

            //String orderName = dartOrder.getOrderName();
            //String querySt =  'WHERE name = \''+ orderName +'\'';
            //MN-27082019
            String orderId = dartOrder.getOrderId();
            String querySt = 'WHERE id = \'' + orderId + '\'';

            // Get order
            DART6_ORDERSERVICE.Statement filterOrd = new DART6_ORDERSERVICE.Statement();
            filterOrd.query = querySt;

            DART6_ORDERSERVICE.OrderPage orderPage = orderRequest.getOrdersByStatement(filterOrd);
            List<DART6_ORDERSERVICE.Order>lstDartOrders = new List<DART6_ORDERSERVICE.Order>();
            if (orderPage.totalResultSetSize>0) {
                for (DART6_ORDERSERVICE.Order ordRes: orderPage.results) {
                    DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
                    ord.id = ordRes.id;
                    ord.name = ordRes.name;
                    ord.advertiserId = ordRes.advertiserId;

                    lstDartOrders.add(ord);
                }
            }
            if (!lstDartOrders.isEmpty()) existOrder = lstDartOrders.get(0);
            invokedMethod = 'getOrderByName';
        }

        public Object getResponseObject() {
            return existOrder;
        }
    }

    /*****************************************************************************************************************************
    @ Class:    DFPGetProposalRequest
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      get Proposal from GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created Class. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public class DFPGetProposalRequest extends AbstractDFPRequest {

        SObject contextRecord;
        DART6_ProposalService.Proposal existProposal;
        AdServer_Login__c login;

        public DFPGetProposalRequest(SObject contextRecord, AdServer_Login__c login) {
            this.contextRecord = contextRecord;
            this.login = login;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login);

            DART6_ProposalService.SoapRequestHeader header = new DART6_ProposalService.SoapRequestHeader();
            header.applicationName = 'ProposalService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_ProposalService.ProposalServiceInterfacePort proposalRequest = new DART6_ProposalService.ProposalServiceInterfacePort();
            proposalRequest.RequestHeader = header;
            proposalRequest.inputHttpHeaders_x = inputHttpHeaders_x;

            DARTObject.DARTOrder dartProposal = new DARTObject.DARTOrder(contextRecord, true);

            String proposalId = dartProposal.getOrderId();
            String querySt = 'WHERE id = \'' + proposalId + '\'';

            DART6_ProposalService.Statement filterPros = new DART6_ProposalService.Statement();
            filterPros.query = querySt;

            DART6_ProposalService.ProposalPage proposalPage = proposalRequest.getProposalsByStatement(filterPros);
            List<DART6_ProposalService.Proposal>lstDartProposals = new List<DART6_ProposalService.Proposal>();
            if (proposalPage.totalResultSetSize>0) {
                for (DART6_ProposalService.Proposal prosRes: proposalPage.results) {
                    DART6_ProposalService.Proposal pros = new DART6_ProposalService.Proposal();
                    pros.id = prosRes.id;
                    pros.name = prosRes.name;
                    
                    DART6_ProposalService.ProposalCompanyAssociation proposalCa = new DART6_ProposalService.ProposalCompanyAssociation();
                    proposalCa.companyId = prosRes.advertiser.companyId;
                    pros.advertiser = proposalCa;

                    lstDartProposals.add(pros);
                }
            }
            if (!lstDartProposals.isEmpty()) existProposal = lstDartProposals.get(0);
            invokedMethod = 'getProposalByName';
        }

        public Object getResponseObject() {
            return existProposal;
        }
    }




    /** 
     * @createdDate 25-07-2014
     * @description request to DFP to get lineItem that filter by Ad_Name__c 
     */
    public class DFPGetLineItemRequest extends AbstractDFPRequest {

        DART6_LINEITEMSERVICE.LineItem existItem;
        IO_LineItem__c IOLineItem;
        SObject contextRecord;
        DARTObject.IDARTObjectOrder dartOrder;
        AdServer_Login__c login;

        String FIELDTYPE_TEXTVALUE = 'TextValue';
        String FIELDTYPE_NUMBERVALUE = 'NumberValue';

        public DFPGetLineItemRequest(AdServer_Login__c login, SObject contextRecord, DARTObject.IDARTObjectOrder dartOrder) {
            this.login = login;
            this.dartOrder = dartOrder;
            this.contextRecord = contextRecord;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login); // new version 201405

            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName = 'LineItemService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;


            DARTObject.DARTAds dartAds = new DARTObject.DARTAds(contextRecord);
            String itemName = dartAds.getName();
            Long ordId = null;
            if (dartOrder != null) {
                ordId = Long.valueOf(dartOrder.getDartId());
            }

            //Sophal:15/03/2021:US-0009282 disable code below. use binding instead
            // String querySt = 'WHERE name = \'' + itemName + '\'  AND orderId=' + ordId;
            // // Get LineItem
            // DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
            // filterItem.query = querySt;
            
            //Sophal:15/03/2021:US-0009282 use bidding to send request to dfp
            DART6_LINEITEMSERVICE.Statement filterItem = createQueryStatementFromItemNameAndOrderId(itemName, ordId);


            DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
            List<DART6_LINEITEMSERVICE.LineItem>lstDartItems = new List<DART6_LINEITEMSERVICE.LineItem>();
            if (itemPage.totalResultSetSize>0) {
                for (DART6_LINEITEMSERVICE.LineItem itemRes: itemPage.results) {
                    DART6_LINEITEMSERVICE.LineItem lit = new DART6_LINEITEMSERVICE.LineItem();
                    lit.id = itemRes.id;
                    lit.orderId = itemRes.orderId;

                    lstDartItems.add(lit);
                }
            }
            if (!lstDartItems.isEmpty()) existItem = lstDartItems.get(0);
            invokedMethod = 'getLineItemByName';

        }

        public Object getResponseObject() {
            return existItem;
        }


        private DART6_LINEITEMSERVICE.Statement createQueryStatementFromItemNameAndOrderId(String itemName, Long ordId){
            //Sophal:15/03/2021:US-0009282 use bidding to send request to dfp
            DART6_LINEITEMSERVICE.TextValue txtValName = new DART6_LINEITEMSERVICE.TextValue();
            txtValName.value = itemName;
            txtValName.type_x = FIELDTYPE_TEXTVALUE;
    
    
            DART6_LINEITEMSERVICE.NumberValue numValOrderId = new DART6_LINEITEMSERVICE.NumberValue();
            numValOrderId.value = ''+ordId;
            numValOrderId.type_x = FIELDTYPE_NUMBERVALUE;
    
            DART6_LINEITEMSERVICE.String_ValueMapEntry mapStringName = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
            mapStringName.key = 'name';
            mapStringName.value = txtValName;
    
            DART6_LINEITEMSERVICE.String_ValueMapEntry mapStringOrderId = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
            mapStringOrderId.key = 'orderId';
            mapStringOrderId.value = numValOrderId;
                
            DART6_LINEITEMSERVICE.String_ValueMapEntry[] values = new DART6_LINEITEMSERVICE.String_ValueMapEntry[2];
            values[0] = mapStringName;
            values[1] = mapStringOrderId;
    
            DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
            filterItem.query = 'WHERE name = :name AND orderId = :orderId';
            filterItem.values = values;
    
            return filterItem;
        }

    }

    /*****************************************************************************************************************************
    @ Class:    DFPGetProposalLineItemRequest
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      get Proposal Lineitem from GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created class. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public class DFPGetProposalLineItemRequest extends AbstractDFPRequest {

        DART6_LINEITEMSERVICE.ProposalLineItem existItem;
        SObject contextRecord;
        DARTObject.IDARTObjectOrder dartProposal;
        AdServer_Login__c login;

        String FIELDTYPE_TEXTVALUE = 'TextValue';
        String FIELDTYPE_NUMBERVALUE = 'NumberValue';

        public DFPGetProposalLineItemRequest(AdServer_Login__c login, SObject contextRecord, DARTObject.IDARTObjectOrder dartProposal) {
            this.login = login;
            this.dartProposal = dartProposal;
            this.contextRecord = contextRecord;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login);

            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName = 'ProposalLineItemService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort();
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;

            DARTObject.DARTAds dartPropLineItems = new DARTObject.DARTAds(contextRecord, true);
            String itemName = dartPropLineItems.getName();
            Long propId = null;
            if (dartProposal != null) {
                propId = Long.valueOf(dartProposal.getDartId());
            }

            DART6_LINEITEMSERVICE.Statement filterItem = createQueryStatementFromItemNameAndProposalId(itemName, propId);

            DART6_LINEITEMSERVICE.ProposalLineItemPage itemPage = lineItemService.getProposalLineItemsByStatement(filterItem);
            List<DART6_LINEITEMSERVICE.ProposalLineItem>lstDartItems = new List<DART6_LINEITEMSERVICE.ProposalLineItem>();
            if (itemPage.totalResultSetSize>0) {
                for (DART6_LINEITEMSERVICE.ProposalLineItem itemRes: itemPage.results) {
                    DART6_LINEITEMSERVICE.ProposalLineItem lit = new DART6_LINEITEMSERVICE.ProposalLineItem();
                    lit.id = itemRes.id;
                    lit.proposalId = itemRes.proposalId;

                    lstDartItems.add(lit);
                }
            }
            if (!lstDartItems.isEmpty()) existItem = lstDartItems.get(0);
            invokedMethod = 'getProposalLineItemByName';

        }

        public Object getResponseObject() {
            return existItem;
        }

        private DART6_LINEITEMSERVICE.Statement createQueryStatementFromItemNameAndProposalId(String itemName, Long proposalId){
            DART6_LINEITEMSERVICE.TextValue txtValName = new DART6_LINEITEMSERVICE.TextValue();
            txtValName.value = itemName;
            txtValName.type_x = FIELDTYPE_TEXTVALUE;
    
            DART6_LINEITEMSERVICE.NumberValue numValPropId = new DART6_LINEITEMSERVICE.NumberValue();
            numValPropId.value = ''+proposalId;
            numValPropId.type_x = FIELDTYPE_NUMBERVALUE;
    
            DART6_LINEITEMSERVICE.String_ValueMapEntry mapStringName = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
            mapStringName.key = 'name';
            mapStringName.value = txtValName;
    
            DART6_LINEITEMSERVICE.String_ValueMapEntry mapStringPropId = new DART6_LINEITEMSERVICE.String_ValueMapEntry();
            mapStringPropId.key = 'proposalId';
            mapStringPropId.value = numValPropId;
                
            DART6_LINEITEMSERVICE.String_ValueMapEntry[] values = new DART6_LINEITEMSERVICE.String_ValueMapEntry[2];
            values[0] = mapStringName;
            values[1] = mapStringPropId;
    
            DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
            filterItem.query = 'WHERE name = :name AND proposalId = :proposalId';
            filterItem.values = values;
    
            return filterItem;
        }

    }



    /**
     * @description request to create order in DFP 
     */
    public class DFPOrderRequest extends AbstractDFPRequest {

        String dartVerCountry;
        DART6_ORDERSERVICE.Order newDartOrder;
        SObject lineItemRecord, parentRecord;
        AdServer_Login__c login;
        Map<String, DARTObject.DARTPerson>mapDartUser;
        Map<String, Advertiser__c> mapAdvertiser;

        public DFPOrderRequest(AdServer_Login__c login, String dartVerCountry, SObject parentRecord, SObject lineItemRecord, Map<String, DARTObject.DARTPerson>mapDartUser, Map<String, Advertiser__c> mapAdvertiser) {
            this.dartVerCountry = dartVerCountry;
            this.parentRecord = parentRecord;
            this.lineItemRecord = lineItemRecord;
            this.login = login;
            this.mapDartUser = mapDartUser;
            this.mapAdvertiser = mapAdvertiser;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login);
            String networkTimezone = login.Timezone__c + '';

            DART6_ORDERSERVICE.SoapRequestHeader header = new DART6_ORDERSERVICE.SoapRequestHeader();
            header.applicationName = 'OrderService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_ORDERSERVICE.OrderServiceInterfacePort orderRequest = new DART6_ORDERSERVICE.OrderServiceInterfacePort();
            orderRequest.RequestHeader = header;
            orderRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            orderRequest.timeout_x = 120000;
            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(parentRecord);

            // Create new Order 
            DART6_ORDERSERVICE.Order ord = new DART6_ORDERSERVICE.Order();
            ord.poNumber = dartOrder.getPONumber();
            ord.name = dartOrder.getOrderName();


            // System.debug('nsp: opp.offer_number__c = ' + (((Opportunity)parentRecord).offer_number__c));
            // Sophal Noch / 09.02.2021 / US-0009026
            if(parentRecord instanceof Opportunity){


                String offerNum =  ' - ' + (((Opportunity)parentRecord).offer_number__c);
                ord.name += offerNum;

            }

            ord.isArchived = false;

            String trafickerId = mapDartUser.containskey(UserInfo.getName()) ? mapDartUser.get(UserInfo.getName()).getDartId() : '';
            //trafickerId = mapDartUser.get('vengleab').getDartId(); // For testing

            //MN-15062021-US-0009671 - [Ads 2020] Change to matching GAM trafficker to Hive user
            if (String.isBlank(trafickerId) && mapDartUser.containskey(UserInfo.getUserEmail())) trafickerId = mapDartUser.get(UserInfo.getUserEmail()).getDartId();

            String ownerName = UTIL.getString(GW_sObject.getFieldValueAsObject(parentRecord, 'Owner.Name'));
            String salespersonId = mapDartUser.containskey(ownerName) ? mapDartUser.get(ownerName).getDartId() : '';

            if (mapAdvertiser.get(dartVerCountry) != null) {
                ord.advertiserId = Long.valueOf(mapAdvertiser.get(dartVerCountry).Dart6_Advertiser_Id__c); // Company ID
            }
            if (String.isNotEmpty(salespersonId)) {
                ord.salespersonId = Long.valueOf(salespersonId);
            }
            if (String.isNotEmpty(trafickerId)) {
                ord.traffickerId = Long.valueOf(trafickerId);
            }
            //call to create order
            try {
                List<DART6_ORDERSERVICE.Order>lstOrdersRq = orderRequest.createOrders(new List<DART6_ORDERSERVICE.Order>{
                    ord
                });
                if (!lstOrdersRq.isEmpty()) newDartOrder = lstOrdersRq.get(0);
            } catch (System.CalloutException cex) {
                throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
            }
            invokedMethod = 'createOrder';
        }

        public Object getResponseObject() {
            return newDartOrder;
        }
    }

    /*****************************************************************************************************************************
    @ Class:    DFPProposalRequest
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      Create Proposal in GAM
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created class. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public class DFPProposalRequest extends AbstractDFPRequest {

        String dartVerCountry;
        DART6_ProposalService.Proposal newDartProposal;
        SObject lineItemRecord, parentRecord;
        AdServer_Login__c login;
        Map<String, DARTObject.DARTPerson> mapDartUser;
        Map<String, Advertiser__c> mapAdvertiser;
        private final String ADVERTISER_TYPE = 'ADVERTISER';

        public DFPProposalRequest(AdServer_Login__c login, String dartVerCountry, SObject parentRecord, SObject lineItemRecord, Map<String, DARTObject.DARTPerson> mapDartUser, Map<String, Advertiser__c> mapAdvertiser) {
            this.dartVerCountry = dartVerCountry;
            this.parentRecord = parentRecord;
            this.lineItemRecord = lineItemRecord;
            this.login = login;
            this.mapDartUser = mapDartUser;
            this.mapAdvertiser = mapAdvertiser;
        }

        public void invoke() {
            String authToken = DARTUtil.getAccessToken(login);
            String networkTimezone = login.Timezone__c + '';

            DART6_ProposalService.SoapRequestHeader header = new DART6_ProposalService.SoapRequestHeader();
            header.applicationName = 'ProposalService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_ProposalService.ProposalServiceInterfacePort proposalRequest = new DART6_ProposalService.ProposalServiceInterfacePort();
            proposalRequest.RequestHeader = header;
            proposalRequest.inputHttpHeaders_x = inputHttpHeaders_x;
            proposalRequest.timeout_x = 120000;
            DARTObject.DARTOrder dartProposal = new DARTObject.DARTOrder(parentRecord, true);

            DART6_ProposalService.Proposal prop = new DART6_ProposalService.Proposal();
            prop.name = dartProposal.getOrderName();

            if(parentRecord instanceof Opportunity){
                String offerNum =  ' - ' + (((Opportunity)parentRecord).offer_number__c);
                prop.name += offerNum;
            }

            prop.isArchived = false;

            String trafickerId = mapDartUser.containskey(UserInfo.getName()) ? mapDartUser.get(UserInfo.getName()).getDartId() : '';
            
            if (String.isBlank(trafickerId) && mapDartUser.containskey(UserInfo.getUserEmail())) trafickerId = mapDartUser.get(UserInfo.getUserEmail()).getDartId();

            String ownerName = UTIL.getString(GW_sObject.getFieldValueAsObject(parentRecord, 'Owner.Name'));
            String salespersonId = mapDartUser.containskey(ownerName) ? mapDartUser.get(ownerName).getDartId() : '';

            if (mapAdvertiser.get(dartVerCountry) != null) {
                DART6_ProposalService.ProposalCompanyAssociation proposalAdvertiser = new DART6_ProposalService.ProposalCompanyAssociation();
                proposalAdvertiser.companyId = Long.valueOf(mapAdvertiser.get(dartVerCountry).Dart6_Advertiser_Id__c);
                proposalAdvertiser.type_x = ADVERTISER_TYPE;
                prop.advertiser = proposalAdvertiser;
            }
            if (String.isNotEmpty(salespersonId)) {
                DART6_ProposalService.SalespersonSplit primarySalesperson = new DART6_ProposalService.SalespersonSplit();
                primarySalesperson.userId = Long.valueOf(salespersonId);
                prop.primarySalesperson = primarySalesperson;
            }
            if (String.isNotEmpty(trafickerId)) {
                prop.primaryTraffickerId = Long.valueOf(trafickerId);
            }

            // 17.12.2021 / Sophal Noch / US-0009971 set buyeraccountid when create proposal
            String buyerId = dartProposal.getBuyerSeat();
            if (String.isNotBlank(buyerId)) {
                DART6_ProposalService.ProposalMarketplaceInfo propMartPlace = new DART6_ProposalService.ProposalMarketplaceInfo();
                propMartPlace.buyerAccountId = Long.valueOf(buyerId);
                prop.marketplaceInfo = propMartPlace;
            }

            prop.isProgrammatic = true;
            //call to create proposal
            try {
                List<DART6_ProposalService.Proposal>lstProposalsRq = proposalRequest.createProposals(new List<DART6_ProposalService.Proposal>{
                    prop
                });
                if (!lstProposalsRq.isEmpty()) newDartProposal = lstProposalsRq.get(0);
            } catch (System.CalloutException cex) {throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));}
            invokedMethod = 'createProposal';
        }

        public Object getResponseObject() {
            return newDartProposal;
        }
    }

    /**
     * @description request to get Salesperson and Trafficker from DFP
     * - Salesperson: get from DFP's user filter by name = opportunity.owner.Name
     * - Trafficker: get from DFP's user filter by UserInfo.getName()
     */
    public class DFPSalespersonRequest extends AbstractDFPRequest {

        List<DART6_USERSERVICE.User_x>dartUsers;
        AdServer_Login__c login;
        SObject parentRecord;

        public DFPSalespersonRequest(AdServer_Login__c login, SObject parentRecord) {
            this.login = login;
            this.parentRecord = parentRecord;
        }

        public void Invoke() {
            String authToken = DARTUtil.getAccessToken(login);

            DART6_USERSERVICE.SoapRequestHeader userHeader = new DART6_USERSERVICE.SoapRequestHeader();
            userHeader.applicationName = 'UserService';
            userHeader.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_USERSERVICE.UserServiceInterfacePort userRequest = new DART6_USERSERVICE.UserServiceInterfacePort();
            userRequest.RequestHeader = userHeader;
            userRequest.inputHttpHeaders_x = inputHttpHeaders_x;

            String uInfoName = UserInfo.getName().replace('\'', '\'\'').replace('"', '""');
            String ownerName = UTIL.getString(GW_sObject.getFieldValueAsObject(parentRecord, 'Owner.Name')).replace('\'', '\'\'').replace('"', '""');
            String querySt = 'WHERE (name = \'' + uInfoName + '\' OR name =\'' + ownerName + '\')';
            
            String uInfoEmail = UserInfo.getUserEmail().replace('\'', '\'\'').replace('"', '""'); //MN-14062021-US-0009671
            querySt += ' OR (email = \'' + uInfoEmail + '\')'; //MN-14062021-US-0009671

            // Get User Id (traffickerId) DART User By UserName in Adsever Login
            DART6_USERSERVICE.Statement filterUser = new DART6_USERSERVICE.Statement();
            filterUser.query = querySt;


            DART6_USERSERVICE.UserPage userPage = userRequest.getUsersByStatement(filterUser);
            dartUsers = new List<DART6_USERSERVICE.User_x>();
            if (userPage.totalResultSetSize>0) {
                for (DART6_USERSERVICE.User_x user: userPage.results) {
                    DART6_USERSERVICE.User_x dartuser = new DART6_USERSERVICE.User_x();
                    dartUser.id = user.id;
                    dartUser.name = user.name;
                    dartUser.email = user.email;
                    dartUsers.add(dartUser);
                }
            }
            invokedMethod = 'getCurrentUser';
        }

        public Object getResponseObject() {
            return dartUsers;
        }
    }

    /**
     * @description request to DFP to create lineItem
     */
    public class DFPAdsRequest extends AbstractDFPRequest {
        Map<String, String> transformFieldNames = new Map<String, String>{
            Util.NS + 'IO_LineItem__c.adUnitId' => 'Product__r.Site__r.Run_of_Network_ID__c',
            Util.NS + 'IO_LineItem__c.siteId' => 'Product__r.Site__r.Id',
            'QuoteLineItem.adUnitId' => 'PriceBookEntry.Product2.' + Util.NS + 'Site__r.' + Util.NS + 'Run_of_Network_ID__c',
            'QuoteLineItem.siteId' => 'PriceBookEntry.Product2.' + Util.NS + 'Site__r.Id',
            //US-0008578 map for dart and Ad_Product__c.Product2__r
            'Ad_Product__c.adUnitId' => 'Product2__r.' + Util.NS + 'Site__r.' + Util.NS + 'Run_of_Network_ID__c',
            'Ad_Product__c.siteId' => 'Product2__r.' + Util.NS + 'Site__r.Id'
        };
        DART6_LINEITEMSERVICE.LineItem dfpLineItemResponse;
        DART6_LINEITEMSERVICE.ProposalLineItem dfpPropLineItemResponse;
        SObject contextRecord;
        AdServer_Login__c login;
        DARTObject.IDARTObjectOrder dartOrder;
        Boolean isProposal = false;

        public DFPAdsRequest(AdServer_Login__c login, SObject contextRecord, DARTObject.IDARTObjectOrder dartOrder) {
            this.login = login;
            this.contextRecord = contextRecord;
            this.dartOrder = dartOrder;
        }
        
        public DFPAdsRequest(AdServer_Login__c login, SObject contextRecord, DARTObject.IDARTObjectOrder dartOrder, Boolean isProposal) {
             // 15.12.2021 / Sophal Noch / US-0009927 new constructor to flag proposal lineitem request
            this.login = login;
            this.contextRecord = contextRecord;
            this.dartOrder = dartOrder;
            this.isProposal = isProposal;
        }

        
        public String getValueField(String varField) {
            String sobjectType = UTIL.getString(contextRecord.getSObjectType());
            String fieldName = transformFieldNames.get(sobjectType + '.' + varField);
            return UTIL.getString(GW_sObject.getFieldValueAsObject(contextRecord, fieldName));
        }

        public void Invoke() {

            DART6_KeyValueController ctrl;
            List<DART6_FORECASTSERVICE.CustomCriteriaSet>listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();

            String authToken = DARTUtil.getAccessToken(login);

            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName = isProposal ? 'ProposalLineItemService' : 'LineItemService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;

            DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort propLineItemService = new DART6_LINEITEMSERVICE.ProposalLineItemServiceInterfacePort();
            propLineItemService.RequestHeader = header;
            propLineItemService.timeout_x = 120000;
            propLineItemService.inputHttpHeaders_x = inputHttpHeaders_x;


            DARTObject.DARTAds dartAds = new DARTObject.DARTAds(contextRecord, isProposal);

            List<Long>placementIds = new List<Long>();
            for (Placement__c pPlacement: dartAds.getIncludePlacementTarget()) {
                if (pPlacement.Dart_Id__c != null) placementIds.add(Long.valueOf(pPlacement.Dart_Id__c + ''));
            }

            //targetedAdUnits
            List<DART6_LINEITEMSERVICE.AdUnitTargeting>adUnitTargs = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>();

            for (Content__c predefined: dartAds.getPredefinedAdunit()) {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = predefined.Name;
                adUnitTargs.add(adunit);
            }

            for (Content__c dartSite: dartAds.getIncludeDartSite()) {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = dartSite.Name;
                adUnitTargs.add(adunit);
            }
            for (Content__c dartZone: dartAds.getIncludeDartZone()) {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = dartZone.Name;
                adUnitTargs.add(adunit);
            }

            List<DART6_LINEITEMSERVICE.Location>lstLocations = new List<DART6_LINEITEMSERVICE.Location>();
            for (Geography__c g: dartAds.getIncludeGeography()) {
                DART6_LINEITEMSERVICE.Location loc = new DART6_LINEITEMSERVICE.Location();
                loc.id = Long.valueOf(g.Dart_ID__c + ''); // 2124
                loc.type_x = g.Type__c;
                lstLocations.add(loc);
            }

            //Pushing Device targeting to DFP
            DART6_LINEITEMSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
            DART6_LINEITEMSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;

            DART6_LINEITEMSERVICE.Technology[] listBandWidth = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] techMobileCar = new List<DART6_LINEITEMSERVICE.Technology>();
            Set<Id> connIds = new Map<id, Connection__c> (dartAds.getIncludeConnection()).keySet();

            List<Connection__c>  conns = [select id, name, DFP_API_Name__c, Node_ID__c, Dart_ID__c from connection__c WHERE node_id__r.id in: connIds or node_id__r.node_id__r.id in: connIds or id in: connIds];

            Set<Id> parentIds = new Set<Id> ();
            for (Connection__c c: conns) {
                parentIds.add(c.Node_ID__c);
            }

            for (Connection__c c: conns) {
                boolean isParent = parentIds.contains(c.id);

                if ((STR_BANDWIDTH_GROUP).equals(c.DFP_API_Name__c) && !isParent) {
                    DART6_LINEITEMSERVICE.Technology technologyBw = new DART6_LINEITEMSERVICE.Technology();
                    technologyBw.id = c.Dart_ID__c.longValue();
                    listBandWidth.add(technologyBw);
                } else if ((STR_MOBILE_CARRIER).equals(c.DFP_API_Name__c) && !isParent) {
                    DART6_LINEITEMSERVICE.Technology techMb = new DART6_LINEITEMSERVICE.Technology();
                    techMb.id = c.Dart_ID__c.longValue();
                    techMobileCar.add(techMb);
                }
            }


            if (!listBandWidth.isEmpty()) {
                bandwidthGroupTargeting = new DART6_LINEITEMSERVICE.BandwidthGroupTargeting();
                bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
            }

            if (!techMobileCar.isEmpty()) {
                mobileCarrierTargeting = new DART6_LINEITEMSERVICE.MobileCarrierTargeting();
                mobileCarrierTargeting.mobileCarriers = techMobileCar;
            }
            // ---------------- end of targeting device setup ----------------

            //pushing Connection targeting to DFP
            // -------------------------->> Device Targeting <<--------------------------------
            DART6_LINEITEMSERVICE.Technology[] listBrowsing = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listBrowsingLang = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listDeviceCap = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listDeviceCategory = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listDeviceManufacturer = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listOpSys = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listOpSysVersion = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listMobileDevice = new List<DART6_LINEITEMSERVICE.Technology>();
            DART6_LINEITEMSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_LINEITEMSERVICE.Technology>();

            //Targeting Device from targeting tree
            for (Devices__c d: dartAds.getIncludeDevice()) {
                if ((STR_BROWSER).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techBrw = new DART6_LINEITEMSERVICE.Technology();
                    techBrw.id = d.Dart_ID__c.longValue();
                    listBrowsing.add(techBrw);
                } else if ((STR_BROWSER_LANGUAGE).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techBrwLang = new DART6_LINEITEMSERVICE.Technology();
                    techBrwLang.id = d.Dart_ID__c.longValue();
                    listBrowsingLang.add(techBrwLang);
                } else if ((STR_DEVICE_CAPABILITY).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techDevCap = new DART6_LINEITEMSERVICE.Technology();
                    techDevCap.id = d.Dart_ID__c.longValue();
                    listDeviceCap.add(techDevCap);
                } else if ((STR_DEVICE_MANUFACTURER).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techDevMf = new DART6_LINEITEMSERVICE.Technology();
                    techDevMf.id = d.Dart_ID__c.longValue();
                    listDeviceManufacturer.add(techDevMf);
                } else if ((STR_OPERATING_SYSTEM).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techOs = new DART6_LINEITEMSERVICE.Technology();
                    techOs.id = d.Dart_ID__c.longValue();
                    listOpSys.add(techOs);
                } else if ((STR_OPERATING_SYSTEM_VERSION).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techOsVersion = new DART6_LINEITEMSERVICE.Technology();
                    techOsVersion.id = d.Dart_ID__c.longValue();
                    listOpSysVersion.add(techOsVersion);
                } else if ((STR_MOBILE_DEVICE).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techMobileDev = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDev.id = d.Dart_ID__c.longValue();
                    listMobileDevice.add(techMobileDev);
                } else if ((STR_MOBILE_DEVICE_SUBMODEL).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                    DART6_LINEITEMSERVICE.Technology techMobileDevSubMd = new DART6_LINEITEMSERVICE.Technology();
                    techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                    listMobileDeviceSubMod.add(techMobileDevSubMd);
                }
            }

            // DART6_LINEITEMSERVICE.BrowserTargeting
            DART6_LINEITEMSERVICE.BrowserTargeting browserTargeting = null;
            if (!listBrowsing.isEmpty()) {
                browserTargeting = new DART6_LINEITEMSERVICE.BrowserTargeting();
                browserTargeting.browsers = listBrowsing;
            }

            // DART6_LINEITEMSERVICE.BrowserLanguageTargeting
            DART6_LINEITEMSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
            if (!listBrowsingLang.isEmpty()) {
                browserLanguageTargeting = new DART6_LINEITEMSERVICE.BrowserLanguageTargeting();
                browserLanguageTargeting.browserLanguages = listBrowsingLang;
            }

            // DART6_LINEITEMSERVICE.DeviceCapabilityTargeting
            DART6_LINEITEMSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
            if (!listDeviceCap.isEmpty()) {
                deviceCapabilityTargeting = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
                deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
            }
            if(isProposal){ //US-0011408
                if(deviceCapabilityTargeting == null) deviceCapabilityTargeting = new DART6_LINEITEMSERVICE.DeviceCapabilityTargeting();
                DART6_LINEITEMSERVICE.Technology excludeTechno = new DART6_LINEITEMSERVICE.Technology();
                excludeTechno.id = EXCLUDE_MOBILE_TARGETING_ID;
                deviceCapabilityTargeting.excludedDeviceCapabilities = new DART6_LINEITEMSERVICE.Technology[]{excludeTechno};
            } //US-0011408

            //DART6_LINEITEMSERVICE.DeviceCategoryTargeting
            DART6_LINEITEMSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
            if (!listDeviceCategory.isEmpty()) {
                deviceCategoryTargeting = new DART6_LINEITEMSERVICE.DeviceCategoryTargeting();
                deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
            }

            //DART6_LINEITEMSERVICE.DeviceManufacturerTargeting ;
            DART6_LINEITEMSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
            if (!listDeviceManufacturer.isEmpty()) {
                deviceManufacturerTargeting = new DART6_LINEITEMSERVICE.DeviceManufacturerTargeting();
                deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
            }

            //DART6_LINEITEMSERVICE.OperatingSystemTargeting
            DART6_LINEITEMSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
            if (!listOpSys.isEmpty()) {
                OperatingSystemTargeting = new DART6_LINEITEMSERVICE.OperatingSystemTargeting();
                OperatingSystemTargeting.operatingSystems = listOpSys;
            }

            //DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting
            DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
            if (!listOpSysVersion.isEmpty()) {
                operatingSystemVersionTargeting = new DART6_LINEITEMSERVICE.OperatingSystemVersionTargeting();
                operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
            }

            //DART6_LINEITEMSERVICE.MobileDeviceTargeting
            DART6_LINEITEMSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
            if (!listMobileDevice.isEmpty()) {
                mobileDeviceTargeting = new DART6_LINEITEMSERVICE.MobileDeviceTargeting();
                mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
            }

            //DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting
            DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
            if (!listMobileDeviceSubMod.isEmpty()) {
                mobileDeviceSubmodelTargeting = new DART6_LINEITEMSERVICE.MobileDeviceSubmodelTargeting();
                mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
            }

            // --------------------- end of connection set up ------------

            // Targeting
            DART6_LINEITEMSERVICE.Targeting itemTargeting = new DART6_LINEITEMSERVICE.Targeting();

            //Set up Connection and Device targeting to the parent technologyTargeting
            //---------------------------- TechnologyTargeting ---------------------------//
            DART6_LINEITEMSERVICE.TechnologyTargeting techno = new DART6_LINEITEMSERVICE.TechnologyTargeting();
            techno.browserTargeting = browserTargeting;
            techno.bandwidthGroupTargeting = bandwidthGroupTargeting;
            techno.mobileCarrierTargeting = mobileCarrierTargeting;
            techno.browserTargeting = browserTargeting;
            techno.browserLanguageTargeting = browserLanguageTargeting;
            techno.deviceCapabilityTargeting = deviceCapabilityTargeting;
            techno.deviceCategoryTargeting = deviceCategoryTargeting;
            techno.deviceManufacturerTargeting = deviceManufacturerTargeting;
            techno.OperatingSystemTargeting = OperatingSystemTargeting;
            techno.operatingSystemVersionTargeting = operatingSystemVersionTargeting;
            techno.mobileDeviceTargeting = mobileDeviceTargeting;
            techno.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
            itemTargeting.technologyTargeting = techno;

            //DayPart
            List<DART6_LINEITEMSERVICE.DayPart>lstDayParts = new List<DART6_LINEITEMSERVICE.DayPart>();

            for (DARTObject.DTOTimeTargeting dto: dartAds.getListDTOTimeTargeting()) {
                for (String hour: dto.hours) { // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
                    List<String>lsthd = hour.split('-'); // (0:00, 0:59)
                    List<String>lstTimeStart = lsthd[0].split(':'); //(0, 00)
                    List<String>lstTimeEnd = lsthd[1].split(':'); // (0, 59)

                    DART6_LINEITEMSERVICE.TimeOfDay startTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim() + '');
                    startTimeOfDay.minute = STR_ZERO;

                    DART6_LINEITEMSERVICE.TimeOfDay endTimeOfDay = new DART6_LINEITEMSERVICE.TimeOfDay();
                    endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim() + '') + 1;
                    endTimeOfDay.minute = STR_ZERO;

                    DART6_LINEITEMSERVICE.DayPart dayPart = new DART6_LINEITEMSERVICE.DayPart();
                    dayPart.dayOfWeek = dto.day.toUpperCase();
                    dayPart.startTime = startTimeOfDay;
                    dayPart.endTime = endTimeOfDay;

                    lstDayParts.add(dayPart);
                }
            }

            // InventoryTargeting
            DART6_LINEITEMSERVICE.InventoryTargeting inventoryTargeting = new DART6_LINEITEMSERVICE.InventoryTargeting();

            if (placementIds.isEmpty() && adUnitTargs.isEmpty()) {
                DART6_LINEITEMSERVICE.AdUnitTargeting adunit = new DART6_LINEITEMSERVICE.AdUnitTargeting();
                adunit.adUnitId = getValueField(AD_UNIT_ID_FNAME);
                inventoryTargeting.targetedAdUnits = new List<DART6_LINEITEMSERVICE.AdUnitTargeting>{
                    adunit
                };
            } else {
                inventoryTargeting.targetedPlacementIds = placementIds;
                inventoryTargeting.targetedAdUnits = adUnitTargs;
            }

            itemTargeting.inventoryTargeting = inventoryTargeting;

            if (lstLocations.size()>0) {
                DART6_LINEITEMSERVICE.GeoTargeting geoTargeting = new DART6_LINEITEMSERVICE.GeoTargeting();
                geoTargeting.targetedLocations = lstLocations;
                itemTargeting.geoTargeting = geoTargeting;

            }

            if (lstDayParts.size()>0) {
                DART6_LINEITEMSERVICE.DayPartTargeting dayPartTargeting = new DART6_LINEITEMSERVICE.DayPartTargeting();
                dayPartTargeting.dayParts = lstDayParts;
                dayPartTargeting.timeZone = STR_BROWSER;
                itemTargeting.dayPartTargeting = dayPartTargeting;
            }

            ctrl = new DART6_KeyValueController(getValueField(SITE_ID_FNAME), dartAds.getKeyWKV(), authToken, login.Network_ID__c);
            if (ctrl.isNeedToCreate()) {
                ctrl.searchCreateDFPFreeFormValues();

            }
            listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>) ctrl.getListDart();

            if (listCrit.size()>0) {
                itemTargeting.customTargeting = listCrit.get(0);
            }

            /** Create LineItem */
            DART6_LINEITEMSERVICE.LineItem lineItem = new DART6_LINEITEMSERVICE.LineItem();
            DART6_LINEITEMSERVICE.ProposalLineItem propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem();
            
            // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem
            setStartEndDate(dartAds, null, lineItem, propLineItem, login);
            setTypeAndPrimaryGoal(dartAds, null, lineItem, propLineItem);

            Boolean startDateUpdatable = false;

            if(isProposal){
                if (String.isNotBlank(dartAds.getAdId())) {
                    invokedMethod = 'Get ProposalLineItems';
                    try {
                        // Before upadate LineItem need to select it from DFP to ensure that some field not update to avoid the errors: Ex: "LineItemError.ALREADY_STARTED @ startDateTime" 
                        propLineItem.id = Long.valueOf(dartAds.getAdId());

                        DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
                        filterItem.query = 'WHERE id=' + propLineItem.id;
                        DART6_LINEITEMSERVICE.ProposalLineItemPage itemPage = propLineItemService.getProposalLineItemsByStatement(filterItem);
                        if (itemPage.totalResultSetSize>0) {
                            for (DART6_LINEITEMSERVICE.ProposalLineItem qItem: itemPage.results) {
                                // 1 - check StartDateTime
                                if (LINEITEM_STATUSES.contains(qItem.computedStatus) || dartAds.getStartDateTime() < system.now()) propLineItem.startDateTime = qItem.startDateTime;
                                else startDateUpdatable = true;
                                // 2 - check Type
                                if (LINEITEM_STATUSES.contains(qItem.computedStatus)) propLineItem.lineItemType = qItem.lineItemType;
                            }
                        }
                    } catch (System.CalloutException cex) {
                        throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                    }
                }

                if (dartOrder != null) {
                    propLineItem.proposalId = Long.valueOf(dartOrder.getDartId());
                }

            }else{

                if (String.isNotBlank(dartAds.getAdId())) {
                    invokedMethod = 'Get LineItem/Ads';
                    try {
                        // Before upadate LineItem need to select it from DFP to ensure that some field not update to avoid the errors: Ex: "LineItemError.ALREADY_STARTED @ startDateTime" 
                        lineItem.id = Long.valueOf(dartAds.getAdId());
    
                        DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
                        filterItem.query = 'WHERE id=' + lineItem.id;
                        DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
    
                        if (itemPage.totalResultSetSize>0) {
                            for (DART6_LINEITEMSERVICE.LineItem qItem: itemPage.results) {
                                // 1 - check StartDateTime
                                // Set<String>statuses = new Set<String>{
                                //     'READY',
                                //     'DELIVERING',
                                //     'COMPLETED'
                                // };
                                if (LINEITEM_STATUSES.contains(qItem.status) || dartAds.getStartDateTime() < system.now()) lineItem.startDateTime = qItem.startDateTime;
                                else startDateUpdatable = true;
                                // 2 - check Type
                                if (LINEITEM_STATUSES.contains(qItem.status)) lineItem.lineItemType = qItem.lineItemType;
                            }
                        }
                    } catch (System.CalloutException cex) {
                        throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                    }
                }
    
                if (dartAds.getStartDateTime() < system.now() && (String.isBlank(dartAds.getAdId()) || startDateUpdatable)) {
                    lineItem.startDateTimeType = 'IMMEDIATELY';
                }
    
                if (dartOrder != null) {
                    lineItem.orderId = Long.valueOf(dartOrder.getDartId());
                }
            }


            lineItem.targeting = itemTargeting;
            propLineItem.targeting = itemTargeting;

            iniatValues(dartAds, null, lineItem, propLineItem);  // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem
            setCostPerUnit(dartAds, lineItem, propLineItem);
            if(!isProposal){setCustomFields(dartAds, lineItem, login);}
             // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem
            setDartCreative(dartAds, null, lineItem, propLineItem, login);
            setFreqCaps(dartAds, null, lineItem, propLineItem);
            System.debug('>>>> Cost Type ' + lineItem.costType);

            if(isProposal){ //US-0011408
                DART6_LINEITEMSERVICE.RequestPlatformTargeting requestPlat = new DART6_LINEITEMSERVICE.RequestPlatformTargeting();
                requestPlat.targetedRequestPlatforms = new String[]{STR_BROWSER.toUpperCase()};
                propLineItem.targeting.requestPlatformTargeting = requestPlat;
                propLineItem.environmentType = STR_BROWSER.toUpperCase();
            } //US-0011408

            try {

                if(isProposal){
                    
                    if (String.isBlank(dartAds.getAdId())) {
                        invokedMethod = 'Create ProposalLineItems';
                        try {
                            List<DART6_LINEITEMSERVICE.ProposalLineItem>lstItemResp = propLineItemService.createProposalLineItems(new List<DART6_LINEITEMSERVICE.ProposalLineItem>{
                                propLineItem
                            });
                            if (!lstItemResp.isEmpty()) dfpPropLineItemResponse = lstItemResp.get(0);
                        } catch (System.CalloutException cex) {
                            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                    } else { // Update LineItem  

                        invokedMethod = 'UpdateProposalLineItems';
                        try {
                            List<DART6_LINEITEMSERVICE.ProposalLineItem>listItemsTobeUpdated = propLineItemService.updateProposalLineItems(new List<DART6_LINEITEMSERVICE.ProposalLineItem>{
                                propLineItem
                            });
                            if (!listItemsTobeUpdated.isEmpty()) dfpPropLineItemResponse = listItemsTobeUpdated.get(0);

                        } catch (System.CalloutException cex) {
                            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                    }

                }else{

                    if (String.isBlank(dartAds.getAdId())) {
                        invokedMethod = 'Create LineItem/Ads';
                        try {
                            List<DART6_LINEITEMSERVICE.LineItem>lstItemResp = lineItemService.createLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{
                                lineItem
                            });
                            if (!lstItemResp.isEmpty()) dfpLineItemResponse = lstItemResp.get(0);
                        } catch (System.CalloutException cex) {
                            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                    } else { // Update LineItem  
    
                        invokedMethod = 'Update LineItem/Ads';
                        try {
                            List<DART6_LINEITEMSERVICE.LineItem>listItemsTobeUpdated = lineItemService.updateLineItems(new List<DART6_LINEITEMSERVICE.LineItem>{
                                lineItem
                            });
                            if (!listItemsTobeUpdated.isEmpty()) dfpLineItemResponse = listItemsTobeUpdated.get(0);
    
                        } catch (System.CalloutException cex) {
                             throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                        }
                    }
                }

            } catch (System.CalloutException cex) {
                throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
            } catch (Exception ex) {
                //throw new ExceptionGroup.DARTException(ex.getMessage() + ' : ' + ex.getStackTraceString());
                throw new ExceptionGroup.DARTException(ex.getMessage());
            }
        }

        public Object getResponseObject() {
            if(isProposal){
                return dfpPropLineItemResponse;
            }else{
                return dfpLineItemResponse;
            }
        }

    }


    /**
     * @description request ot DFP to get Forecast 
     */
    public class DFPForecastRequest extends AbstractDFPRequest {

        List<String>adIds;
        QuoteLineItem item;
        DARTObject.DARTForecast dartObjForecast;

        public DART6_FORECASTSERVICE.AvailabilityForecast forecast;

        public DFPForecastRequest(QuoteLineItem item) {
            this.item = item;
        }

        public void invoke() {

            DART6_KeyValueController ctrl;
            List<DART6_FORECASTSERVICE.CustomCriteriaSet>listCrit = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();

            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, item.priceBookEntry.Product2.Site__r.Name); //NK:21/04/2021
            String authToken = DARTUtil.getAccessToken(login);
            DART6_FORECASTSERVICE.SoapRequestHeader header = new DART6_FORECASTSERVICE.SoapRequestHeader();

            header.applicationName = 'ForecastService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_FORECASTSERVICE.ForecastServiceInterfacePort forecastService = new DART6_FORECASTSERVICE.ForecastServiceInterfacePort();
            forecastService.RequestHeader = header;
            forecastService.inputHttpHeaders_x = inputHttpHeaders_x;

            if (item != null) {
                String strFCErr = '';

                dartObjForecast = new DARTObject.DARTForecast(item);

                //customTargeting
                ctrl = new DART6_KeyValueController(item.PricebookEntry.Product2.Site__r.Id, dartObjForecast.getKeyWKV(), authToken, login.Network_ID__c);

                if (ctrl.isNeedToCreate()) {
                    ctrl.searchCreateDFPFreeFormValues();
                }
                listCrit = (List<DART6_FORECASTSERVICE.CustomCriteriaSet>) ctrl.getListDart();




                //DART6_FORECASTSERVICE.Location
                List<DART6_FORECASTSERVICE.Location>lstLocations = new List<DART6_FORECASTSERVICE.Location>();

                for (Geography__c g: dartObjForecast.getIncludeGeography()) {
                    DART6_FORECASTSERVICE.Location loc = new DART6_FORECASTSERVICE.Location();
                    loc.id = Long.valueOf(g.Dart_ID__c + '');
                    loc.type_x = g.Type__c;
                    lstLocations.add(loc);
                }

                //DART6_FORECASTSERVICE.GeoTargeting
                DART6_FORECASTSERVICE.GeoTargeting geoTargeting = new DART6_FORECASTSERVICE.GeoTargeting();
                geoTargeting.targetedLocations = lstLocations;

                DART6_FORECASTSERVICE.BandwidthGroupTargeting bandwidthGroupTargeting = null;
                DART6_FORECASTSERVICE.MobileCarrierTargeting mobileCarrierTargeting = null;
                DART6_FORECASTSERVICE.Technology[] listBandWidth = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] techMobileCar = new List<DART6_FORECASTSERVICE.Technology>();
                Set<Id> connIds = new Map<id, Connection__c> (dartObjForecast.getIncludeConnection()).keySet();

                List<Connection__c>  conns = [select id, name, DFP_API_Name__c, Node_ID__c, Dart_ID__c from connection__c WHERE node_id__r.id in: connIds or node_id__r.node_id__r.id in: connIds or id in: connIds];
                Set<Id> parentIds = new Set<Id> ();
                for (Connection__c c: conns) {
                    parentIds.add(c.Node_ID__c);
                }

                for (Connection__c c: conns) {
                    boolean isParent = parentIds.contains(c.Id);
                    if ((STR_BANDWIDTH_GROUP).equals(c.DFP_API_Name__c) && !isParent) {
                        DART6_FORECASTSERVICE.Technology technologyBw = new DART6_FORECASTSERVICE.Technology();
                        technologyBw.id = c.Dart_ID__c.longValue();
                        listBandWidth.add(technologyBw);
                    } else if ((STR_MOBILE_CARRIER).equals(c.DFP_API_Name__c) && !isParent) {
                        DART6_FORECASTSERVICE.Technology techMb = new DART6_FORECASTSERVICE.Technology();
                        techMb.id = c.Dart_ID__c.longValue();
                        techMobileCar.add(techMb);

                    }
                }

                if (!listBandWidth.isEmpty()) {
                    bandwidthGroupTargeting = new DART6_FORECASTSERVICE.BandwidthGroupTargeting();
                    bandwidthGroupTargeting.bandwidthGroups = listBandWidth;
                }

                if (!techMobileCar.isEmpty()) {
                    mobileCarrierTargeting = new DART6_FORECASTSERVICE.MobileCarrierTargeting();
                    mobileCarrierTargeting.mobileCarriers = techMobileCar;
                }

                // -------------------------->> Device Targeting <<--------------------------------
                DART6_FORECASTSERVICE.Technology[] listBrowsing = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listBrowsingLang = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listDeviceCap = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listDeviceCategory = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listDeviceManufacturer = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listOpSys = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listOpSysVersion = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listMobileDevice = new List<DART6_FORECASTSERVICE.Technology>();
                DART6_FORECASTSERVICE.Technology[] listMobileDeviceSubMod = new List<DART6_FORECASTSERVICE.Technology>();


                //Targeting Device from targeting tree
                for (Devices__c d: dartObjForecast.getIncludeDevice()) {
                    if ((STR_BROWSER).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techBrw = new DART6_FORECASTSERVICE.Technology();
                        techBrw.id = d.Dart_ID__c.longValue();
                        listBrowsing.add(techBrw);
                    } else if ((STR_BROWSER_LANGUAGE).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techBrwLang = new DART6_FORECASTSERVICE.Technology();
                        techBrwLang.id = d.Dart_ID__c.longValue();
                        listBrowsingLang.add(techBrwLang);
                    } else if ((STR_DEVICE_CAPABILITY).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techDevCap = new DART6_FORECASTSERVICE.Technology();
                        techDevCap.id = d.Dart_ID__c.longValue();
                        listDeviceCap.add(techDevCap);
                    } else if ((STR_DEVICE_MANUFACTURER).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techDevMf = new DART6_FORECASTSERVICE.Technology();
                        techDevMf.id = d.Dart_ID__c.longValue();
                        listDeviceManufacturer.add(techDevMf);
                    } else if ((STR_OPERATING_SYSTEM).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techOs = new DART6_FORECASTSERVICE.Technology();
                        techOs.id = d.Dart_ID__c.longValue();
                        listOpSys.add(techOs);
                    } else if ((STR_OPERATING_SYSTEM_VERSION).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techOsVersion = new DART6_FORECASTSERVICE.Technology();
                        techOsVersion.id = d.Dart_ID__c.longValue();
                        listOpSysVersion.add(techOsVersion);
                    } else if ((STR_MOBILE_DEVICE).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techMobileDev = new DART6_FORECASTSERVICE.Technology();
                        techMobileDev.id = d.Dart_ID__c.longValue();
                        listMobileDevice.add(techMobileDev);
                    } else if ((STR_MOBILE_DEVICE_SUBMODEL).equals(d.DFP_API_Name__c) && d.Dart_ID__c != null) {
                        DART6_FORECASTSERVICE.Technology techMobileDevSubMd = new DART6_FORECASTSERVICE.Technology();
                        techMobileDevSubMd.id = d.Dart_ID__c.longValue();
                        listMobileDeviceSubMod.add(techMobileDevSubMd);
                    }
                }

                // DART6_FORECASTSERVICE.BrowserTargeting
                DART6_FORECASTSERVICE.BrowserTargeting browserTargeting = null;
                if (!listBrowsing.isEmpty()) {
                    browserTargeting = new DART6_FORECASTSERVICE.BrowserTargeting();
                    browserTargeting.browsers = listBrowsing;
                }

                // DART6_FORECASTSERVICE.BrowserLanguageTargeting
                DART6_FORECASTSERVICE.BrowserLanguageTargeting browserLanguageTargeting = null;
                if (!listBrowsingLang.isEmpty()) {
                    browserLanguageTargeting = new DART6_FORECASTSERVICE.BrowserLanguageTargeting();
                    browserLanguageTargeting.browserLanguages = listBrowsingLang;
                }

                // DART6_FORECASTSERVICE.DeviceCapabilityTargeting
                DART6_FORECASTSERVICE.DeviceCapabilityTargeting deviceCapabilityTargeting = null;
                if (!listDeviceCap.isEmpty()) {
                    deviceCapabilityTargeting = new DART6_FORECASTSERVICE.DeviceCapabilityTargeting();
                    deviceCapabilityTargeting.targetedDeviceCapabilities = listDeviceCap;
                }

                //DART6_FORECASTSERVICE.DeviceCategoryTargeting
                DART6_FORECASTSERVICE.DeviceCategoryTargeting deviceCategoryTargeting = null;
                if (!listDeviceCategory.isEmpty()) {
                    deviceCategoryTargeting = new DART6_FORECASTSERVICE.DeviceCategoryTargeting();
                    deviceCategoryTargeting.targetedDeviceCategories = listDeviceCategory;
                }

                //DART6_FORECASTSERVICE.DeviceManufacturerTargeting ;
                DART6_FORECASTSERVICE.DeviceManufacturerTargeting deviceManufacturerTargeting = null;
                if (!listDeviceManufacturer.isEmpty()) {
                    deviceManufacturerTargeting = new DART6_FORECASTSERVICE.DeviceManufacturerTargeting();
                    deviceManufacturerTargeting.deviceManufacturers = listDeviceManufacturer;
                }

                //DART6_FORECASTSERVICE.OperatingSystemTargeting
                DART6_FORECASTSERVICE.OperatingSystemTargeting OperatingSystemTargeting = null;
                if (!listOpSys.isEmpty()) {
                    OperatingSystemTargeting = new DART6_FORECASTSERVICE.OperatingSystemTargeting();
                    OperatingSystemTargeting.operatingSystems = listOpSys;
                }

                //DART6_FORECASTSERVICE.OperatingSystemVersionTargeting
                DART6_FORECASTSERVICE.OperatingSystemVersionTargeting operatingSystemVersionTargeting = null;
                if (!listOpSysVersion.isEmpty()) {
                    operatingSystemVersionTargeting = new DART6_FORECASTSERVICE.OperatingSystemVersionTargeting();
                    operatingSystemVersionTargeting.targetedOperatingSystemVersions = listOpSysVersion;
                }

                //DART6_FORECASTSERVICE.MobileDeviceTargeting
                DART6_FORECASTSERVICE.MobileDeviceTargeting mobileDeviceTargeting = null;
                if (!listMobileDevice.isEmpty()) {
                    mobileDeviceTargeting = new DART6_FORECASTSERVICE.MobileDeviceTargeting();
                    mobileDeviceTargeting.targetedMobileDevices = listMobileDevice;
                }

                //DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting
                DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting mobileDeviceSubmodelTargeting = null;
                if (!listMobileDeviceSubMod.isEmpty()) {
                    mobileDeviceSubmodelTargeting = new DART6_FORECASTSERVICE.MobileDeviceSubmodelTargeting();
                    mobileDeviceSubmodelTargeting.targetedMobileDeviceSubmodels = listMobileDeviceSubMod;
                }

                //TechnologyTargeting
                DART6_FORECASTSERVICE.TechnologyTargeting technologyTargeting = new DART6_FORECASTSERVICE.TechnologyTargeting();


                if (browserTargeting != null) {
                    technologyTargeting.browserTargeting = browserTargeting;
                }

                if (bandwidthGroupTargeting != null) {
                    technologyTargeting.bandwidthGroupTargeting = bandwidthGroupTargeting;
                }

                if (mobileCarrierTargeting != null) {
                    technologyTargeting.mobileCarrierTargeting = mobileCarrierTargeting;
                }

                if (browserTargeting != null) {
                    technologyTargeting.browserTargeting = browserTargeting;
                }

                if (browserLanguageTargeting != null) {
                    technologyTargeting.browserLanguageTargeting = browserLanguageTargeting;
                }

                if (deviceCapabilityTargeting != null) {
                    technologyTargeting.deviceCapabilityTargeting = deviceCapabilityTargeting;
                }

                if (deviceCategoryTargeting != null) {
                    technologyTargeting.deviceCategoryTargeting = deviceCategoryTargeting;
                }

                if (deviceManufacturerTargeting != null) {
                    technologyTargeting.deviceManufacturerTargeting = deviceManufacturerTargeting;
                }

                if (OperatingSystemTargeting != null) {
                    technologyTargeting.OperatingSystemTargeting = OperatingSystemTargeting;
                }

                if (operatingSystemVersionTargeting != null) {
                    technologyTargeting.operatingSystemVersionTargeting = operatingSystemVersionTargeting;
                }

                if (mobileDeviceTargeting != null) {
                    technologyTargeting.mobileDeviceTargeting = mobileDeviceTargeting;
                }

                if (mobileDeviceSubmodelTargeting != null) {
                    technologyTargeting.mobileDeviceSubmodelTargeting = mobileDeviceSubmodelTargeting;
                }


                //NK:29/01/2013----------------------------


                //DayPart
                List<DART6_FORECASTSERVICE.DayPart>lstDayParts = new List<DART6_FORECASTSERVICE.DayPart>();

                // Pheaktra Hun: 31-Aug-2016. For Time Targeting with different hours on different days
                for (DARTObject.DTOTimeTargeting dto: dartObjForecast.getListDTOTimeTargeting()) {
                    for (String hour: dto.hours) { // Ex: dto.hours = ('0:00 - 0:59', '1:00 - 1:59')
                        List<String>lsthd = hour.split('-'); // (0:00, 0:59)
                        List<String>lstTimeStart = lsthd[0].split(':'); //(0, 00)
                        List<String>lstTimeEnd = lsthd[1].split(':'); // (0, 59)

                        DART6_FORECASTSERVICE.TimeOfDay startTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                        startTimeOfDay.hour = Integer.valueOf(lstTimeStart[0].trim() + '');
                        startTimeOfDay.minute = STR_ZERO;

                        DART6_FORECASTSERVICE.TimeOfDay endTimeOfDay = new DART6_FORECASTSERVICE.TimeOfDay();
                        endTimeOfDay.hour = Integer.valueOf(lstTimeEnd[0].trim() + '') + 1;
                        endTimeOfDay.minute = STR_ZERO;

                        DART6_FORECASTSERVICE.DayPart dayPart = new DART6_FORECASTSERVICE.DayPart();
                        dayPart.dayOfWeek = dto.day.toUpperCase();
                        dayPart.startTime = startTimeOfDay;
                        dayPart.endTime = endTimeOfDay;

                        lstDayParts.add(dayPart);
                    }
                }


                // Targeting
                DART6_FORECASTSERVICE.Targeting itemTargeting = new DART6_FORECASTSERVICE.Targeting();
                setTargetings(dartObjForecast, login, item, itemTargeting);

                itemTargeting.geoTargeting = geoTargeting;

                if (lstDayParts.size()>0) {
                    DART6_FORECASTSERVICE.DayPartTargeting dayPartTargeting = new DART6_FORECASTSERVICE.DayPartTargeting();
                    dayPartTargeting.dayParts = lstDayParts;
                    dayPartTargeting.timeZone = STR_BROWSER;
                    itemTargeting.dayPartTargeting = dayPartTargeting;
                }

                itemTargeting.technologyTargeting = technologyTargeting;
                if (listCrit.size()>0) {
                    itemTargeting.customTargeting = listCrit.get(0);
                }
                system.debug('customTargeting' + itemTargeting.customTargeting);
                //-----------------12-11-2013----------------------------
                List<String>lstAdSlotWH_FORECASTSERVICE = new List<String>();
                List<DART6_FORECASTSERVICE.CreativePlaceholder>listCreativePLC_FORECASTSERVICE = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();

                lstAdSlotWH_FORECASTSERVICE = dartObjForecast.getListAdSlotWH(); // lstAdSlotHW{120x600,160x600};
                //Get native style from custom setting
                Map<String, DART_NativeStylesMapper__c> mNativeStyles = DART_NativeStylesMapper__c.getAll();
                for (String slotWH_FORECASTSERVICE: lstAdSlotWH_FORECASTSERVICE) {

                    DART6_FORECASTSERVICE.CreativePlaceholder creativePlc = new DART6_FORECASTSERVICE.CreativePlaceholder();

                    DART6Message.setSize(creativePlc, slotWH_FORECASTSERVICE, login.Network_ID__c, mNativeStyles);
                    listCreativePLC_FORECASTSERVICE.add(creativePlc);
                }
                //---------------------12-11-2013----------------------------------                   


                DART6_FORECASTSERVICE.LineItem lineItem = new DART6_FORECASTSERVICE.LineItem();
                setStartEndDate(dartObjForecast, lineItem, null, null, login); // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem
                lineItem.targeting = itemTargeting;
                // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem :
                iniatValues(dartObjForecast, lineItem, null, null);
                setTypeAndPrimaryGoal(dartObjForecast, lineItem, null, null);
                setFreqCaps(dartObjForecast, lineItem, null, null);
                setDartCreative(dartObjForecast, lineItem, null, null, login);

                try {
                    DART6_FORECASTSERVICE.ProspectiveLineItem prospectiveItem = new DART6_FORECASTSERVICE.ProspectiveLineItem();
                    if (lineItem.lineItemType != 'SPONSORSHIP') lineItem.lineItemType = 'STANDARD'; //MN-20042021-US-0009350 - "Forecast only available for STANDARD & SPONSORSHIP
                    prospectiveItem.LineItem = lineItem;
                    DART6_FORECASTSERVICE.AvailabilityForecastOptions availabilityFcOpt = new DART6_FORECASTSERVICE.AvailabilityForecastOptions();
                    availabilityFcOpt.includeTargetingCriteriaBreakdown = true;
                    availabilityFcOpt.includeContendingLineItems = true;
                    //Get forecast
                    forecast = forecastService.getAvailabilityForecast(prospectiveItem, availabilityFcOpt);
                    invokedMethod = 'getForecast';
                    if (listCrit.size()>0) {
                        ctrl.updateDart6ValueIds();
                    }
                    if (ctrl.isCreateNewKv()) {
                        ctrl.createObjectKeyVal();
                    }
                } catch (System.CalloutException cex) {
                    throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
                } catch (Exception ex) {
                    throw new ExceptionGroup.DARTException(ex.getStackTraceString() + '' + ex.getMessage());
                }
            }
        }

        public Object getResponseObject() {
            return forecast;
        }

    }

    /**
     * @description delivery Request
     * AdServer_Login__c login = DARTUtil.getCredential('DART5','UK');
     */
    public class DeliveryRequest extends AbstractDFPRequest {
        private DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService;
        private Long reportjobId;
        private String xmlBody;
        private AdServer_Login__c credential;

        public DeliveryRequest(AdServer_Login__c credential, Long reportjobId, DART6_REPORTSERVICE.REPORTServiceInterfacePort reportService) {
            this.reportjobId = reportjobId;
            this.reportService = reportService;
            this.credential = credential;
        }

        /** Download report from url when running completed */
        public void invoke() {
            DART6_REPORTSERVICE.ReportDownloadOptions reportOptions = new DART6_REPORTSERVICE.ReportDownloadOptions();
            
            // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
            // EU is using CSV_DUMP
            // reportOptions.exportFormat = 'XML';
            reportOptions.exportFormat = 'CSV_DUMP';

            reportOptions.includeReportProperties = false;
            reportOptions.includeTotalsRow = false;
            reportOptions.useGzipCompression = false;
            String downloadUrl = reportService.getReportDownloadUrlWithOptions(reportjobId, reportOptions);
            System.debug('downloadUrl===>  : ' + downloadUrl);
            HTTPWrapper.IRequest downloadxmlReq = new DART6Message.DART6ReportDownloadRequest(credential, downloadUrl);
            DART6Message.GenericResponse downloadxmlResponse = new DART6Message.GenericResponse(downloadxmlReq);
            xmlBody = downloadxmlResponse.getResBody();
        }

        public Object getResponseObject() {
            return xmlBody;
        }
    }

    /** @description request to download report */
    public class DART6ReportDownloadRequest extends AbstractDART6Request {

        public DART6ReportDownloadRequest(AdServer_Login__c credential, String url) {
            super(credential);
            endPoint = url;
            method = 'GET';
            //new request to download report no need content-type
            //mapHeader.put('Content-type', 'text/xml');
            //constructBody();
        }
        protected override void composeHeader() {}
        public override void constructBody() {}
    }

    public class DART6TokenRequest extends AbstractDART6Request {
        public DART6TokenRequest(AdServer_Login__c credential) {
            super(credential);
            endPoint = DARTUtil.CLIENT_AUTH_URL;
        }
        public override void constructBody() {
            reqBody = 'service=gam&accountType=GOOGLE&' + 'Email=' + credential.User_Name__c + '&Passwd=' + credential.Password__c;
        }
    }



    /*------Add new after remove DART5Message -----*/
    public abstract class AbstractDARTRequest implements HTTPWrapper.IGenericRequest {
        protected String invokedMethod = '';
        public String getInvokedMethod() {
            return invokedMethod;
        }
    }

    public abstract class AbstractDART6Request extends AbstractDARTRequest implements HTTPWrapper.IRequest {
        protected Map<String, String> mapHeader;
        protected String reqBody = '';
        protected String endPoint = '';
        protected String method = 'POST';

        protected AdServer_Login__c credential;

        public AbstractDART6Request(AdServer_Login__c credential) {
            this.credential = credential;
            endPoint = credential.Login_URL__c;
            mapHeader = new Map<String, String> ();
            composeHeader();
        }

        protected virtual void composeHeader() {
            //mapHeader.put('Cookie','');
            //mapHeader.put('Content-type','text/xml');
            //mapHeader.put('Accept-Encoding','gzip, deflate');
            //mapHeader.put('User-Agent','API_VERSION_DARTAPI_13.6.9 JRE_1.6.0_25');
            //String authsss = DARTUtil.composeDigestAuthorizationHeader(credential.User_Name__c,credential.Password__c,'/xmlserver/','POST');
            //mapHeader.put('Authorization',authsss);
        }

        abstract void constructBody();

        public String getEndPoint() {
            return endPoint;
        }
        public Map<String, String> getHeader() {
            return mapHeader;
        }
        public String getBody() {
            return reqBody;
        }
        public String getMethod() {
            return method;
        }
    }

    public class GenericResponse extends HTTPWrapper.AbstractResponse {
        public GenericResponse(IRequest req) {
            super(req);
            excecute();
        }
        public override String getMockedBody() {
            return DARTMockUp.generateDart6Response(request);
        }
    }

    /** 
     * @createdDate 15-06-2015
     * @description request to DFP to get some fields of lineItem by AdIds
     *      Start Time --> save in externalFromDate__c
     *      End Time --> save in externalEndDate__c
     *      Quantity --> save in externalQuantity__c
     *      Rate type --> save in externalBillngCategory__c
     *      Rate --> save in externalSalesPrice__c
     */

    public class DFPGetLineItemRequestById extends AbstractDFPRequest {

        DART6_LINEITEMSERVICE.LineItem dfpItem;
        OpportunityLineItem item;
        public DFPGetLineItemRequestById(OpportunityLineItem item) {
            this.item = item;
        }

        public void invoke() {

            AdServer_Login__c login = DARTUtil.getCredential(DARTUtil.DART6, item.PriceBookEntry.Product2.Site__r.Country__c);
            String authToken = DARTUtil.getAccessToken(login); // new version 201405

            DART6_LINEITEMSERVICE.SoapRequestHeader header = new DART6_LINEITEMSERVICE.SoapRequestHeader();
            header.applicationName = 'LineItemService';
            header.networkCode = login.Network_ID__c;

            Map<String, String> inputHttpHeaders_x = new Map<String, String> ();
            inputHttpHeaders_x.put('Authorization', 'Bearer ' + authToken);

            DART6_LINEITEMSERVICE.LineItemServiceInterfacePort lineItemService = new DART6_LINEITEMSERVICE.LineItemServiceInterfacePort();
            lineItemService.RequestHeader = header;
            lineItemService.timeout_x = 120000;
            lineItemService.inputHttpHeaders_x = inputHttpHeaders_x;

            String querySt = 'WHERE Id = ' + item.Ad_Id__c + '';

            // Get LineItem
            DART6_LINEITEMSERVICE.Statement filterItem = new DART6_LINEITEMSERVICE.Statement();
            filterItem.query = querySt;
            List<DART6_LINEITEMSERVICE.LineItem>lstItems = new List<DART6_LINEITEMSERVICE.LineItem>();
            DART6_LINEITEMSERVICE.LineItemPage itemPage = lineItemService.getLineItemsByStatement(filterItem);
            if (itemPage.totalResultSetSize>0) {
                for (DART6_LINEITEMSERVICE.LineItem itemRes: itemPage.results) {
                    lstItems.add(itemRes);
                }
            }
            if (!lstItems.isEmpty()) dfpItem = lstItems.get(0);
            invokedMethod = 'getLineItemById';

        }

        public Object getResponseObject() {
            return dfpItem;
        }
    }
    /**
     * @createdDate: 15-12-2016
     * @return Mapping DFP message & friendly message
     */
    public static Map<String, String> getMapFriendlyMsg() {
        List<DFP_Message_Error__c> allDFPMsgErr = DFP_Message_Error__c.getall().values();
        Map<String, String> mapMsg = new Map<String, String> ();
        for (DFP_Message_Error__c cus: allDFPMsgErr) {
            mapMsg.put(cus.DFP_Message__c, cus.Friendly_Message__c);
        }
        return mapMsg;
    }


    private static void setSize(DART6_FORECASTSERVICE.CreativePlaceholder holder, String adSlot, String networkId, Map<String, DART_NativeStylesMapper__c> mNativeStyleSetting) {
        DART6_FORECASTSERVICE.Size itemSize = new DART6_FORECASTSERVICE.Size();
        itemSize.isAspectRatio = false;

        // Check if Native style
        if (!adSlot.replace('x', '').trim().isNumeric()) {
            DART_NativeStylesMapper__c nativeSetting = mNativeStyleSetting.get(networkId + adSlot);
            if (nativeSetting == null || nativeSetting.DART_CreativeTemplateId__c == null) throw new ExceptionGroup.DARTException('Native Style Configure is required for "' + adSlot + '"');

            //Native size, which is a function of the how the client renders the creative. This must be used with 1x1 size.
            holder.creativeSizeType = 'NATIVE';
            holder.creativeTemplateId = nativeSetting.DART_CreativeTemplateId__c.longValue();
            itemSize.width = 1;
            itemSize.height = 1;
        } else {
            String ww = adSlot.split('x')[0];
            String hh = adSlot.split('x')[1];
            itemSize.width = (('').equals(ww) ? 0 : Integer.valueOf(ww + ''));
            itemSize.height = (('').equals(hh) ? 0 : Integer.valueOf(hh + ''));
        }
        holder.size = itemSize;
    }


    static void iniatValues(DARTObject.DARTForecast dartAds, DART6_FORECASTSERVICE.LineItem foreItem, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem) {
        if (foreItem == null) foreItem = new DART6_FORECASTSERVICE.LineItem();
        if (lineItem == null) lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if (propLineItem == null) propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem(); // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem

        // Forecast, Lineitem, Proposoal Lineitem
        foreItem.deliveryRateType = 'EVENLY';
        lineItem.deliveryRateType = 'EVENLY';
        propLineItem.deliveryRateType = 'EVENLY';

        foreItem.creativeRotationType = 'EVENLY';
        lineItem.creativeRotationType = 'EVENLY';
        // propLineItem.creativeRotationType = 'EVENLY';
        foreItem.costType = MAP_COST_TYPES.get(dartAds.getBillingCat());
        lineItem.costType = foreItem.costType;
        propLineItem.rateType = foreItem.costType;
        System.debug('>>>> Cost Type ' + lineItem.costType);

        // only lineItem
        lineItem.priority = dartAds.getPriority();
        lineItem.allowOverbook = true; // Chr: 11-07-2014: set to avoid error NOT_ENOUGH_INVENTORY
        lineItem.notes = dartAds.getAdOpsComments(); // Chr: 30-11-2015 pushing Ad Ops Comment to lineItem
        lineItem.name = dartAds.getName();

        // only proposal lineitem
        propLineItem.lineItemPriority = dartAds.getPriority();
        // propLineItem.allowOverbook = true;
        propLineItem.internalNotes = dartAds.getAdOpsComments();
        propLineItem.name = dartAds.getName();
    }

    static void setCustomFields(DARTObject.DARTAds dartAds, DART6_LINEITEMSERVICE.LineItem lineItem, AdServer_Login__c login) {
        if (String.isNotBlank(login.ExternalLineDescriptionId__c)) {
            DART6_LINEITEMSERVICE.TextValue custVal = new DART6_LINEITEMSERVICE.TextValue();
            custVal.value = dartAds.getLineDesc();
            custVal.type_x = 'TextValue';

            DART6_LINEITEMSERVICE.CustomFieldValue custFldVal = new DART6_LINEITEMSERVICE.CustomFieldValue();
            custFldVal.customFieldId = Long.valueOf(login.ExternalLineDescriptionId__c);
            custFldVal.type_x = 'CustomFieldValue';
            custFldVal.value = custVal;
            lineItem.customFieldValues = new List<DART6_LINEITEMSERVICE.BaseCustomFieldValue>{
                custFldVal
            };
        }
    }

    // Bunhor 20-Jun-18: Review DPF Creative and Optimized
    static void setDartCreative(DARTObject.DARTForecast dObj, DART6_FORECASTSERVICE.LineItem foreItem, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem,AdServer_Login__c login) {
        if (foreItem == null) foreItem = new DART6_FORECASTSERVICE.LineItem();
        if (lineItem == null) lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if (propLineItem == null) propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem(); // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem

        String dartProType = dObj.getDartProductType();
        String[] slots = dObj.getListAdSlotWH();
        if (dartProType == INVENTORY_SIZE_TYPE_COM || dartProType == INVENTORY_SIZE_TYPE_VID) { // -- Master/companion roadblock --- --- Video VAST ---
            if (dartProType == INVENTORY_SIZE_TYPE_VID) {
                foreItem.EnvironmentType = 'VIDEO_PLAYER';
                lineItem.EnvironmentType = 'VIDEO_PLAYER';
                propLineItem.EnvironmentType = 'VIDEO_PLAYER';
            }
            foreItem.companionDeliveryOption = 'ALL';
            lineItem.companionDeliveryOption = 'ALL';
            propLineItem.companionDeliveryOption = 'ALL';
        } else { // --- Standard ---
            /* MN-16092021-US-0010346 - Changed it to ONE_OR_MORE instead
            foreItem.roadblockingType = 'ONLY_ONE';
            lineItem.roadblockingType = 'ONLY_ONE';
            */

            //MN-16092021-US-0010346 - Changed it to ONE_OR_MORE instead
            foreItem.roadblockingType = 'ONE_OR_MORE';
            lineItem.roadblockingType = 'ONE_OR_MORE';
            propLineItem.roadblockingType = 'ONE_OR_MORE';
        }

        Map<String, DART_NativeStylesMapper__c> mNativeStyleSetting = DART_NativeStylesMapper__c.getAll();
        List<DART6_FORECASTSERVICE.CreativePlaceholder>creatives = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();
        foreItem.creativePlaceholders = creatives;
        lineItem.creativePlaceholders = creatives;
        propLineItem.creativePlaceholders = creatives;

        for (String s: slots) {
            DART6_FORECASTSERVICE.CreativePlaceholder creative = new DART6_FORECASTSERVICE.CreativePlaceholder();
            DART6Message.setSize(creative, s, login.Network_ID__c, mNativeStyleSetting);
            creatives.add(creative);
        }
        if (dartProType == INVENTORY_SIZE_TYPE_COM || dartProType == INVENTORY_SIZE_TYPE_VID) {
            for (DART6_FORECASTSERVICE.CreativePlaceholder master: creatives) {
                List<DART6_FORECASTSERVICE.CreativePlaceholder>coms = new List<DART6_FORECASTSERVICE.CreativePlaceholder>();
                for (String s: dObj.getDartCompanionSize()) {
                    DART6_FORECASTSERVICE.CreativePlaceholder com = new DART6_FORECASTSERVICE.CreativePlaceholder();
                    DART6Message.setSize(com, s, login.Network_ID__c, mNativeStyleSetting);
                    coms.add(com);
                }
                master.companions = coms;
            }
        }
    }


    static void setStartEndDate(DARTObject.DARTForecast dartAds, DART6_FORECASTSERVICE.LineItem foreItem, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem, AdServer_Login__c login) {
        if (foreItem == null) foreItem = new DART6_FORECASTSERVICE.LineItem();
        if (lineItem == null) lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if (propLineItem == null) propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem(); // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem

        String networkTimezone = login.Timezone__c + '';

        // Start
        DART6_FORECASTSERVICE.Date_x datexStart = new DART6_FORECASTSERVICE.Date_x();
        datexStart.day = dartAds.getStartDateTime().dayGmt();
        datexStart.month = dartAds.getStartDateTime().monthGmt();
        datexStart.year = dartAds.getStartDateTime().yearGmt();

        DART6_FORECASTSERVICE.DateTime_x dartTimexStart = new DART6_FORECASTSERVICE.DateTime_x();
        dartTimexStart.date_x = datexStart;
        dartTimexStart.hour = 0;
        dartTimexStart.minute = 0;
        dartTimexStart.second = 0;
        dartTimexStart.timeZoneID = networkTimezone;


        // End
        DART6_FORECASTSERVICE.Date_x datexEnd = new DART6_FORECASTSERVICE.Date_x();
        datexEnd.day = dartAds.getEndDateTime().dayGmt();
        datexEnd.month = dartAds.getEndDateTime().monthGmt();
        datexEnd.year = dartAds.getEndDateTime().yearGmt();

        DART6_FORECASTSERVICE.DateTime_x dartTimexEnd = new DART6_FORECASTSERVICE.DateTime_x();
        dartTimexEnd.date_x = datexEnd;
        dartTimexEnd.hour = 23;
        dartTimexEnd.minute = 59;
        dartTimexEnd.second = 0;
        dartTimexEnd.timeZoneID = networkTimezone;

        foreItem.startDateTime = dartTimexStart;
        lineItem.startDateTime = dartTimexStart;
        propLineItem.startDateTime = dartTimexStart;

        foreItem.endDateTime = dartTimexEnd;
        lineItem.endDateTime = dartTimexEnd;
        propLineItem.endDateTime = dartTimexEnd;

        if (dartAds.getStartDateTime().isSameDay(System.today())) {
            foreItem.startDateTimeType = 'ONE_HOUR_FROM_NOW';
            lineItem.startDateTimeType = 'ONE_HOUR_FROM_NOW';
            // propLineItem.startDateTimeType = 'ONE_HOUR_FROM_NOW';
        }
    }

    static void setTypeAndPrimaryGoal(DARTObject.DARTForecast dartAds, DART6_FORECASTSERVICE.LineItem foreItem, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem) {
        if (foreItem == null) foreItem = new DART6_FORECASTSERVICE.LineItem();
        if (lineItem == null) lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if (propLineItem == null) propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem();

        String itemType = (dartAds.getBillingCat().equals(BILLING_CATE_FIX_PRICE) || dartAds.getBillingCat().equals('CPD')) ? 'SPONSORSHIP' : dartAds.getLineItemType();
        if (String.isBlank(itemType)) itemType = 'STANDARD';

        foreItem.lineItemType = itemType;
        lineItem.lineItemType = itemType;
        propLineItem.lineItemType = itemType; // 01.12.2021 / Sophal Noch / US-0009927

        if (String.isNotBlank(dartAds.getQuantity())) {
            DART6_FORECASTSERVICE.Goal gl = new DART6_FORECASTSERVICE.Goal();
            gl.unitType = ('CPC'.equals(dartAds.getBillingCat()) ? 'CLICKS' : 'IMPRESSIONS');
            if ((LINEITEM_TYPE_NETWORK.equals(itemType) || LINEITEM_TYPE_HOUSE.equals(itemType) || LINEITEM_TYPE_SPONSERSHIP.equals(itemType))) {
                gl.unitType = 'IMPRESSIONS';
                gl.units = 100;
            } else {
                gl.units = Long.valueOf(dartAds.getQuantity());
            }
            foreItem.primaryGoal = gl;
            lineItem.primaryGoal = gl;
            propLineItem.goal = gl; // 01.12.2021 / Sophal Noch / US-0009927
        }

    }

    static void setFreqCaps(DARTObject.DARTForecast dartAds, DART6_FORECASTSERVICE.LineItem foreItem, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem) {
        List<DART6_FORECASTSERVICE.FrequencyCap>lstFQ = new List<DART6_FORECASTSERVICE.FrequencyCap>();
        if (!dartAds.getFrequencyCappings().isEmpty()) {
            for (TargetingFrequencyAssociation__c ass: dartAds.getFrequencyCappings()) {
                DART6_FORECASTSERVICE.FrequencyCap freq = new DART6_FORECASTSERVICE.FrequencyCap();
                freq.numTimeUnits = DARTUtil.toInteger(ass.FC_Ad_served_every__c);
                freq.maxImpressions = DARTUtil.toInteger(ass.FC_Quantity__c);
                freq.timeUnit = MAP_TIME_UNITS.get(ass.FC_Period__c);
                lstFQ.add(freq);
            }
        } else if (String.isNotBlank(dartAds.getFCPeriodDart6())) {
            DART6_FORECASTSERVICE.FrequencyCap freq = new DART6_FORECASTSERVICE.FrequencyCap();
            freq.numTimeUnits = DARTUtil.toInteger(dartAds.getFCAdServedEvery());
            freq.maxImpressions = DARTUtil.toInteger(dartAds.getFCQty());
            freq.timeUnit = MAP_TIME_UNITS.get(dartAds.getFCPeriodDart6());
            lstFQ.add(freq);
        }

        if (foreItem == null) foreItem = new DART6_FORECASTSERVICE.LineItem();
        if (lineItem == null) lineItem = new DART6_LINEITEMSERVICE.LineItem();
        if (propLineItem == null) propLineItem = new DART6_LINEITEMSERVICE.ProposalLineItem(); // 01.12.2021 / Sophal Noch / US-0009927 : modified to include proposal lineitem
        foreItem.frequencyCaps = lstFQ;
        lineItem.frequencyCaps = lstFQ;
        propLineItem.frequencyCaps = lstFQ;
    }

    static void setCostPerUnit(DARTObject.DARTForecast dartAds, DART6_LINEITEMSERVICE.LineItem lineItem, DART6_LINEITEMSERVICE.ProposalLineItem propLineItem) {
        DART6_LINEITEMSERVICE.Money money = new DART6_LINEITEMSERVICE.Money();
        money.currencyCode = dartAds.getCurrencyCode();
        if (String.isNotBlank(dartAds.getRate())) money.microAmount = Long.valueOf(dartAds.getRate());
        lineItem.costPerUnit = money;
        propLineItem.netRate = money;
    }

    static void setTargetings(DARTObject.DARTForecast dartObjForecast, AdServer_Login__c login, QuoteLineItem qitem, DART6_FORECASTSERVICE.Targeting itemTargeting) {

        List<DART6_FORECASTSERVICE.AdUnitTargeting>adUnitTargs = new List<DART6_FORECASTSERVICE.AdUnitTargeting>();
        for (Content__c predefined: dartObjForecast.getPredefinedAdunit()) {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = predefined.Name;
            adUnitTargs.add(adunit);
        }
        for (Content__c dartSite: dartObjForecast.getIncludeDartSite()) {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = dartSite.Name;
            adUnitTargs.add(adunit);
        }
        for (Content__c dartZone: dartObjForecast.getIncludeDartZone()) {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = dartZone.Name;
            adUnitTargs.add(adunit);
        }

        List<Long>placementIds = new List<Long>();
        for (Placement__c pPlacement: dartObjForecast.getIncludePlacementTarget()) {
            if (pPlacement.Dart_Id__c != null) placementIds.add(Long.valueOf(pPlacement.Dart_Id__c + ''));
        }

        DART6_FORECASTSERVICE.InventoryTargeting inventoryTargeting = new DART6_FORECASTSERVICE.InventoryTargeting();

        if (placementIds.isEmpty() && adUnitTargs.isEmpty()) {
            DART6_FORECASTSERVICE.AdUnitTargeting adunit = new DART6_FORECASTSERVICE.AdUnitTargeting();
            adunit.adUnitId = qitem.PricebookEntry.Product2.Site__r.Run_of_Network_ID__c;
            inventoryTargeting.targetedAdUnits = new List<DART6_FORECASTSERVICE.AdUnitTargeting>{
                adunit
            };
        } else {
            inventoryTargeting.targetedPlacementIds = placementIds;
            inventoryTargeting.targetedAdUnits = adUnitTargs;
        }

        itemTargeting.inventoryTargeting = inventoryTargeting;
    }

    
}