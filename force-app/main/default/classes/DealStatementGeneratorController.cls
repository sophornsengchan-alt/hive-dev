/*********************************************************************************************************************************
@ Class:          DealStatementGeneratorController
@ Version:        1.0
@ Author:         Sovantheany Dim (sovantheany.dim@gaea-sys.com)
@ Purpose:        US-0010376 - [NA Deal Statement] Monthly Statement Summary and Approval
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 14.10.2021 / Sovantheany Dim / Created the class.       
@                 07.09.2023 / Mony Nou / US-0013897 - Deals Mass Payment File Generation (US/IT)         
*********************************************************************************************************************************/
public with sharing class DealStatementGeneratorController {
    private final static String SOQL_DEALSTATEMENT = 'select id[PLACEHOLDER] from Deal_Statement__c';
    //MN-07092023-US-0013897: Added Deal_Site__c to query
    private final static String SOQL_DEALSTATEMENTSUMMARY = 'select Deal_Site__c, Summary_Name__c, Month__c, Year__c, Statement_Type__c, id from Deal_Statement_Summary__c';
    private static Map<String,String> mapField_Type = new Map<String,String>{
        '1st Statement'=>'X1st_Statement_Approved__c',
        'Final Statement'=>'Final_Statement_Approved__c',
        'Adjusted Statement'=>'Adjustment_Approved__c'
    };
    //MN-07092023-US-0013897: Added eBay_Seller__r.NA_Deals_Subsidy_PayPal_Email__c to query
    private static set<String> sFields = new set<String>{'eBay_Seller__r.NA_Deals_Subsidy_PayPal_Email__c','eBay_Seller__r.Name','Month__c','Year__c','Initial_Payout__c','Total_Paid_Out__c','Subsidy_30_Day_Calculation__c','Amount_Held_Back__c','Subsidy_Final_Calculation__c','Second_Payout__c','Disputes_Payout__c'};
    private static Map<String,String[]> mapHeaderCol = new Map<String,String[]>
    {
    	'US'=>new String[]{'\uFEFFeBay Seller:Business Name','Month','Year','Initial Payout (60%)','Total Paid Out','Subsidy 30 Day Calculation','Subsidy Amount Held Back (40%)','Subsidy Final (60-Day) Calculation','Subsidy Final Payout','Adjusted Payout'}
    };

    //MN-07092023-US-0013897: Paypal Statement Excel Header with customized Style
    private static Map<String, List<String>> mapPaypalStatementHeader = new Map<String, List<String>> {
        'US' => new List<String>{'\uFEFFeBay Seller Paypal id__!!__b_yellow', 'Amount__!!__b_yellow','Promo Name__!!__b_yellow','Message__!!__b_yellow'},
        'IT' => new List<String>{'\uFEFFeBay Seller Paypal id__!!__b_yellow', 'Amount__!!__b_yellow','Promo Name__!!__b_yellow','Message__!!__b_yellow'}
    };

    //MN-07092023-US-0013897
    private static Map<String, Integer> mapPaymentThreshold = new Map<String, Integer> {
        'US' => 100000,
        'IT' => 8000
    };
    
    //MN-07092023-US-0013897
    private static Map<String, String> mapSiteCurrency = new Map<String, String> {
        'US' => 'USD',
        'IT' => 'EUR'
    };
    /*****************************************************************************************************************************
	@ Method:   generateToExcel
	@ Version:  1.0
	@ Author:   Sovantheany Dim (sovantheany.dim@gaea-sys.com)
	@ Purpose:  US-0010376 - [NA Deal Statement] Monthly Statement Summary and Approval
	@			Summary Excel will use Month, Year and Statement Type to select Deal Statements to be selected for the file. Only Deal Statements which match Month, Year and the fields in AC1 matching the Statement Type will be included. If AC1 field is FALSE, then that Statement is excluded.
	@			AC5) If no matching Deal Statements for the criteria is found. System will give error message: 'No Deal Statements found for this Summary'
	@			AC5) If Excel file is successfully generated. Deal Statement Summary 'Status' field will be updated to 'Ready for Approval' and Excel file is attached to the Deal Statement Summary record.
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 14.10.2021/ Sovantheany Dim / Created the  Method.
	*****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> generateToExcel(String parentId) {
        Map<String, Object> mResult = new Map<String, Object>();
        List<Attachment> lstAttach = new List<Attachment>();
        String key = 'US';
        String[] listHeader = mapHeaderCol.containsKey(key)?mapHeaderCol.get(key):null;
        List<List<String>> listRows = new List<List<String>>{listHeader};
        try{
            //get deal statement summary
            String month = '';
            String year = '';
            String where_Type = '';
            String dssName = '';
            String dealSite; //MN-07092023-US-0013897

            for(Deal_Statement_Summary__c dss : Database.query(SOQL_DEALSTATEMENTSUMMARY+' where id =: parentId')){
                month = dss.Month__c;
                year = dss.Year__c;
                if(!String.isEmpty(dss.Statement_Type__c) && mapField_Type.containsKey(dss.Statement_Type__c)) where_Type += ' AND '+mapField_Type.get(dss.Statement_Type__c)+' = true';
            	dssName = dss.Summary_Name__c;
                dealSite = dss.Deal_Site__c; //MN-07092023-US-0013897
            }
            //convert Year from string to integer
            Integer year_int = Integer.valueOf(year);
            String fields = ','+String.join(new List<String>(sFields),',');
            String soql_dealstatement2 = SOQL_DEALSTATEMENT.replace('[PLACEHOLDER]', fields).replace('Month__c','toLabel(Month__c)');
            boolean hasDealStement = false;
            List<Deal_Statement__c> lstDS = new List<Deal_Statement__c>(); //MN-07092023-US-0013897
            //get Deal Statement
            //MN-07092023-US-0013897:Add criteria Site into below query
            for(Deal_Statement__c ds : Database.query(soql_dealstatement2+' where toLabel(Site__c)=:dealSite AND Month__c =: month AND Year__c =: year_int'+where_Type)){
            	hasDealStement = true;
                List<String> listCells = new List<String>();
                for(String f : sFields){
                    if (f == 'eBay_Seller__r.NA_Deals_Subsidy_PayPal_Email__c') continue; //MN-13092023-US-0013897: This field only for PayPal Statement Excel File
                    listCells.add(getFieldValue(f,ds,'UK'));
                }
                listRows.add(listCells);
                lstDS.add(ds); //MN-07092023-US-0013897
            }
            if(hasDealStement){
                //update Deal Statement Summary 'Status' to 'Ready for Approval'
                Deal_Statement_Summary__c dssReadyForApproval = new Deal_Statement_Summary__c(id=parentId ,Status__c = 'Ready for Approval');
              	update dssReadyForApproval;
                //generate to excel file
                List<ExcelGenerator.xSheet> listSheets = new List<ExcelGenerator.xSheet>();
                ExcelGenerator.xSheet sheetSTP = new ExcelGenerator.xSheet('Sheet1',listRows);
                listSheets.add(sheetSTP);
                ExcelGenerator generator = new ExcelGenerator(userinfo.getname(),listSheets);
                generator.generateWorkBook();
                String xml = generator.getWorkbookXML();
                String fileName = dssName+'.xls';
                //attached Excel file  to the Deal Statement Summary record
                Attachment attach = createAttachment(Blob.valueOf(xml), filename,'application/vnd.ms-excel', parentId);
                lstAttach.add(attach);

                //MN-07092023-US-0013897
                Attachment attachPaypalStat = createPaypalStatementFile(lstDS, 'application/vnd.ms-excel', parentId, dealSite);
                lstAttach.add(attachPaypalStat);

                insert lstAttach;
                mResult.put('isSuccess', true);
                mResult.put('msg', System.label.successAddFile_msg);  
            }else{
               	mResult.put('isSuccess', false);
           		mResult.put('msg', System.label.failAddFile_msg); 
            }
        }catch (Exception ex) { mResult.put('isSuccess', false);mResult.put('msg', ex.getMessage());}
        return mResult;
    }
    
    private static Attachment createAttachment(Blob body, String fileName,String contentType, Id parentId) {
        Attachment att = new Attachment();
        att.Body = body;
        att.Name = fileName;
        att.IsPrivate = false;
        att.ContentType = contentType; 
        att.ParentId = parentId;
        return att;
    }
    private static Map<String,Schema.DisplayType> mapFieldType = new Map<String,Schema.DisplayType>
    {
    	'Deal_Statement__c:Initial_Payout__c' => Schema.DisplayType.Double,
    	'Deal_Statement__c:Total_Paid_Out__c' => Schema.DisplayType.Double,
    	'Deal_Statement__c:Subsidy_30_Day_Calculation__c' => Schema.DisplayType.Double,
    	'Deal_Statement__c:Amount_Held_Back__c' => Schema.DisplayType.Double,
    	'Deal_Statement__c:Subsidy_Final_Calculation__c'=> Schema.DisplayType.Double,
    	'Deal_Statement__c:Second_Payout__c' => Schema.DisplayType.Double,
        'Deal_Statement__c:Disputes_Payout__c' => Schema.DisplayType.Double
    };
    private static String getFieldValue(String fieldName,Sobject sobj,String revRoll)
    {
    	//System.debug('>>>fieldName: '+fieldName);
    	Object val = ApexUtil.getValue(fieldName,sobj);
    	if(val==null)
    	{
    		return '';
        }else{
            if(!mapFieldType.containsKey(sobj.getSObjectType()+':'+fieldName)){
            	return val+''; 
        	}
            Schema.DisplayType fType =  mapFieldType.get(sobj.getSObjectType()+':'+fieldName);
            if(Schema.DisplayType.Percent ==fType)
            {
                //return val +' %';
                return ApexUtil.formatNumber((Decimal)val,2,revRoll)+' %';
            }else if(Schema.DisplayType.Date ==  fType)
            {
                return ((Date)val).format();
            }else if(Schema.DisplayType.DateTime == fType)
            {
                return ((DateTime)val).format();
            }else if(Schema.DisplayType.Currency == fType|| Schema.DisplayType.Integer == fType  || Schema.DisplayType.Double == fType ||  Schema.DisplayType.Long == fType)
            {
                return ApexUtil.formatNumber((Decimal)val,2,revRoll);
            }
        }
    	return val+''; 
    }
    
    /*****************************************************************************************************************************
	@ Method:   createPaypalStatementFile
	@ Version:  1.0
	@ Author:   Mony Nou (mony.nou@gaea-sys.com)
	@ Purpose:  US-0013897 - Deals Mass Payment File Generation (US/IT)
    @           + Create an additional excel file with name =  Month, Year Paypal Statement
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 07.09.2023 / Mony Nou / Created the  Method.
	*****************************************************************************************************************************/
    public static Attachment createPaypalStatementFile(List<Deal_Statement__c> lstDS, String contentType, Id parentId, String site) {

        List<String> lstHeader = mapPaypalStatementHeader.get(site);
        Integer paymentThreshold = mapPaymentThreshold.get(site);
        List<List<String>> listRows = new List<List<String>>{lstHeader};

        String formatPromoName = System.Label.PaypalStatement_Col_PromoName;
        String formatMessage = System.Label.PaypalStatement_Col_Message;
        String formatFileName = System.Label.PaypalStatement_Col_FileName;
        String currencySign = ApexUtil.mapCurrencySign.get(mapSiteCurrency.get(site));

        Decimal total = 0;

        for (Deal_Statement__c ds : lstDS) {

            //AC4) First we need to check Total Payout to see if it exceeds Payment Threshold => it needs to broken down into multiple lines.
            //Example – If Deal Site = US and Total Payout = $230k in Deals subsidies => Payment Threshold = 100k => the payments to be broken into 3 payments (meaning 3 rows in excel file)
            Integer rowNo = Integer.valueOf(ds.Total_Paid_Out__c/paymentThreshold);
            rowNo += (ds.Total_Paid_Out__c > (paymentThreshold * rowNo))?1:0; //Since there is no Math.mod for Decimal then we have to manually check the remainder for division.

            String eBaySellerPaypalId = ds.eBay_Seller__r.NA_Deals_Subsidy_PayPal_Email__c;
            String promoName = formatPromoName.replace('{Month__c}', ds.Month__c).replace('{Year__c}', String.valueOf(ds.Year__c));
            String message = formatMessage.replace('{eBay_Seller__r.Name}', ds.eBay_Seller__r.Name).replace('{Month__c}', ds.Month__c);

            formatFileName = formatFileName.replace('{Month__c}', ds.Month__c).replace('{Year__c}', String.valueOf(ds.Year__c));

            for (integer i=0; i<rowNo; i++) {

                List<String> lstCells = new List<String>();
                
                Decimal rowTotalPayout = (i==0)?(ds.Total_Paid_Out__c - (paymentThreshold * (rowNo-1))):paymentThreshold;

                lstCells.add(eBaySellerPaypalId); 
                lstCells.add(currencySign + ' ' + ApexUtil.formatNumber(rowTotalPayout,2,site)+'');
                lstCells.add(promoName);
                lstCells.add(message);

                listRows.add(lstCells);

            }

            total += ds.Total_Paid_Out__c;
        }

        List<String> lstTotalCells = new List<String>();
        lstTotalCells.add('Total__!!__f_bold');
        lstTotalCells.add(currencySign + ' ' + ApexUtil.formatNumber(total,2,site)+'__!!__f_bold');
        listRows.add(lstTotalCells);

        List<ExcelGenerator.xSheet> listSheets = new List<ExcelGenerator.xSheet>();
        ExcelGenerator.xSheet sheetSTP = new ExcelGenerator.xSheet('Sheet1',listRows);
        listSheets.add(sheetSTP);
        ExcelGenerator generator = new ExcelGenerator(userinfo.getname(),listSheets, true);
        generator.generateWorkBook();
        String xml = generator.getWorkbookXML();
        String fileName = formatFileName+'.xls';

        Attachment att = new Attachment();
        att.Body = Blob.valueOf(xml);
        att.Name = fileName;
        att.IsPrivate = false;
        att.ContentType = contentType; 
        att.ParentId = parentId;
        return att;

    }

}