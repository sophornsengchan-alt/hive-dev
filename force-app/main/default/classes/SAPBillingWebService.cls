@RestResource(urlMapping='/SAPBillingWebService/*')
global inherited sharing class SAPBillingWebService {

    static SAPFile sapFile;
    static Map<id,map<string,string>> mapData = new Map<Id,map<string,string>>();
    static List<SAPRecord> RecordstoSend = new List<SAPRecord>();
    static SAPBillingWebService__mdt webServiceDetails;
    static String errorMessage;

    @HttpPost
    global static String getRecords(String id) {
        
            webServiceDetails = getSAPWebService(id);
        //try{
            sapFile = new SAPFile(webServiceDetails);
            sapFile.sap2Records = getDocuments(webServiceDetails);          
        /*}catch(Exception e){
            errorMessage = 'Oops something has gone wrong please try again. If problem continues please contact...';
            throw new SAPWebServiceException(errorMessage);
        }*/
       return JSON.serialize(sapFile);  
    }

    private static List<SAPRecord> getDocuments(SAPBillingWebService__mdt ws) {

        Sobject[] results = runQuery(ws);
        SAPRecord sapRecord;
        List<SAPRecord> RecordsList = new List<SAPRecord>();
        for (Sobject so : results) {
            SapRecord = new SAPRecord();
            Map<string,string> mapFieldMappings = new Map<String,String>();
            for(SAPBillingWebServiceFieldMapping__mdt fieldmapping:webServiceDetails.SAPBillingWebServiceFieldMappings__r){
                if(fieldmapping.Query_Field__c != null){
                    String QueryValue;
                    if(fieldmapping.Query_Field__c.contains('.')){
                        Integer point = fieldmapping.Query_Field__c.indexOfAny('.');

                        String lookupname = fieldmapping.Query_Field__c.substring(0,point);
                        String fieldname = fieldmapping.Query_Field__c.substring(point+1,fieldmapping.Query_Field__c.length());
                        
                        if(!fieldname.contains('.') && so.getSObject(lookupname) != null){
                            QueryValue = String.ValueOf(so.getSObject(lookupname).get(fieldname));
                        }else if(so.getSObject(lookupname) != null) {
                            point = fieldname.indexOfAny('.');
                            string lookupname2 = fieldname.substring(0,point);
                            string fieldname2 = fieldname.substring(point+1,fieldname.length());
                            
                            if(!fieldname2.contains('.') && so.getSObject(lookupname).getSObject(lookupname2) != null){       
                                QueryValue = String.ValueOf(so.getSObject(lookupname).getSObject(lookupname2).get(fieldname2));
                            }
                            else if(so.getSObject(lookupname).getSObject(lookupname2) != null) {
                                point = fieldname2.indexOfAny('.');
                                string lookupname3 = fieldname2.substring(0,point);
                                string fieldname3 = fieldname2.substring(point+1,fieldname2.length());   
                                if(so.getSObject(lookupname).getSObject(lookupname2).getSobject(lookupname3)!= null){
                                    QueryValue = String.ValueOf(so.getSObject(lookupname).getSObject(lookupname2).getSobject(lookupname3).get(fieldname3));
                                }                             
                            }
                        }
                        if(queryvalue != null){
                            mapFieldMappings.put(fieldmapping.SAP_Field__c,QueryValue);
                        }else{
                            mapFieldMappings.put(fieldmapping.SAP_Field__c,'');
                        }
                    }else{
                        QueryValue = String.valueOf(so.get(fieldmapping.Query_Field__c));

                        if(queryvalue != null){
                            if(QueryValue.length() > fieldmapping.Length_Limit__c){
                            mapFieldMappings.put(fieldmapping.SAP_Field__c,QueryValue.substring(0,Integer.ValueOf(fieldmapping.Length_Limit__c)));                        
                            }else{
                                mapFieldMappings.put(fieldmapping.SAP_Field__c,QueryValue);
                            }
                        }
                        else{
                            mapFieldMappings.put(fieldmapping.SAP_Field__c,'');
                        }
                    }
                }else if(fieldmapping.Hardcoded_Value__c != null){
                    mapFieldMappings.put(fieldmapping.SAP_Field__c,String.valueOf(fieldmapping.Hardcoded_Value__c));
                }else{
                    mapFieldMappings.put(fieldmapping.SAP_Field__c,'');
                }
            }
            sapRecord.columns = mapFieldMappings;
            RecordsList.add(SapRecord);         
        }

        return RecordsList;
    }

    private static Sobject[] runQuery(SAPBillingWebService__mdt ws) {
        String query = ws.query__c;
        System.Debug('###'+query);
        //sapFile.debug(query);
        SObject[] listSo = Database.query(query);
        return listSo;
    }

    private static SAPBillingWebService__mdt getSAPWebService(String ServiceName) {
            SAPBillingWebService__mdt ws;
            try{
                ws = [SELECT id, MasterLabel, query__c, FileType__c,FileDirectory__c,FileName__c,(SELECT id, Query_Field__c, SAP_Field__c, Hardcoded_Value__c, Order__c, Length_Limit__c FROM SAPBillingWebServiceFieldMappings__r Order By Order__c DESC) FROM SAPBillingWebService__mdt WHERE MasterLabel = :ServiceName];
            }catch(Exception e){
                errorMessage = 'No web service call is defined for:' + ServiceName + '.';
                throw new SAPWebServiceException(errorMessage);
            }
            return ws;
    }

    class SAPFile {
        SAPFileHeader sap1FileHeader;
        List<SAPRecord> sap2Records;
        SAPFileFooter sap3FileFooter;

        //Comment out 
        String sap4ErrorString = '';
        void debug(String d) {
            sap4ErrorString += ' ' + d.replace('\n',' ').replace('\r',' ');
        }
        //End commentout;

        SAPFile(SAPBillingWebService__mdt webServiceDetails) {
            sap1FileHeader = new SAPFileHeader(webServiceDetails);
            sap2Records = new List<SAPRecord>();
        }
    }

    class SAPFileHeader {
        String FileName;
        String FileDirectory;
        String FileFormat;
        String WebServiceName;

        SAPFileHeader(SAPBillingWebService__mdt webServiceDetails) {
            this.WebServiceName = webServiceDetails.MasterLabel;
            this.FileDirectory = webServiceDetails.FileDirectory__c;
            this.FileFormat = webServiceDetails.FileType__c;
            this.FileName = webServiceDetails.FileName__c;
            if(FileName.contains('MMDDYYYY')){
                FileName = FileName.replace('MMDDYYYY', String.ValueOf(system.today().month())+String.ValueOF(system.today().day())+String.ValueOF(system.today().year()));
            }

            if(FileName.contains('HHSS')){
                FileName = FileName.replace('HHSS', String.valueOf(datetime.now().hour())+String.ValueOF(datetime.now().minute()));
            }

        }
    }

    class SAPRecord {
        Map<String,String> columns;
    }

    class SAPFileFooter {
        /*String FT01_RecordTypeIndicator = 'FT';
        String FT02_EndLiteral = 'END';
        Integer FT03_RecordCount;
        SAPFileFooter(Integer numberOfRecords) {
            FT03_RecordCount = numberOfRecords;
        }*/

    }

    class SAPWebServiceException extends Exception {}
}