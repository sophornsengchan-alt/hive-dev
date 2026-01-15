/*********************************************************************************************************************************
@ Class:          MassUploadObjectControllerTest
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Test Controller Class for MassUploadObjectController
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  14.09.2020 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
@isTest
private without sharing class MassUploadObjectControllerTest{

    static String csvLeadContent = 'Lead Owner,Focus Vertical,Lead Source,Other Lead Source,Company,Website,Last Name,First Name,Email,Job Title,Role,Street,City,State,Zip/Postal Code,Country,Phone,Lead Segment,Shopping Cart\r'
    + '{!ownerId1},Collectibles,Tradeshow,Event xyz,"Rosery, Inc.",XXXX,Red,Rose,Rose@roseryinc.com,lastNameHere,XXXXX,XXXXX,XXXXX,XXXXX,11110,AU,000 000 0000,Brand,{!accId1}\r'
    + '{!ownerId2},Fashion,Tradeshow,Event abc,"Lily, Inc.",YYYYY,Blue,Lily,Lily@flowerlily.com,lastNameHere,XXXXX,XXXXX,XXXXX,XXXXX,1111,AU,000 000 0000,Brand,{!accId2}';
    
    static String csvDealContent = 'Owner,Deal_Site,Vertical,Category,Sub_Category,Deal_Format,eBay_Item_ID,eBay_Seller,Product_Title,Deal_Price,RRP_WAS,List_Price,Seller_Price,Quantity,Sold_Items_Forecast,Maximum_Purchases,Dealdate (earliest possible),Deal_Start_Date,Deal_Start_Time,Deal_End_Date,Deal_End_Time,Optional_Notes,Sellers_Deal_Price_MSKU_Lower,Sellers_Deal_Price_MSKU_Upper,Sellers_Offer_Price_MSKU_Lower,Sellers_Offer_Price_MSKU_Upper,List_Price_MSKU_Lower,List_Price_MSKU_Upper,Seller_Approver_1,Seller_Approver_2,Seller_Approver_3,Seller_Approver_4,Seller_Approver_5\r'
    + '{!ownerId1},US,Electronics,Cell Phones & Accessories,,Deal,133058000000,Test Acc1,$20/Mo Red Pocket Prepaid Wireless Phone Plan+Kit: Unlmtd Everything 5GB LTE,50000,RRP,$360.00 ,43772.01,2000,1000,3,{!date},{!date},11:00,{!date},17:00,No Notes,250,300,200,250,200,250,test@gmail.com.test,,,,';

    static String dateFm = '01/01/2021';
    static String naLead = 'NA_Lead';
    static String naDeal = 'NA_Deal';

    static MassUploadObjectController.CustomUploadSetting massUploadObject;

    static String[] listError;

    static Map<String,Object> mapResult;

    static List<Mass_Upload_Setting__mdt> listMassUploadSetting;

    static SObjectType sObjectType;
    static List<String> rowColumns;

    static Map<String,String> formatDate = new Map<String,String> {
        'MM/dd/yyyy' => '09/20/2020',
        'dd/MM/yyyy' => '01/03/2021',
        'yyyy/MM/dd' => '2021/02/23',
        'yyyy-MM-dd' => '2021-09-09',
        'dd.MM.yyyy' => '23.09.2021'
    };

    public static void setUpMassUploadObject(String param){

        massUploadObject =  new MassUploadObjectController.CustomUploadSetting();
        

        listMassUploadSetting = [
            SELECT DeveloperName, Object_Name__c,RecordTypeID__c,CSV_Column_Names__c,CSV_Column_Types__c,Field_API_Names__c 
            From Mass_Upload_Setting__mdt where DeveloperName =: param LIMIT 1
        ];

        

        if(!listMassUploadSetting.isEmpty() ){

            sObjectType = Schema.getGlobalDescribe().get(listMassUploadSetting[0].Object_Name__c);

            massUploadObject.sobjectName = sObjectType.getDescribe().getLabel();
            massUploadObject.sobjectApiName = sObjectType.getDescribe().getName();
            massUploadObject.recordTypeId = listMassUploadSetting[0].RecordTypeID__c;
            massUploadObject.csvColumnNames = listMassUploadSetting[0].CSV_Column_Names__c;
            massUploadObject.csvColumnTypes = listMassUploadSetting[0].CSV_Column_Types__c;
            massUploadObject.fieldApiName = listMassUploadSetting[0].Field_API_Names__c;
        }

        ApexPages.currentPage().getParameters().put('setting',param);
    }

    @isTest
    public static void testUploadLead() {

        // test custom meta data not found
        String invalidSetting = '';
        setUpMassUploadObject(invalidSetting);
        
        System.assertEquals(0, listMassUploadSetting.size());
        MassUploadObjectController ctrl = new MassUploadObjectController();
        System.assertEquals(null, ctrl.isLightningReady);

        // test custom meta data found
        
        setUpMassUploadObject(naLead);

        ctrl = new MassUploadObjectController();
        System.assertEquals(true, ctrl.isLightningReady);

        System.assertEquals(1, listMassUploadSetting.size());

        // test for error because of csv
        /*mapResult = MassUploadObjectController.chunkRecords(csvLeadContent,'en',',',false);
        System.assertEquals('ok', mapResult.get('status'));

        listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
        rowColumns = (List<String>) mapResult.get('rowColumns');*/
        
        List<List<List<String>>> listAllChunk = convertCSVToListChunk(csvLeadContent);

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'','',false,'MM/dd/yyyy',false,null,null,null,null,null,null);
        System.assertEquals('ok', mapResult.get('status'));

        listError =   (String[])mapResult.get('listError');
        System.assertEquals(1, listError.size());

       
        // test for success by updating the csv content
        RecordType partnerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Partner');
        Account acc = new Account(EBH_OracleId__c='123456789',Name='Test Acc1',RecordTypeID = partnerRecordType.Id,EBH_PartnerType__c='Shop System');
        insert acc;

        String updatedCsvLeadContent = csvLeadContent;

        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!ownerId1}', UserInfo.getUserId()).replace('{!ownerId2}', UserInfo.getUserId());
        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!accId1}', acc.Id).replace('{!accId2}', acc.Id);
        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!date}', dateFm);
        
        // mapResult = MassUploadObjectController.doUploadSobject(updatedCsvLeadContent,null,0,'en',',',new String[]{}, (Object)massUploadObject);
        // System.assertEquals('ok', mapResult.get('status'));
        // listError =   (String[])mapResult.get('listError');



        /*mapResult = MassUploadObjectController.chunkRecords(updatedCsvLeadContent,'en',',',false);
        System.assertEquals('ok', mapResult.get('status'));

        listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
        rowColumns = (List<String>) mapResult.get('rowColumns');*/

        // test class run only 1 record per transaction.
        // this is the first run

        listAllChunk = convertCSVToListChunk(updatedCsvLeadContent);

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'','',false,'MM/dd/yyyy',false,null,null,null,null,null,null);
        System.assertEquals('ok', mapResult.get('status'));

        listError =  (String[])mapResult.get('listError');

        System.assertEquals(0, listError.size());

        // List<List<MassUploadObjectController.CsvRowWrapper>> listAllChunk = (List<List<MassUploadObjectController.CsvRowWrapper>>)mapResult.get('listAllChunk');

        // mapResult = MassUploadObjectController.doUploadSobject(null,listAllChunk,1,'en',',',listError, (Object)massUploadObject);

        // this is the second run

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[1],rowColumns,1,'en',(Object)massUploadObject,'','',false, 'MM/dd/yyyy',false,null,null,null,null,null,null);
        System.assertEquals('ok', mapResult.get('status'));

        System.assertEquals('ok', mapResult.get('status'));
        listError =   (String[])mapResult.get('listError');
        System.assertEquals(0, listError.size());

        List<Lead> listLead = [SELECT Id FROM Lead where OwnerId =:UserInfo.getUserId()];

        System.assertEquals(2, listLead.size());

        MassUploadObjectController.getDocumentUrl('Lead',false);
    }
    
    //TH: 30/09/2020 : US-0008088 :
    @isTest
    public static void testUploadDeal() {
        setUpMassUploadObject(naDeal);
        
        MassUploadObjectController ctrl = new MassUploadObjectController();
        ctrl = new MassUploadObjectController();
        System.assertEquals(true, ctrl.isLightningReady);

        System.assertEquals(1, listMassUploadSetting.size());

        RecordType partnerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(EBH_OracleId__c='123456789',Name='Test Acc1',RecordTypeID = partnerRecordType.Id,EBH_PartnerType__c='Shop System');
        insert acc;
        
        Contact con = new Contact(LastName = 'testCountContact',Email='test@gmail.com.test', AccountId = acc.Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
        insert con;
        
        String updatedCsvLeadContent = csvDealContent;

        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!ownerId1}', UserInfo.getUserId());
        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!date}', dateFm);

        /*mapResult = MassUploadObjectController.chunkRecords(updatedCsvLeadContent,'en',',',false);
        System.assertEquals('ok', mapResult.get('status'));

        listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
        rowColumns = (List<String>) mapResult.get('rowColumns');*/

        // test class run only 1 record per transaction.
        // this is the first run

        List<List<List<String>>> listAllChunk = convertCSVToListChunk(updatedCsvLeadContent);

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'Account:Name:7*Contact:Email:28,29,30,31,32','EBH_Status__c:New',true, 'MM/dd/yyyy',false,'1','2','3',null,null,null);
        System.assertEquals('ok', mapResult.get('status'));

        listError =  (String[])mapResult.get('listError');
        //System.assertEquals(0, listError.size());
    }
    
    @isTest
    public static void testInvalidCSVUploadLead() {
        setUpMassUploadObject(naLead);
        String updatedCsvLeadContent = csvLeadContent;
        ApexPages.currentPage().getParameters().put('setting',naLead);

        updatedCsvLeadContent = updatedCsvLeadContent.replaceAll('lastNameHere','');

        MassUploadObjectController ctrl = new MassUploadObjectController();
        System.assertEquals(true, ctrl.isLightningReady);

        List<Mass_Upload_Setting__mdt> listMassUploadSetting = [
            SELECT DeveloperName, Object_Name__c,RecordTypeID__c,CSV_Column_Names__c,CSV_Column_Types__c,Field_API_Names__c 
            From Mass_Upload_Setting__mdt where DeveloperName =: naLead LIMIT 1
        ];

        // mapResult = MassUploadObjectController.doUploadSobject(updatedCsvLeadContent,null,0,'en',',',new String[]{}, (Object)massUploadObject);

        /*mapResult = MassUploadObjectController.chunkRecords(updatedCsvLeadContent,'en',',',false);
        System.assertEquals('ok', mapResult.get('status'));

        listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
        rowColumns = (List<String>) mapResult.get('rowColumns');*/

        List<List<List<String>>> listAllChunk = convertCSVToListChunk(updatedCsvLeadContent);

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'','',false, 'MM/dd/yyyy',false,null,null,null,null,null,null);


        listError =   (String[])mapResult.get('listError');

       
        System.assertEquals('ok', mapResult.get('status'));
        System.assertEquals(1, listError.size());
        
    }

    @isTest
    public static void testApexIndex() {
        mapResult = MassUploadObjectController.apexInit(naLead,null);
        System.assertEquals('ok', mapResult.get('status'));
        System.assertNotEquals(null, mapResult.get('massUploadObject'));
    }
    
    @isTest
    public static void testApexIndexDeal() {
        mapResult = MassUploadObjectController.apexInit(naDeal,null);
        System.assertEquals('ok', mapResult.get('status'));
    }
    


    @isTest
    public static void testGetValueByType() {
       
        MassUploadObjectController.getValueByType('decimal', '12.2', 'en', 'MM/dd/yyyy');
        MassUploadObjectController.getValueByType('number', '11', 'en', 'MM/dd/yyyy');
        MassUploadObjectController.getValueByType('date', '01/20/2020', 'en', 'MM/dd/yyyy');
        MassUploadObjectController.getValueByType('time', '07:30', 'en', 'MM/dd/yyyy');
    }

    @isTest
    public static void testDateRestrictFormatFromGetValueByType() {
        
        for(String key : formatDate.keySet()) {
            String value = formatDate.get(key);
            MassUploadObjectController.getValueByType('date', value, 'en', key);
        }
    }

    @isTest
    public static void testUploadDealWithMultiDateFormat() {
        
        Integer index = 0;
        for(String key : formatDate.keySet()) {
            setUpMassUploadObject(naDeal);
            String dateMt = formatDate.get(key);

            MassUploadObjectController ctrl = new MassUploadObjectController();
            ctrl = new MassUploadObjectController();
            System.assertEquals(true, ctrl.isLightningReady);

            System.assertEquals(1, listMassUploadSetting.size());
            index ++;
            RecordType partnerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
            Account acc = new Account(EBH_OracleId__c='123456789' + index , Name='Test Acc1 ' + dateMt ,RecordTypeID = partnerRecordType.Id,EBH_PartnerType__c='Shop System');
            insert acc;
            
            Contact con = new Contact(LastName = 'testCountContact',Email='test@gmail.com.test', AccountId = acc.Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
            insert con;
            
            String updatedCsvLeadContent = csvDealContent;        
            
            updatedCsvLeadContent = updatedCsvLeadContent.replace('{!ownerId1}', UserInfo.getUserId());
            updatedCsvLeadContent = updatedCsvLeadContent.replace('{!date}', dateMt);
            
            /*mapResult = MassUploadObjectController.chunkRecords(updatedCsvLeadContent,'en',',',false);
            System.assertEquals('ok', mapResult.get('status'));

            listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
            rowColumns = (List<String>) mapResult.get('rowColumns');*/

            List<List<List<String>>> listAllChunk = convertCSVToListChunk(updatedCsvLeadContent);

            mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'Account:Name:7*Contact:Email:28,29,30,31,32','EBH_Status__c:New',true, key,false,'1','2','3',null,null,null);
            System.assertEquals('ok', mapResult.get('status'));
            listError =  (String[])mapResult.get('listError');

        }
    }
    
    @isTest
    public static void testPreviewUpload() {
        setUpMassUploadObject(naDeal);
        
        MassUploadObjectController ctrl = new MassUploadObjectController();
        System.assertEquals(true, ctrl.isLightningReady);

        System.assertEquals(1, listMassUploadSetting.size());

        RecordType partnerRecordType = ApexUtil.getRecordTypeByName('Account','EBH_Seller');
        Account acc = new Account(EBH_OracleId__c='123456789',Name='Test Acc1',RecordTypeID = partnerRecordType.Id,EBH_PartnerType__c='Shop System');
        insert acc;
        
        Contact con = new Contact(LastName = 'testCountContact',Email='test@gmail.com.test', AccountId = acc.Id, EBH_DataOrigin__c='test',EBH_Status__c='Active');
        insert con;
        
        String updatedCsvLeadContent = csvDealContent; 

        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!ownerId1}', UserInfo.getUserId());
        updatedCsvLeadContent = updatedCsvLeadContent.replace('{!date}', dateFm);

        /*mapResult = MassUploadObjectController.chunkRecords(updatedCsvLeadContent,'en',',',true);
        System.assertEquals('ok', mapResult.get('status'));

        listAllChunk = (List<List<List<String>>>) mapResult.get('listAllChunk');
        rowColumns = (List<String>) mapResult.get('rowColumns');*/
        
        List<List<List<String>>> listAllChunk = convertCSVToListChunk(updatedCsvLeadContent);

        Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepVertical  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Vertical__c');
        Map<String,List<ApexUtil.PicklistEntryWrapper>> pklDepCategory  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Category__c');

        mapResult = MassUploadObjectController.doSaveChunkRecords(listAllChunk[0],rowColumns,0,'en',(Object)massUploadObject,'Account:Name:7*Contact:Email:28,29,30,31,32_Account.Name:7','EBH_Status__c:New',true, 'MM/dd/yyyy',true,'1','2','3',pklDepVertical,pklDepCategory,null);
        System.assertEquals('ok', mapResult.get('status'));
    }
    
     @isTest
    public static void testhandleSendResult() {
    	Test.startTest();
    	MassUploadObjectController.handleSendResult(0,new List<String>{'test error handler'});
    	Test.stopTest();
    }

    private static List<List<List<String>>> convertCSVToListChunk(String csvContent){
        String contentfile = csvContent.replace('\n','');
        OpenCSVParser parser = new OpenCSVParser(',',OpenCSVParser.DEFAULT_QUOTE_CHARACTER, OpenCSVParser.DEFAULT_ESCAPE_CHARACTER,OpenCSVParser.DEFAULT_STRICT_QUOTES, OpenCSVParser.DEFAULT_IGNORE_LEADING_WHITESPACE);
        OpenCSVReader reader = new OpenCSVReader(parser,contentfile,'\r',false);//unix user only \r
        List<List<String>> lstDataRow = reader.readAll();
        rowColumns = lstDataRow[0];
        lstDataRow.remove(0);
        List<List<List<String>>> listAllChunk = new List<List<List<String>>>();
        Integer rowLimit = 1;
        Decimal d = Decimal.valueOf(lstDataRow.size()) / Decimal.valueOf(rowLimit);
        Integer numOfChunk = d.round(System.RoundingMode.CEILING).intValue();
        for(Integer i=0;i<numOfChunk;i++){
            Integer startIndex = i == 0 ? 0 : i*rowLimit;
            Integer endIndex = i==0?rowLimit: (i*rowLimit)+rowLimit;
            endIndex = endIndex > lstDataRow.size()?lstDataRow.size():endIndex;
            
            List<List<String>> listChunk = new List<List<String>>();
            for(Integer j = startIndex;j< endIndex;j++)
            {
                listChunk.add(lstDataRow[j]);
            }
            listAllChunk.add(listChunk);
            
        }
        return listAllChunk;
    }

}