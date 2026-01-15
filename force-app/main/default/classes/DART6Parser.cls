/** 
 * All Parsers for DFP
 * @				: 11.09.2023 /vadhanak voun/ US-0013940 - PART 2 - Upgrade API version of all classes having an API version lower than 31
 */
public without sharing class DART6Parser {

    // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    private static final Integer MAX_CHAR_OF_CSV_CHUNK =100000;

    public DART6Parser() {}

    public virtual interface IDartParser {
        void parse();
        List<DARTObject.IDARTGenericObject> getListDartObject();
    }

    public interface IDART6Parser extends IDartParser {
        void setObjectDFP(Object dfpObject);
    }

    /**
     * Company parser
     * Parse response object from DFP to apex DARTObject[]  
     */
    public class DFPResponseToCompanyParser implements IDART6Parser {

        List<DARTObject.IDARTObjectAdvertiser> lstDartCom;
        List<DART6_COMPANYSERVICE.Company> coms;
        Account acc;

        public DFPResponseToCompanyParser(Account acc) {
            this.acc = acc;
        }

        public void setObjectDFP(Object dfpObject) {
            this.coms = (List<DART6_COMPANYSERVICE.Company> ) dfpObject;
        }

        public void parse() {
            lstDartCom = new List<DARTObject.IDARTObjectAdvertiser> ();
            for (DART6_COMPANYSERVICE.Company com: coms) {
                DARTObject.DARTAdvertiser drtAdv = new DARTObject.DARTAdvertiser(acc);
                drtAdv.setDartId(com.id + '');
                lstDartCom.add(drtAdv);
            }
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return lstDartCom;
        }
    }

    /**
     * Order parser
     * Parse response object from WSDL ivoked to apex DARTObject    
     */
    public class DFPResponseToOrderParser implements IDART6Parser {
        
        List<DARTObject.IDARTObjectOrder> listOrder;
        DART6_ORDERSERVICE.Order objOrder;
        SObject contextRecord;
        AdServer_Login__c credential;

        // Constructor 
        public DFPResponseToOrderParser(SObject contextRecord, AdServer_Login__c credential) {
            this.contextRecord = contextRecord;
            this.credential = credential;
        }

        public void setObjectDFP(Object dfpObject) {
            this.objOrder = (DART6_ORDERSERVICE.Order) dfpObject;
        }

        public void parse() {
            listOrder = new List<DARTObject.IDARTObjectOrder> ();
            DARTObject.DARTOrder dartOrder = new DARTObject.DARTOrder(contextRecord);

            if (objOrder != null) {
                dartOrder.setDartId(objOrder.id + '');
                dartOrder.setAdvertiserId(objOrder.advertiserId + '');
                dartOrder.setAssignAdserver(credential.Name + ' (' + credential.User_Name__c + ')');
                listOrder.add(dartOrder);
            }
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return listOrder;
        }
    }

    /*****************************************************************************************************************************
    @ Class:        DFPResponseToProposalParser
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      Parser from Proposal Response
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created class. US-0009927 - Update PG Opportunity Flow
    @*****************************************************************************************************************************/
    public class DFPResponseToProposalParser implements IDART6Parser {
        
        List<DARTObject.IDARTObjectOrder> listProposal;
        DART6_ProposalService.Proposal objProposal;
        SObject contextRecord;
        AdServer_Login__c credential;

        // Constructor 
        public DFPResponseToProposalParser(SObject contextRecord, AdServer_Login__c credential) {
            this.contextRecord = contextRecord;
            this.credential = credential;
        }

        public void setObjectDFP(Object dfpObject) {
            this.objProposal = (DART6_ProposalService.Proposal) dfpObject;
        }

        public void parse() {
            listProposal = new List<DARTObject.IDARTObjectOrder> ();
            DARTObject.DARTOrder dartProposal = new DARTObject.DARTOrder(contextRecord, true);

            if (objProposal != null) {
                dartProposal.setDartId(objProposal.id + '');
                dartProposal.setAdvertiserId(objProposal.advertiser.companyId + '');
                dartProposal.setAssignAdserver(credential.Name + ' (' + credential.User_Name__c + ')');
                listProposal.add(dartProposal);
            }
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return listProposal;
        }
    }


    /**
     * User parser
     * Parse response object from WSDL ivoked to apex DARTObject    
     */
    public class DFPResponseToSalespersonParser implements IDART6Parser {
        List<DART6_USERSERVICE.User_x> objUsers;
        List<DARTObject.DARTPerson> listSalesperson;

        // Constructor 
        public DFPResponseToSalespersonParser() {

        }

        public void setObjectDFP(Object dfpObject) {
            this.objUsers = (List<DART6_USERSERVICE.User_x> ) dfpObject;
        }

        public void parse() {
            listSalesperson = new List<DARTObject.DARTPerson> ();
            for (DART6_USERSERVICE.User_x u: objUsers) {
                DARTObject.DARTPerson objSalesp = new DARTObject.DARTPerson();
                objSalesp.setDartId(u.id + '');
                objSalesp.setDartName(u.name);
                objSalesp.setUserEmail(u.email);
                listSalesperson.add(objSalesp);
            }
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return listSalesperson;
        }
    }

    /**
     * Availability Forecast
     * Parse response object from WSDL ivoked to apex DARTObject    
     */
    public class DFPResponseToForecastParser implements IDART6Parser {

        List<DARTObject.DARTForecast> listForecast;
        DART6_FORECASTSERVICE.AvailabilityForecast forecast;
        SObject contextRecord;

        public DFPResponseToForecastParser(SObject contextRecord) {
            this.contextRecord = contextRecord;
        }

        public void setObjectDFP(Object dfpObject) {
            this.forecast = (DART6_FORECASTSERVICE.AvailabilityForecast) dfpObject;
        }

        public void parse() {
            listForecast = new List<DARTObject.DARTForecast> ();
            DARTObject.DARTForecast objForecast = new DARTObject.DARTForecast(contextRecord);
            objForecast.setAvailableUnits(forecast.availableUnits == null ? '' : String.valueOf(forecast.availableUnits));
            objForecast.setMatchingUnits(forecast.matchedUnits == null ? '' : String.valueOf(forecast.matchedUnits));
            listForecast.add(objForecast);
        }

        public List<DARTObject.DARTForecast> getListDartObject() {
            return listForecast;
        }
    }

    /**
     * Ads parser
     * Parse response object from WSDL ivoked to apex DARTObject    
     * History: cmatac SEING, 2 March 2022 US-0010618 - ADS - New Product record types and rename existing
     */
    public class DFPResponseToAdsParser implements IDART6Parser {
        Map<String, String> transformFieldNames = new Map<String, String> {
            Util.NS + 'IO_LineItem__c.dartVer' => Util.NS + 'Product__r.RecordType.Name',
            Util.NS + 'IO_LineItem__c.dartCountry' => Util.NS + 'Product__r.Site__r.Country__c',
            'QuoteLineItem.dartVer' => 'Product2.RecordType.DeveloperName',
            'QuoteLineItem.dartCountry' => 'Product2.' + Util.NS + 'Site__r.' + Util.NS + 'Country__c',
            //US-0008578 map for dart and Ad_Product__c.Product2__r
            'Ad_Product__c.dartVer' => 'Product2__r.RecordType.DeveloperName',
            'Ad_Product__c.dartCountry' => 'Product2__r.' + Util.NS + 'Site__r.' + Util.NS + 'Country__c'
        };
        
        List<DARTObject.IDARTObject> lstDartObjects;
        List<DARTObject.DARTAds> lstAds;
        SObject contextRecord;
        AdServer_Login__c credential;
        Map<String, Advertiser__c> mapAdvertiser;
        DART6_LINEITEMSERVICE.LineItem lineItem;

        // Constructor
        public DFPResponseToAdsParser(SObject contextRecord, AdServer_Login__c credential, Map<String, Advertiser__c> mapAdvertiser) {
            this.contextRecord = contextRecord;
            this.credential = credential;
            this.mapAdvertiser = mapAdvertiser;
        }

        public void setObjectDFP(Object dfpObject) {
            this.lineItem = (DART6_LINEITEMSERVICE.LineItem) dfpObject;
        }
        
        public String getValueField(String varField) {
            String sobjectType = UTIL.getString(contextRecord.getSObjectType());
            String fieldName = transformFieldNames.get(sobjectType + '.' + varField);
            return UTIL.getString(GW_sObject.getFieldValueAsObject(contextRecord, fieldName));
        }

        public void parse() {
            lstAds = new List<DARTObject.DARTAds> ();
            String dartVerCountry = getValueField('dartVer') + '_' + getValueField('dartCountry');
            DARTObject.DARTAds objAds = new DARTObject.DARTAds(contextRecord);
            objAds.setDartId(lineItem != null ? lineItem.id + '' : '');
            objAds.setOrder(new DARTObject.DARTOrder(lineItem != null ? lineItem.orderId + '' : '', (mapAdvertiser.get(dartVerCountry) != null ? mapAdvertiser.get(dartVerCountry).Dart6_Advertiser_Id__c : '')));
            objAds.setAssignAdserver(credential.Name + ' (' + credential.User_Name__c + ')');
            if (lineItem != null) lstAds.add(objAds);
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return lstAds;
        }
    }

    /*****************************************************************************************************************************
    @ Class:    DFPResponseToProposalLineitemParser
    @ Author:       Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:      Parser from Proposal Lineitem Response
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  01.12.2021 / Sophal Noch / Created class. US-0009927 - Update PG Opportunity Flow
    @               2 March 2022 / Acmatac SEING / US-0010618 - ADS - New Product record types and rename existing
    @*****************************************************************************************************************************/
    public class DFPResponseToProposalLineitemParser implements IDART6Parser {
        Map<String, String> transformFieldNames = new Map<String, String> {
            'Ad_Product__c.dartVer' => 'Product2__r.RecordType.DeveloperName', // Acmatac US-0010618, Changed from RecordType.Name to RecordType.DeveloperName 
            'Ad_Product__c.dartCountry' => 'Product2__r.' + Util.NS + 'Site__r.' + Util.NS + 'Country__c'
        };
        
        List<DARTObject.IDARTObject> lstDartObjects;
        List<DARTObject.DARTAds> lstProposalLineitems;
        SObject contextRecord;
        AdServer_Login__c credential;
        Map<String, Advertiser__c> mapAdvertiser;
        DART6_LINEITEMSERVICE.ProposalLineItem lineItem;

        // Constructor
        public DFPResponseToProposalLineitemParser(SObject contextRecord, AdServer_Login__c credential, Map<String, Advertiser__c> mapAdvertiser) {
            this.contextRecord = contextRecord;
            this.credential = credential;
            this.mapAdvertiser = mapAdvertiser;
        }

        public void setObjectDFP(Object dfpObject) {
            this.lineItem = (DART6_LINEITEMSERVICE.ProposalLineItem) dfpObject;
        }
        
        public String getValueField(String varField) {
            String sobjectType = UTIL.getString(contextRecord.getSObjectType());
            String fieldName = transformFieldNames.get(sobjectType + '.' + varField);
            return UTIL.getString(GW_sObject.getFieldValueAsObject(contextRecord, fieldName));
        }

        public void parse() {
            lstProposalLineitems = new List<DARTObject.DARTAds> ();
            String dartVerCountry = getValueField('dartVer') + '_' + getValueField('dartCountry');
            DARTObject.DARTAds objProposalLineitems = new DARTObject.DARTAds(contextRecord, true);
            objProposalLineitems.setDartId(lineItem != null ? lineItem.id + '' : '');
            objProposalLineitems.setOrder(new DARTObject.DARTOrder(lineItem != null ? lineItem.proposalId + '' : '', (mapAdvertiser.get(dartVerCountry) != null ? mapAdvertiser.get(dartVerCountry).Dart6_Advertiser_Id__c : ''), true));
            objProposalLineitems.setAssignAdserver(credential.Name + ' (' + credential.User_Name__c + ')');
            if (lineItem != null) lstProposalLineitems.add(objProposalLineitems);
        }

        public List<DARTObject.IDARTObject> getListDartObject() {
            return lstProposalLineitems;
        }
    }


    // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    public class CSV6ToDeliverParser implements IDART6Parser {
        protected List<DARTObject.IDARTGenericObject> listDeliveries;
        protected String csvRes;
        protected String sobjType;
        protected Dart6CSVResponseReader deliveryResponse;
        protected Integer[] gNums = new Integer[11];
        public CSV6ToDeliverParser(String sobjType) {
            this.sobjType = sobjType;
            initColumn(sobjType);
        }

        private void initColumn(String sobjType) {
            if (sobjType == DeliveryController.SOBJECT_AD_PRODUCT) {
                /* NK:02/04/2013: Obsoleted. switched to xmlNode*/
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 3; //lineitemLifetimeMergedImpressions
                gNums[3] = 4; //lineitemLifetimeMergedClicks
                gNums[4] = 2; //mergeLineItemDeliveryIndicator
                gNums[5] = 5; //mergeReservationImpressionsDelivered
                gNums[6] = 6; //mergeReservationClicksDelivered
                gNums[7] = -1; //""
            } else if (sobjType == DeliveryController.SOBJECT_AD_REV_DAILY) {
                /* NK:02/04/2013: Obsoleted. switched to xmlNode*/
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 4; //lineitemLifetimeMergedImpressions
                gNums[3] = 5; //lineitemLifetimeMergedClicks
                gNums[4] = 3; //mergeLineItemDeliveryIndicator
                gNums[5] = 6; //mergeReservationImpressionsDelivered
                gNums[6] = 7; //mergeReservationClicksDelivered
                gNums[7] = 2; //date


            } else if (sobjType == DeliveryController.SOBJECT_AD_REV_MONTHLY || sobjType == DeliveryController.SOBJECT_AD_REV_MONTHLY_MTD) {
                /* NK:02/04/2013: Obsoleted. switched to xmlNode*/
                /************* DFP version 201311 **************/
                gNums[0] = 0; //orderId
                gNums[1] = 1; //lineItemId
                gNums[2] = 4; //mergeReservationImpressionsDelivered
                gNums[3] = 5; //mergeReservationClicksDelivered
                gNums[4] = 3; //mergeLineItemDeliveryIndicator
                gNums[5] = 4; //mergeReservationImpressionsDelivered
                gNums[6] = 5; //mergeReservationClicksDelivered
                gNums[7] = 2; //month
            }
        }

        public void parse() {
            listDeliveries = new List<DARTObject.DARTDelivery> ();
            deliveryResponse = new Dart6CSVResponseReader(csvRes);

            String availImpress = '';
            if (deliveryResponse.isError) {
                throw new ExceptionGroup.DARTException(deliveryResponse.errMsg);
            } else {
                try {
                    doExtract();
                    deliveryResponse = null;
                } catch (Exception ex) {
                    throw new ExceptionGroup.ParserException(ex.getMessage());
                }
                }
            }

        private void doExtract() {
            CSVReader reader = deliveryResponse.reader;
            List < List < String >> dataRows = reader.getAllDataRow();
            for (List < String > row: dataRows) {
                listDeliveries.add(new DARTObject.DARTDelivery(
                    new Map < Object, Object > {
                        DARTObject.DEL_FIELD_ADDELIVERED => row.get(gNums[2]), // child3.getChildElements()[gNums[2]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_ADCLICKED_LIFETIME => row.get(gNums[3]), // child3.getChildElements()[gNums[3]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_ADOSI => row.get(gNums[4]), //child3.getChildElements()[gNums[4]].getChildElements()[0].getText(), 
                        DARTObject.DEL_FIELD_ADID => row.get(gNums[1]), //child3.getChildElements()[gNums[1]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_ORDERID => row.get(gNums[0]), //child3.getChildElements()[gNums[0]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_IMPRESS_DELIVERED => row.get(gNums[5]), //child3.getChildElements()[gNums[5]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_CLICKS_DELIVERED => row.get(gNums[6]), //child3.getChildElements()[gNums[6]].getChildElements()[0].getText(),
                        DARTObject.DEL_FIELD_DATE_OR_MONTH => gNums[7] == -1 ? '' : row.get(gNums[7]) // child3.getChildElements()[gNums[7]].getChildElements()[0].getText()
                    }
                ));
            }
        }

        public List<DARTObject.IDARTGenericObject> getListDartObject() {
            return listDeliveries;
        }
        public void setObjectDFP(Object dfpObject) {
            this.csvRes = dfpObject + '';
        }

    }

    // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    public class CSVReader {

        private String delimiter;
        private List < String > lines;
        private Integer dataRow;
        public CSVReader(String contents, String delimiter) {
            this(contents, delimiter, true);
        }
        
        private CSVReader(String contents, String delimiter, Boolean hasHeader) {
            this(splitStringByEndLine(contents), delimiter, hasHeader);
                        }
        public CSVReader(List < String > lines, String delimiter) {
            this(lines, delimiter, true);
                    }
        public CSVReader(List < String > lines, String delimiter, Boolean hasHeader) {
            this.lines = lines;
            this.delimiter = delimiter;
            if (hasHeader) {
                dataRow = 1;
                } else {
                dataRow = 0;
        }
    }


        public List < String > getHeaders() {
            if (dataRow > 0) {
                //first row is header row
                return getDataRow(0);
        }
            return null;
        }
    /**
         return all csv row except header row(row=0)
     */
        public List < List < String >> getAllDataRow() {
            List < List < String >> allRows = new List < List < String >> ();
            for (Integer i = dataRow; i < lines.size(); i++) {
                List < String > dataRow = getDataRow(i);
                if (dataRow != null) {
                    allRows.add(dataRow);
            }
        }
            return allRows;
                                            }
        public String getLine(Integer row) {
            if (row < lines.size()) {
                return lines.get(row);
                                    }
            return null;
                                }
        public List < String > getDataRow(Integer row) {
            if (row < lines.size()) {
                String strRow = getLine(row);
                if (!isEmptyRow(strRow)) {
                    return strRow.split(delimiter);
                            }
                        }
            return null;
                    }
    
        private Boolean isEmptyRow(String row) {
            return String.isBlank(row) || row.replaceAll(delimiter, '').trim().length() == 0;
                }
            }
    // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
    private static List<String> splitStringByEndLine(String contents){
        // Note n = new Note(Title='AMT TEST',ParentId='00102000003fIuxAAE',Body=contents);
        // insert n;
        List<String> lines = new List<String>();
        String incorrectLastLine ='';
        while(contents.length()>0){
            Integer length = MAX_CHAR_OF_CSV_CHUNK;
            if(contents.length()<length){
                length = contents.length();
        }
            String substr =incorrectLastLine+ contents.subString(0,length);

           boolean lastIsCorrect = substr.endsWithIgnoreCase('\n');
           List<String> tempLines = subStr.split('\n');
            if(lastIsCorrect){
                incorrectLastLine='';
            } else {
                incorrectLastLine= tempLines.remove(tempLines.size()-1);
                }
            lines.addAll(tempLines);
            contents = contents.subString(length,contents.length());
          
            }
        return lines;
        }

    /**
     * Delivery parser, to reduce script statement we need to create the new Parser
     * // Acmatac SEING, US-0007908 [Ads 2020] Migrate DFP Batch Process to Hive.
     */
    public class Dart6CSVResponseReader {
        public Boolean isError {
            get;
            set;
        }
        public CSVReader reader {
            get;
            set;
        }
        public String errMsg;

        /** constructor */
        public Dart6CSVResponseReader(String csv) {
            isError = false;
            //dfp's report format type =CSV_DUMP,comma separated values. 
            reader = new CSVReader(csv, ',');
            List < String > headers = reader.getHeaders();
            if (headers != null && headers.contains('Errors')) {
                isError = true;
                errMsg = reader.getLine(1);

            }
        }
    }
}