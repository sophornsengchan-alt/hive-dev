/*********************************************************************************************************************************
    @ Change history:  04.04.2022 / Acmatac SEING / US-0011492 - [TBD by 25th Apr] SAP Integration - Add Tax Code.
*********************************************************************************************************************************/
@RestResource(urlMapping='/SAPWebService/*')
global inherited sharing class SAPWebService {

    static SAPFile sapFile;

    @HttpPost

    global static String getRecords(String id, String dateFrom, String dateTo, String criteria1, String criteria2) {
       

        if (dateFrom == null || dateTo == null) {
            dateFrom = String.valueOf(getFirstDayLastMonth());
            dateTo = String.valueOf(getLastDayOfLastMonth()); 
        }

        SAP_WebService__c webServiceDetails = getSAPWebService(id);

        sapFile = new SAPFile(webServiceDetails.name);

        sapFile.sap2Documents = getDocuments(webServiceDetails, dateFrom, dateTo, criteria1, criteria2);

        sapFile.sap3FileFooter = new SAPFileFooter(sapFile.getCount());

        return JSON.serialize(sapFile);


    }

    /*********************************************************************************************************************************
    @ Change history:  04.04.2022 / Acmatac SEING / US-0011492 - [TBD by 25th Apr] SAP Integration - Add Tax Code.
    *********************************************************************************************************************************/
    private static List<SAPDocument> getDocuments(SAP_WebService__c ws, String dateFrom, String dateTo, String criteria1, String criteria2) {

        AggregateResult[] results = runQuery(ws, dateFrom, dateTo, criteria1, criteria2);



        List<SAPDocument> sapDocuments = new List<SAPDocument>();

        String lastManagementCode = '';

        SAPDocument sapDocNew;

        map<String, SAP_Country_Mapping__mdt> countryMappings = new map<String, SAP_Country_Mapping__mdt>();
        for (SAP_Country_Mapping__mdt c : [SELECT id, label, country_code__c, management_code__c, countryISO__c, currency__c FROM SAP_Country_Mapping__mdt]) {
            countryMappings.put(c.label, c); // incoming country could be any of label, management code, or country code
            countryMappings.put(c.management_code__c, c);
            countryMappings.put(c.country_code__c, c);          
            countryMappings.put(c.countryISO__c, c); 
            countryMappings.put(c.management_code__c.replaceFirst('^0+',''), c);         
        }

        for (AggregateResult ar : results) {
             // write header
            String countryCode = countryMappings.get((String)ar.get('country')).country_code__c;
            String managementCode = countryMappings.get((String)ar.get('country')).management_code__c;
            String currencyCode = countryMappings.get((String)ar.get('country')).currency__c;
            String countryISO = countryMappings.get((String)ar.get('country')).countryISO__c;
            if (managementCode != lastManagementCode) {
                sapDocNew = new SAPDocument();
                sapDocNew.DH = new SAPDocumentHeader(countryCode, countryISO, ws.document_type__c, currencyCode, ws.header_static_text__c, dateTo, ws.Reversal_Date_Month_Offset__c);
                sapDocNew.DL = new List<SAPDocumentLine>();    
                lastManagementCode = managementCode;
                sapDocuments.add(sapDocNew);
            }

            for (SAP_WebService_GL_Line__c swgl : ws.SAP_WebService_GL_Lines__r) {
                SAPDocumentLine sapDocLineNew = new SAPDocumentLine();
                sapDocLineNew.DL03_Account = swgl.gl_code__c;
                sapDocLineNew.DL02_PostingKey = swgl.posting_key__c;
                sapDocLineNew.DL07_ProfitCenter = swgl.profit_center__c;      
                sapDocLineNew.DL09_ProductID = swgl.product_id__c;                
                sapDocLineNew.DL04_AmountDocumentCurrency = String.valueOf((Decimal)ar.get('val'));

                // 04/04/2022 - Acmatac SEING - US-0011492
                sapDocLineNew.DL05_TaxCode = String.isBlank(swgl.Tax_Code__c) ? '' : swgl.Tax_Code__c;

                sapDocLineNew.DL19_LineItemText = ws.Line_Item_Static_Text__c.replace('{!countryISO}', countryISO).replace('{!grp1}', getDataString(ar.get('grp1')));

                if (ws.line_item_static_text__c.contains('{!grp2}')) {
                    sapDocLineNew.DL19_LineItemText = sapDocLineNew.DL19_LineItemText.replace('{!grp2}', getDataString(ar.get('grp2')));
                }

                sapDocLineNew.DL22_ManagerialCountryCode = managementCode;
                sapDocNew.DL.add(sapDocLineNew);
            }
            
            
        }

        return sapDocuments;

    }




    private static AggregateResult[] runQuery(SAP_WebService__c ws, String dateFrom, String dateTo, String criteria1, String criteria2) {
        String query = ws.aggregate_query__c;
        if (dateFrom != null) query = query.replace('{!dateFrom}', dateFrom  );
        if (dateTo != null) query = query.replace('{!dateTo}',  dateTo );
        if (criteria1 != null) {
            if (criteria1.contains(',')) {
                String[] elements = criteria1.split(',');
                String cleanCriteria1 = '';
                for (Integer i=0;  i<elements.size(); i++) {
                    cleanCriteria1 += (cleanCriteria1==''?'':',') + '\'' + elements[i] + '\'';
                }

                query = query.replace('{!criteria1}',   cleanCriteria1  );
            } else {
                query = query.replace('{!criteria1}',   '\'' + criteria1 +'\''  );
            }
        }
       if (criteria2 != null) {
            if (criteria2.contains(',')) {
                String[] elements = criteria2.split(',');
                String cleanCriteria2 = '';
                for (Integer i=0;  i<elements.size(); i++) {
                    cleanCriteria2 += (cleanCriteria2==''?'':',') + '\'' + elements[i] + '\'';
                }

                query = query.replace('{!criteria2}',   cleanCriteria2  );
            } else {
                query = query.replace('{!criteria2}',  '\'' + criteria2 +'\'' );
            }
        }


        sapFile.debug(query);

        AggregateResult[] ar = Database.query(query);

        return ar;
    }

    private static SAP_WebService__c getSAPWebService(String id) {
        try {
            SAP_WebService__c ws = [SELECT id, Reversal_Date_Month_Offset__c, name, sap_id__c, aggregate_query__c, Header_Static_Text__c, Line_Item_Static_Text__c, Document_Type__c, (SELECT id, GL_Code__c, Posting_Key__c, Product_ID__c, Profit_Center__c, Tax_Code__c FROM SAP_WebService_GL_Lines__r) FROM SAP_WebService__c WHERE sap_id__c = :id];
            return ws;
        } catch (Exception e) {
            String errorMessage = 'Unable to retrieve SAP_WebService__c record for ' + id + '. ';
            throw new SAPWebServiceException(errorMessage);
        }
    }

    class SAPFile {
        SAPFileHeader sap1FileHeader;
        List<SAPDocument> sap2Documents;
        SAPFileFooter sap3FileFooter;

        //Comment out 
        String sap4ErrorString = '';
        void debug(String d) {

            sap4ErrorString += ' ' + d.replace('\n',' ').replace('\r',' ');

        }
        //End commentout;

        SAPFile(String interfaceID) {
            sap1FileHeader = new SAPFileHeader(interfaceID);
            sap2Documents = new List<SAPDocument>();
        }

        private Integer getCount() {
            Integer counter = 0;
            for (SAPDocument s : sap2Documents) {
                counter += (s.DL.size() + 1);
            }
            return counter;
        }
    }

    class SAPFileHeader {
        String FH01_RecordTypeIndicator = 'FH';
        String FH02_InterfaceID;
        String FH03_FileGenerationDate = System.now().formatGmt('yyyyMMdd');
        String FH04_FileGenerationTime = System.now().formatGmt('HHmmss');
    
        SAPFileHeader(String interfaceID) {
            this.FH02_InterfaceID = interfaceID;
        }
    }

    class SAPDocument {
        SAPDocumentHeader DH;
        List<SAPDocumentLine> DL;
    }

    class SAPDocumentHeader {
        String DH01_RecordTypeIndicator = 'DH';
        String DH02_CompanyCode = '';
        String DH03_DocumentType = '';
        String DH04_DocumentDate = System.now().formatGmt('yyyyMMdd');
        String DH05_PostingDate = System.now().formatGmt('yyyyMMdd');
        String DH06_Currency = '';
        String DH07_ReferenceNumber = '';
        String DH08_DocHeaderText  = '';
        String DH09_ExchangeRate =  '';
        String DH10_TranslationDate = '';
        String DH11_ReversalDate = '';

        SAPDocumentHeader(String countryCode, String countryISO, String documentType, String currencyCode, String staticText, String dateTo, Decimal reversalOffset) {
            DH02_CompanyCode = countryCode;
            DH03_DocumentType = documentType;
            DH06_Currency = currencyCode;
            DH08_DocHeaderText = staticText.replace('{!countryISO}',countryISO).replace('{!MM}', dateTo.substring(5, 7)).replace('{!YY}', dateTo.substring(2,4));
            DH11_ReversalDate = getReversalDate(reversalOffset);
        }
    }

    class SAPDocumentLine {
        String DL01_RecordTypeIndicator = 'DL';
        String DL02_PostingKey = '';
        String DL03_Account = '';
        String DL04_AmountDocumentCurrency = '';
        String DL05_TaxCode = '';
        String DL06_Assignment = '';
        String DL07_ProfitCenter = '';
        String DL08_BusinessLine = '';
        String DL09_ProductID = '';
        String DL10_CostCenter = '';
        String DL11_InternalOrder = '';
        String DL12_ValueDate = '';
        String DL13_NewCompanyCode = '';
        String DL14_AmountCompanyCodeCurrency = '';
        String DL15_AmountGroupCurrency = '';
        String DL16_ItemRef1 = '';
        String DL17_ItemRef2 = '';
        String DL18_ItemRef3 = '';
        String DL19_LineItemText = '';
        String DL20_TradingPartner = '';
        String DL21_TradingPartnerProfitCenter = '';
        String DL22_ManagerialCountryCode = '';
        String DL23_CategoryCode = '';
        String DL24_GSIClient = '';
        String DL25_PayeeRemitToVendor = '';
        String DL27_CalculateTax = '';       
        
    }

    class SAPFileFooter {
        String FT01_RecordTypeIndicator = 'FT';
        String FT02_EndLiteral = 'END';
        Integer FT03_RecordCount;
        SAPFileFooter(Integer numberOfRecords) {
            FT03_RecordCount = numberOfRecords;
        }

    }

    private static Date getFirstDayLastMonth() {
        return System.today().addMonths(-1).toStartOfMonth();
    }

    private static Date getLastDayOfLastMonth() {
        return System.today().toStartOfMonth().addDays(-1);
    }

    private static String getDataString(Object o) {

        if (o instanceof Integer) {
            return getMonth((Integer)o);
        } else {
            return (String)o;
        }       

    }

    private static String getMonth(Integer i) {
        
        if (i >= 1 && i<= 12) { // assume this is month
            return DateTime.newInstance(2021, i, 4,0,0,0).format('MMM');
        } else {
            return String.valueOf(i);
        }
    }

    public static String getReversalDate(Decimal reversalOffset) {
        Integer offset = (reversalOffset==null || reversalOffset==0)?1:Integer.valueOf(reversalOffset);
        Date d = System.today().addMonths(offset).toStartOfMonth();
        return DateTime.newInstanceGmt(d.year(), d.month(), 5, 0,0,0).formatGmt('yyyyMMdd');
    }

    class SAPWebServiceException extends Exception {}

}