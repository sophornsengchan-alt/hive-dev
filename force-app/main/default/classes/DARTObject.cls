/**
 * Contains related SF & DFP fields
 * @: 18.09.2023 /Vimean Heng/US-0013941 - PART 3 - Upgrade API version of all classes having an API version lower than 31
 */
public with sharing class DARTObject {

    public final static String BILLING_CPM = 'CPM';
    public final static String BILLING_CPC = 'CPC';
    public final static String BILLING_CPD = 'CPD';

    public final static String DEL_FIELD_ADDELIVERED = 'AdDeliveredLifetime'; // lineitemLifetimeXfpImpressions
    public final static String DEL_FIELD_ADCLICKED_LIFETIME = 'AdClickedLifetime'; //lineitemLifetimeXfpClicks

    public final static String DEL_FIELD_ADOSI = 'AdOSI'; //mergeLineItemDeliveryIndicator                  //OSI (Lifetime)
    public final static String DEL_FIELD_ADID = 'AdId'; //lineItemId  
    public final static String DEL_FIELD_ORDERID = 'CampaignId'; //orderId
    public final static String DEL_FIELD_IMPRESS_DELIVERED = 'ImpressionsDelivered'; //mergeReservationImpressionsDelivered  //   Impressions Delivered  
    public final static String DEL_FIELD_CLICKS_DELIVERED = 'ClicksDelivered'; //mergeReservationClicksDelivered      //   Clicks Recorded 
    public final static String DEL_FIELD_DATE_OR_MONTH = 'dateormonth'; // date for RSD and month for RS

    //Chr: 22-08-2016 add other three columns for the import delviery
    public final static String DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS = 'AdActiveViewViewableImpression';
    public final static String DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS = 'AdActiveViewMeasurableImpression';
    public final static String DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE = 'AdActiveViewViewableImpressionRate';

    // 20-07-18 : Add bring more field from dfp 
    public final static String DEL_FIELD_TOTAL_LINE_ITEM_LEVEL_IMPRESSIONS = 'totalReservationImpressionsDelivered'; //eBayAds__Total_Impressions__c
    public final static String DEL_FIELD_TOTAL_LINE_ITEM_LEVEL_CLICKS = 'totalReservationClicksDelivered'; //eBayAds__Total_Clicks__c
    public final static String DEL_FIELD_AD_SERVER_CPM_AND_CPC_REVENUE = 'reservationPubCostDelivered'; //eBayAds__Actual_Revenue__c
    public final static String DEL_FIELD_AD_SERVER_LINE_ITEM_LEVEL_PERCENT_CLICKS = 'adServerReservationPercentClicksDelivered'; //eBayAds__Actual_Revenue__c
    public final static String DEL_FIELD_AD_SERVER_IMPRESSIONS = 'reservationImpressionsDelivered'; //eBayAds__Measurable_Impressions__c
    public final static String DEL_FIELD_AD_SERVER_CLICKS = 'reservationClicksDelivered'; //eBayAds__Viewable_Clicks__c
    public final static String DEL_FIELD_AD_SERVER_LINE_ITEM_LEVEL_PERCENT_IMPRESSIONS = 'adServerReservationPercentImpressionsDelivered'; //eBayAds__Viewable_Impressions_Rate__c

    //For Adx import
    public final static String ADX_FIELD_LEVEL_IMPRESSION = 'AdxImpression'; //adxReservationImpressionsDelivered
    public final static String ADX_FIELD_LEVEL_CLICK = 'AdxClick'; // adxReservationClicksDelivered
    public final static String ADX_FIELD_LEVEL_REVENUE = 'AdxRevenue'; // adxReservationPubCostDelivered


    public DARTObject() {}

    public interface IValidator {
        void checkError(Object o);
        List < String > getListError();
        Boolean isError();

    }

    public interface IDARTConnector {
        void connect();
        List < IDARTGenericObject > getDartObjects();

    }

    public virtual interface IDARTGenericObject {}

    public virtual interface IDARTObject extends IDARTGenericObject {
        String getDartId();
        String getTempId();
        String getDartName();

        void setTempId(String tmpId);
        void setDartName(String dartNme);
        void setDartId(String dartId);

        String getAssignAdserver();
        void setAssignAdserver(String assAdserver);

        String getDartErrMsg();
        void setDartErrMsg(String errMsg);
    }

    /** ----------- Advertiser/Company ------------- */
    public interface IDARTObjectAdvertiser extends IDARTObject {

        String getAccountId();
        String getAccountName();
        String getAccountRectName();

    }

    /** 
     * Order interface
     */
    public interface IDARTObjectOrder extends IDARTObject {

        String getPONumber();

        DARTPerson getPrimaryTrafficker();
        DARTPerson getSalepeople();

        void setPrimaryTrafficker(DARTPerson trafficker);
        void setSalePeople(DARTPerson speople);

        // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
        String getOppID();
        String getOppName();
        // -- END OF US-0007908
        String getOwnerId();

        String getOrderAvertiserId();
        void setAdvertiserId(String advertiserId);
    }
        /** 
     * Forecast Interface
     */

    public interface IDARTObjectForecast extends IDARTObject {
        String getForecastId();
        void setForecastId(String forecastId);

        String getOrderId();
        void setOrderId(String orderId);

        String getAvailableUnits();
        void setAvailableUnits(String avalUnit);

        String getMatchingUnits();
        void setMatchingUnits(String matchingUnit);
    }

    /** 
     * Ads(LineItem) interface
     */
    public interface IDARTObjectAds extends IDARTObject {
        IDARTObjectOrder getOrder();
        void setOrder(IDARTObjectOrder dartOrder);

        DateTime getStartDateTime();
        DateTime getEndDateTime();
        String getName();
        String getRate();
        String getLineItemId();
        String getProductName();
        String getAdId();
        String getStatus();
        String getCurrencyCode();
        Integer getPriority();

        //Fields for retrieve from DFP 
        DateTime getExternalFromDate();
        void setExternalFromDate(Date externalFromDate);
        DateTime getExternalEndDate();
        void setExternalEndDate(Date externalEndDate);
        Long getExternalQualilty();
        void setExternalQuality(Long externalQty);
        String getExternalBillingCategory();
        void setExternalBillingCategory(String externalBillingCat);
        Long getExternalSalePrice();
        void setExternalSalePrice(Long externalSalePrice);

    }

    /** 
     * Delivery interface
     */
    public interface IDARTObjectDelivery extends IDARTGenericObject {

        Integer getAdDelivered();
        Integer getImpressionsDelivered();
        Integer getAdClickedLifetime();
        Integer getClicksDelivered();
        Double getAdOSI();
        String getAdId();
        String getOrderId();
    }

    /** IDARTItem interface */

    public interface IDARTItem {

        String getProductName();
        String getLineItemId();
        String getQuantity();
        String getFCQty();
        String getFCAdServedEvery();
        Content__c[] getIncludeDartSite();
        Content__c[] getIncludeDartZone();
        Content__c[] getListContentsTargeting();
        Placement__c[] getIncludePlacementTarget();
        String getKeyWKV();
        String getBillingCat();

        String getDartProductType();
        String[] getDartCompanionSize();

        String getLineItemType();
        List < String > getListAdSlotWH();
        Geography__c[] getIncludeGeography();
        Devices__c[] getIncludeDevice();
        Connection__c[] getIncludeConnection();
        String getAdOpsComments();

    }



    /** Asbstract for all dart controllers*/

    public abstract class AbstractDARTController {
        protected String invokedMethod;
        protected List < DARTObject.IDARTGenericObject > listDartObjects;

        public virtual List < DARTObject.IDARTGenericObject > getListDart() {return listDartObjects;}

        public String getInvokedMethod() {return invokedMethod;}
    }


    /** 
     * Abstract of all DARTObjects with shared properties 
     */
    public abstract class AbsractDARTObject implements IDARTObject {
        String dartId;
        String tempId;
        String dartName;
        String assignAdserver;
        String errMsg;

        public String getDartId() {
            return dartId;
        }
        public String getTempId() {
            return tempId;
        }
        public String getDartName() {
            return dartName;
        }
        public void setTempId(String tmpId) {
            tempId = tmpId;
        }
        public void setDartName(String dName) {
            dartName = dName;
        }

        public void setDartId(String dartId) {
            this.dartId = dartId;
        }
        public String getAssignAdserver() {
            return assignAdserver;
        }

        public void setAssignAdserver(String assignAdserver) {
            this.assignAdserver = assignAdserver;
        }
        public String getDartErrMsg() {
            return errMsg;
        }
        public void setDartErrMsg(String errMsg) {
            this.errMsg = errMsg;
        }

    }

    public class DARTOrder extends AbsractDARTObject implements IDARTObjectOrder {
        Map<String, String> transformFieldNames = new Map<String, String> {
            Util.NS + 'IO__c.ownerId' => 'Owner.Id',
            Util.NS + 'IO__c.oppName' => 'Name',
            Util.NS + 'IO__c.advName' => Util.NS + 'Advertiser__r.Name',
            Util.NS + 'IO__c.campaignStart' => Util.NS + 'Campaign_Start__c',
            Util.NS + 'IO__c.orderId' => Util.NS + 'Order_Id__c',
            'Quote.ownerId' => 'Owner.Id',
            'Quote.oppName' => 'Name',
            'Quote.advName' => Util.NS + 'Advertiser__c',
            'Quote.campaignStart' => Util.NS + 'Campaign_Start__c',
            'Quote.orderId' => Util.NS + 'Order_Id__c',
            //US-0008578 map for opportunity and dart
            'Opportunity.oppId' => 'Id',
            'Opportunity.ownerId' => 'Owner.Id',
            'Opportunity.oppName' => 'Name',
            'Opportunity.advName' => Util.NS + 'Account.Name',
            'Opportunity.campaignStart' => Util.NS + 'Campaign_Start2__c',
            'Opportunity.orderId' => Util.NS + 'Order_Id__c',
            'Opportunity.proposalId' => Util.NS + 'Proposal_Id__c',
            'Opportunity.buyerSeat' => Util.NS + 'Buyer_Seat__c' // 17.12.2021 / Sophal Noch / US-0009971
        };
        String advertiserId;
        String salepeopleId;
        SObject contextRecord;
        DARTPerson primaryTrafficker;
        DARTPerson salePeople;

        // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
        String pckOppName;
        String pckOppId;

        Boolean isProposal = false;

        public DARTOrder(SObject contextRecord) {
            this.contextRecord = contextRecord;
        }
        public DARTOrder(SObject contextRecord, Boolean isProposal) {  // 15.12.2021 / Sophal Noch / US-0009927 new contruct to flag proposal
            this.contextRecord = contextRecord;
            this.isProposal = isProposal;
        }

        public DARTOrder(String orderId, String advertiserId) {
            dartId = orderId;
            this.advertiserId = advertiserId;
        }
        public DARTOrder(String orderId, String advertiserId, Boolean isProposal) { // 15.12.2021 / Sophal Noch / US-0009927 new contruct to flag proposal
            dartId = orderId;
            this.advertiserId = advertiserId;
            this.isProposal = isProposal;
        }
        
        public String getValueField(String varField) {
            String sobjectType = UTIL.getString(contextRecord.getSObjectType());
            String fieldName = transformFieldNames.get(sobjectType + '.' + varField);
            if ('campaignStart'.equals(varField)) {
                Date dateVal = (Date)GW_sObject.getFieldValueAsObject(contextRecord, fieldName);
                return dateVal == null ? '' : dateVal.format();
            }
            return UTIL.getString(GW_sObject.getFieldValueAsObject(contextRecord, fieldName));
        }
        
        public String getOwnerId() {
            return getValueField('ownerId');
        }
        
        public String getOppId(){return getValueField('oppId');}

        public String getOppName() {
            return getValueField('oppName');
        }
        
        public String getPONumber() {
            return '';
        }
        
        public String getOrderName() {
            return (getValueField('advName') + ' - ' + getOppName() + ' - ' + getValueField('campaignStart')).replace('\'', '\'\'').replace('"', '""');
        }
        
        public String getOrderId() {
            return getValueField(isProposal ? 'proposalId' : 'orderId');
        }
        
        public DARTPerson getPrimaryTrafficker() {
            return primaryTrafficker;
        }
        
        public DARTPerson getSalepeople() {
            return salePeople;
        }

        public void setAdvertiserId(String advertiserId) {
            this.advertiserId = advertiserId;
        }
        
        public String getOrderAvertiserId() {
            return advertiserId;
        }
        
        public void setSalepeople(DARTPerson salePeople) {
            this.salePeople = salePeople;
        }
        
        public void setPrimaryTrafficker(DARTPerson primaryTrafficker) {
            this.primaryTrafficker = primaryTrafficker;
        }

        public void setDyOppName(String pckOppName){this.pckOppName = pckOppName;}

        public void setDyOppId(String pckOppId){this.pckOppId = pckOppId;}

        public String getBuyerSeat() {  // 17.12.2021 / Sophal Noch / US-0009971
            return getValueField('buyerSeat');
        }
    
    }

    /** 
     * Object Advertiser/Company 
     */
    public class DARTAdvertiser extends AbsractDARTObject implements IDARTObjectAdvertiser {

        Account acc;
        public DARTAdvertiser(Account acc) {
            this.acc = acc;
        }

        public String getAccountId() {
            return acc.id;
        }
        public String getAccountName() {
            return acc.Name;
        }
        public String getAccountRectName() {
            return acc.RecordType.name;
        }
    }

    /**
     * Ads object 
     */
    public class DARTAds extends DARTForecast implements IDARTObjectAds {

        IDARTObjectOrder dartOrder;
        Date externalFromDate;
        Date externalEndDate;
        Long externalQty;
        String externalBillingCat;
        Long externalSalePrice;
        Boolean isProposal = false;

        public DARTAds(SObject contextRecord) {
            super(contextRecord);
        }

        public DARTAds(SObject contextRecord, Boolean isProposal) { // 15.12.2021 / Sophal Noch / US-0009927 new contruct to flag proposal lineitem
            super(contextRecord);
            this.isProposal = isProposal;
        }

        public IDARTObjectOrder getOrder() {
            return dartOrder;
        }
        public void setOrder(IDARTObjectOrder dartOrder) {
            this.dartOrder = dartOrder;
        }
        public String getAdId() {
            return isProposal ? Util.getString(contextRecord.get(Util.NS + 'Proposal_Lineitem_Id__c')) : Util.getString(contextRecord.get(Util.NS + 'Ad_Id__c'));
        }
        public String getStatus() {return String.isEmpty(getAdId()) ? 'Created' : 'Updated';}

        public DateTime getExternalFromDate() {
            return externalFromDate;
        }
        public void setExternalFromDate(Date externalFromDate) {
            this.externalFromDate = externalFromDate;
        }
        public DateTime getExternalEndDate() {
            return externalEndDate;
        }
        public void setExternalEndDate(Date externalEndDate) {
            this.externalEndDate = externalEndDate;
        }
        public Long getExternalQualilty() {
            return externalQty;
        }
        public void setExternalQuality(Long externalQty) {
            this.externalQty = externalQty;
        }
        public String getExternalBillingCategory() {
            return externalBillingCat;
        }
        public void setExternalBillingCategory(String externalBillingCat) {
            this.externalBillingCat = externalBillingCat;
        }
        public Long getExternalSalePrice() {
            return externalSalePrice;
        }
        public void setExternalSalePrice(Long externalSalePrice) {
            this.externalSalePrice = externalSalePrice;
        }
    }


    /**
     * DFP's user properties
     */
    public class DARTPerson extends AbsractDARTObject {

        public DARTPerson() {}

        String userEmail;

        public String getUserEmail() {
            return userEmail;
        }
        public void setUserEmail(String userEmail) {
            this.userEmail = userEmail;
        }

    }

    /** 
     * Forecast Object
     */

    public virtual class DARTForecast extends AbsractDARTObject implements IDARTItem {

        protected SObject contextRecord;
        protected Product2 product;
        protected Id targetingId;
        protected Targeting__c tg;
        protected String adType; //MN-16042021-US-0009350

        public DARTForecast(SObject contextRecord) {
            this.contextRecord = contextRecord;
            this.targetingId = UTIL.getId(GW_sObject.getFieldValueAsObject(contextRecord, 'Targeting__c'));
            
            Product2 product2;
            if(contextRecord instanceof QuoteLineItem){
                product2 = (Product2)GW_sObject.getFieldSObject(contextRecord, 'PriceBookEntry.Product2');
                this.adType  = Util.getString(contextRecord.get('Ad_Type__c')); //MN-16042021-US-0009350
            }else if(contextRecord instanceof Ad_Product__c){
                //US-0008578 map for ad product and dart
                product2 = (Product2)GW_sObject.getFieldSObject(contextRecord, 'Product2__r');
                this.adType  = Util.getString(contextRecord.get('Ad_Type__c')); //MN-16042021-US-0009350
            }else{
                product2 = (Product2)GW_sObject.getFieldSObject(contextRecord, 'Product__r');
            }
            
            this.product = product2;
            this.getTargeting();
        }

        void getTargeting() {
            for (Targeting__c t: [select id, KeyValueString__c,
                    DFP_Time_Monday__c, DFP_Time_Tuesday__c, DFP_Time_Wednesday__c, DFP_Time_Thursday__c, DFP_Time_Friday__c, DFP_Time_Saturday__c, DFP_Time_Sunday__c from Targeting__c where id =: targetingId
                ]) tg = t;
        }
        public DateTime getStartDateTime() {
            return Util.getDateTime(contextRecord.get(Util.NS + 'from_Date__c'));
        }
        public DateTime getEndDateTime() {
            return Util.getDateTime(contextRecord.get(Util.NS + 'until_Date__c'));
        }

        public String getLineItemId() {
            return contextRecord.Id;
        }
        public String getProductName() {
            return product.Name + '';
        }

        public String getLineDesc() {
            return contextRecord instanceof QuoteLineItem ? Util.getString(contextRecord.get('Description')) : Util.getString(contextRecord.get(Util.NS + 'Description__c'));
        }
        public String getQuantity() {
            Decimal q = contextRecord instanceof QuoteLineItem ? Util.getDecimal(contextRecord.get('Quantity')) : Util.getDecimal(contextRecord.get(Util.NS + 'Quantity__c'));
            return q == null ? '' : q.intValue() + '';
        }
        public String getFCQty() {
            Decimal fcQty = Util.getDecimal(contextRecord.get(Util.NS + 'FC_Quantity__c'));
            return fcQty == null ? '' : fcQty.intValue() + '';
        }
        public String getFCAdServedEvery() {
            Decimal FCAdServedEvery = Util.getDecimal(contextRecord.get(Util.NS + 'FC_Ad_served_every__c'));
            return FCAdServedEvery == null ? '' : FCAdServedEvery.intValue() + '';
        }
        public String getFCPeriodDart6() {
            return Util.getString(contextRecord.get(Util.NS + 'FC_Period__c'));
        }
        Geography__c[] geographies;
        public Geography__c[] getIncludeGeography() {
            if (targetingId == null) return new List < Geography__c > ();
            if (geographies == null) {
                geographies = DARTUtil.getListGeographies(targetingId);
            }
            return geographies;
        }

        Devices__c[] devices;
        public Devices__c[] getIncludeDevice() {
            if (targetingId == null) return new List < Devices__c > ();
            if (devices == null) {
                devices = DARTUtil.getListDevices(targetingId);
            }
            return devices;
        }

        TargetingFrequencyAssociation__c[] frequencyCappings;
        public TargetingFrequencyAssociation__c[] getFrequencyCappings() {
            if (targetingId == null) return new List < TargetingFrequencyAssociation__c > ();
            if (frequencyCappings == null) {
                frequencyCappings = DARTUtil.getListFrequencyCappings(targetingId);
            }
            return frequencyCappings;
        }

        Connection__c[] connections;
        public Connection__c[] getIncludeConnection() {
            if (targetingId == null) return new List < Connection__c > ();
            if (connections == null) {
                connections = DARTUtil.getListConnections(targetingId);
            }
            return connections;
        }

        public String getAdOpsComments() {
            return Util.getString(contextRecord.get(Util.NS + 'AdOpsComments__c'));
        }

        public virtual Content__c[] getIncludeDartSite() {
            Content__c[] listCont = DARTUtil.getListContents(targetingId, Product.id);
            if (product.Fixed_Site__c) {
                Content__c[] availSites = DARTUtil.getListAvailSites(Product.id, new Set < String > {
                    'Dart - Zone',
                    'Dart - Site'
                });
                listCont.addAll(availSites);
            }

            return listCont;
        }

        public Content__c[] getIncludeDartZone() {
            return DartUtil.getContentsByTargetType(targetingId, new List < String > {
                'Dart - Zone'
            });
        }

        public Content__c[] getListContentsTargeting() {
            return DARTUtil.getContentsByTargetType(targetingId, New List < String > {
                'Dart - Site',
                'Dart - Zone',
                'Dart - ContentCategory'
            });
        }

        public Content__c[] getPredefinedAdunit() {
            return this.contextRecord.get(Util.NS + 'Predefined_Adunit__c') == null ? new List < Content__c > () : new Content__c[] {
                (Content__c) this.contextRecord.getSObject('Predefined_Adunit__r')
            };
        }

        public virtual Placement__c[] getIncludePlacementTarget() {
            Placement__c[] placementTargets = DartUtil.getPlacementTargeting(targetingId);
            return placementTargets;

        }

        public String getKeyWKV() {
            // String combKVAdkey = '';

            // String combOperator = contextRecord.get(Util.NS + 'Keywords_KeyValue_combination__c') == null ? 'AND' : Util.getString(contextRecord.get(Util.NS + 'Keywords_KeyValue_combination__c'));
            // combOperator = combOperator == 'OR' ? '- OR -' : combOperator;

            // String KeyValueString = Util.getString(tg.KeyValueString__c);
            // String AdKeywords = Util.getString(contextRecord.get(Util.NS + 'AdKeywords__c'));
            // if (KeyValueString != '' && AdKeywords != '') combKVAdkey = '(' + KeyValueString + ' ' + combOperator + ' ' + AdKeywords + ')';
            // else if (KeyValueString != '' && AdKeywords == '') combKVAdkey = KeyValueString;
            // else if (KeyValueString == '' && AdKeywords != '') combKVAdkey = AdKeywords;
            // return combKVAdkey;
            
            //NK:07/03/2021:US-0008010 
            return contextRecord.get('AdKeyWords__c')+''; //final key  = kvstring + keyword(manuall) + predefined
        }

        public String getLineItemType() {
            /* MN-17042021-US-0009350 - No longer need this map since the value from Ad_Type__c field is enough
            final Map<String, String> mLineItemTypes = new Map<String, String> {
                'Standard' => 'STANDARD',
                'Sponsorship' => 'SPONSORSHIP',
                'Bulk' => 'BULK',
                'Standard High' => 'STANDARD',
                'Standard Normal' => 'STANDARD',
                'Standard Low' => 'STANDARD',
                'Network' => 'NETWORK',
                'Price Priority' => 'PRICE_PRIORITY',
                'House' => 'HOUSE'
            };
            */
            /* MN-13042021-US-0009350 - No longer pull from Advertising_Medium__r.DART_AdType__c
            return Product.Advertising_Medium__r.DART_AdType__c == null ? '' : (mLineItemTypes.get(Product.Advertising_Medium__r.DART_AdType__c) == null ? '' : (mLineItemTypes.get(Product.Advertising_Medium__r.DART_AdType__c)));
            */

            return (String.isNotBlank(adType)?adType:''); //MN-16042021-US-0009350 

        }

        public List < String > getListAdSlotWH() {
            List < String > lstAdSlotWH = new List < String > ();
            if (Product.Advertising_Medium__r.DART_AdSlotSize__c != null) {
                lstAdSlotWH = Product.Advertising_Medium__r.DART_AdSlotSize__c.split(';');
            }
            return lstAdSlotWH;
        }

        public String getBillingCat() {
            return Util.getString(contextRecord.get('Billing_Category__c')); //  Sophal:01/03/2021:US-0009134
            //return Util.getString(product.Billing_Category__c);
        }

        public String getDartProductType() {
            return Product.Advertising_Medium__r.Dart_Product_Type__c;
        }
        public String[] getDartCompanionSize() {
            String compSize = Product.Advertising_Medium__r.DART_CompanionSize__c;
            return compSize == null ? new List < String > () : compSize.split(';');
        }

        String totalUnits;
        String availableUnits;

        public String getAvailableUnits() {
            return availableUnits;
        }
        public void setAvailableUnits(String avalUnit) {
            this.availableUnits = avalUnit;
        }
        public String getMatchingUnits() {return totalUnits;}

        public void setMatchingUnits(String matchingUnit) {
            totalUnits = matchingUnit;
        }

        public Decimal getToSubtract(Double availUnits) {
            //Sophal:03/03/2021:US-0009139 migrated from EU instance
            Decimal toSubstract;
            if(product.Advertising_Medium__c != null && product.Advertising_Medium__r.Quantity_Multiplier__c != null){
                toSubstract = product.Advertising_Medium__r.to_Subtract__c;
            }
            if(!this.getListDTOTimeTargeting().isEmpty()) {
                toSubstract = 70;
            }
            return (availUnits == null || toSubstract == null) ? 0 : availUnits*toSubstract/100;
        }

        public Decimal getQuantityMultiplier() {
             //Sophal:03/03/2021:US-0009139 migrated from EU instance
            Decimal qm = 1;
            if(product.Advertising_Medium__c != null && product.Advertising_Medium__r.Quantity_Multiplier__c != null){
                qm = product.Advertising_Medium__r.Quantity_Multiplier__c;
            }
            return  qm;
        }

        public String getAvailableImpressions()
        {
          //Sophal:03/03/2021:US-0009139 migrated from EU instance, orginal method name : DARTObject.getAvailableUnits
          Double availVal = DARTUtil.toDouble(availableUnits);
          return String.valueOf((availVal - getToSubtract(availVal))/getQuantityMultiplier());
        }

        public String getAvailableMatchingImpressions()
        {
            //Sophal:03/03/2021:US-0009139 migrated from EU instance, orginal method name : DARTObject.getMatchingUnits
          Double matchVal = DARTUtil.toDouble(totalUnits);
          return String.valueOf(matchVal/getQuantityMultiplier());
        }

        public String getShareOfVoice(){
            //Sophal:03/03/2021:US-0009139 migrated from EU instance, orginal method name : DARTObject.getShareOfVoice
            Double totalD = DARTUtil.toDouble(totalUnits);
            if(totalD==0)return ''; 
            Double qty = DARTUtil.toDouble(getQuantity());
            return Decimal.valueOf(qty/totalD*100).setScale(2)+'';
        }


        public DTOTimeTargeting[] getListDTOTimeTargeting() {

            DTOTimeTargeting[] theList = new List < DTOTimeTargeting > ();

            if (tg != null) {

                if (tg.DFP_Time_Monday__c != null)
                    theList.add(new DTOTimeTargeting('monday', Util.getString(tg.DFP_Time_Monday__c)));

                if (tg.DFP_Time_Tuesday__c != null)
                    theList.add(new DTOTimeTargeting('tuesday', Util.getString(tg.DFP_Time_Tuesday__c)));

                if (tg.DFP_Time_Wednesday__c != null)
                    theList.add(new DTOTimeTargeting('wednesday', Util.getString(tg.DFP_Time_Wednesday__c)));

                if (tg.DFP_Time_Thursday__c != null)
                    theList.add(new DTOTimeTargeting('thursday', Util.getString(tg.DFP_Time_Thursday__c)));

                if (tg.DFP_Time_Friday__c != null)
                    theList.add(new DTOTimeTargeting('friday', Util.getString(tg.DFP_Time_Friday__c)));

                if (tg.DFP_Time_Saturday__c != null)
                    theList.add(new DTOTimeTargeting('saturday', Util.getString(tg.DFP_Time_Saturday__c)));

                if (tg.DFP_Time_Sunday__c != null)
                    theList.add(new DTOTimeTargeting('sunday', Util.getString(tg.DFP_Time_Sunday__c)));

            }
            return theList;
        }

        public String getRate() {
            // Acmatac SEING, 20/09/201 US-0010364 : Change from SalesPriceNet__c to CPM_net__c
            // Decimal salesPriceNet = Util.getDecimal(contextRecord.get(Util.NS + 'SalesPriceNet__c'));
            Decimal salesPriceNet = Util.getDecimal(contextRecord.get(Util.NS + 'CPM_net__c'));
            return salesPriceNet == null ? '' : salesPriceNet.setScale(2) * 1000000 + '';
        }

        public String getCurrencyCode() {
            return (UserInfo.isMultiCurrencyOrganization() ? contextRecord.get('CurrencyIsoCode') + '' : UserInfo.getDefaultCurrency());
        }

        public Integer getPriority() {
            return DARTUtil.toInteger(Product.Advertising_Medium__r.Dart_Prio__c);
        }

        public String getName() {
            String n = contextRecord instanceof QuoteLineItem ? 
            'QLI-' + Util.getString(contextRecord.get('LineNumber')) + ' - ' + Util.getString(contextRecord.get(Util.NS + 'ProductName__c')) + ' - ' + Util.getString(contextRecord.get(Util.NS + 'Description__c')) : 
            Util.getString(contextRecord.get(Util.NS + 'UniqueAdName__c')) + ' ' + Util.getString(contextRecord.get(Util.NS + 'Description__c'));
            return n.left(255);
        }

    }

    public class DTOTimeTargeting {
        public String day;
        public String[] hours = new List < String > ();

        public DTOTimeTargeting(String day, String strHours) {
            this.day = day;
            this.hours = getHours(strHours);
        }

        // Ex: strHours = '0:00 - 0:59; 1:00 - 1:59; 2:00 - 2:59; 4:00 - 4:59; 21:00 - 21:59; 22:00 - 22:59'
        // this method will return  (0:00 - 2:59, 4:00 - 4:59, 21:00 - 22:59 )
        private String[] getHours(String strHours) {

            String[] hours = new List < String > ();
            for (String h: strHours.split(';')) {
                if (h.trim() != '') hours.add(h.trim());
            }
            hours.sort();

            Map < Integer, String > theMap = new Map < Integer, String > ();
            for (String hour: hours) {
                Integer h = Integer.valueOf(hour.substring(0, hour.indexOf(':')));

                if (theMap.get(h - 1) == null) {
                    theMap.put(h, hour);
                } else {
                    String startHour = theMap.get(h - 1).split('-')[0];
                    String endHour = hour.split('-')[1];
                    theMap.remove(h - 1);
                    theMap.put(h, startHour + ' - ' + endHour);
                }
            }

            return theMap.values();
        }

    }

    /** 
     * DARTDelivery Object 
     * Trying to reduce the script statement to the minimum to ensure that US, 40K Monthly is feasible
     */
    public class DARTDelivery implements IDARTObjectDelivery {

        //constructor
        public DARTDelivery() {}
        public Map < Object, Object > mapRecord;

        public DARTDelivery(Map < Object, Object > mapRecord) {this.mapRecord = mapRecord;}
        public Integer getAdDelivered() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADDELIVERED) + '');}
        public Integer getImpressionsDelivered() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_IMPRESS_DELIVERED) + '');}

        public Integer getAdClickedLifetime() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_ADCLICKED_LIFETIME) + '');}

        public Integer getClicksDelivered() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_CLICKS_DELIVERED) + '');}
        public Double getAdOSI() {return DARTUtil.toDouble(mapRecord.get(DEL_FIELD_ADOSI) + '');}
        public String getAdId() {return mapRecord.get(DEL_FIELD_ADID) + '';}
        public String getOrderId() {return mapRecord.get(DEL_FIELD_ORDERID) + '';}

        public Object getValue(String colname) {return mapRecord.get(colname);}

        public String getDateString() {return mapRecord.get(DEL_FIELD_DATE_OR_MONTH) + '';}
        public Integer getAdActiveViewViewableImpression() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS) + '');}

        public Integer getAdActiveViewMeasurableImpression() {return DARTUtil.toInteger(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_MEASURABLE_IMPRESSIONS) + '');}
        public Double getAdActiveViewViewableImpressionRate() {return DARTUtil.toDouble(mapRecord.get(DEL_FIELD_AD_ACTIVE_VIEW_VIEWABLE_IMPRESSIONS_RATE) + '');}
    }


    /** 
     * Adx interface
     */
    public interface IDARTObjectAdx extends IDARTGenericObject {

        Integer getAdxImpression();
        Integer getAdxClick();
        Double getAdxRevenue();
        String getAdId();
        String getOrderId();
    }

    public class DARTAdxImport implements IDARTObjectAdx {
        public Map < Object, Object > mapRecord;

        public DARTAdxImport() {}
        public DARTAdxImport(Map < Object, Object > mapRecord) {this.mapRecord = mapRecord;}
        public Integer getAdxImpression() {return DARTUtil.toInteger((mapRecord.get(ADX_FIELD_LEVEL_IMPRESSION) + '').replace(',', '').replace('.', ''));}
        public Integer getAdxClick() {return DARTUtil.toInteger((mapRecord.get(ADX_FIELD_LEVEL_CLICK) + '').replace(',', '').replace('.', ''));}
        public Double getAdxRevenue() {return Double.valueOf(mapRecord.get(ADX_FIELD_LEVEL_REVENUE) + '');}
        public String getAdId() {return mapRecord.get(DEL_FIELD_ADID) + '';}
        public String getOrderId() {return mapRecord.get(DEL_FIELD_ORDERID) + '';}
        public Object getValue(String colname) {return mapRecord.get(colname);}
        public String getDateString() {return mapRecord.get(DEL_FIELD_DATE_OR_MONTH) + '';}
    }
}