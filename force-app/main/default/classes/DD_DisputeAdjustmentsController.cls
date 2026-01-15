/**
Currently, there is a static lightning component called DisputeReconiliation that needs to be coded 

1 - Update the naming to be DisputeAdjustments 
2 - Update button name on Deal Statement to say Adjustments 
3 - create two field sets on Deal: 
Deal Adjustment 1st statement: 
Listing Id, Item Description, Start Date/Time, Start End/Time, Subsidy, Sold Items 30 days, Subsidy Due 30 days 
Deal Adjustment 2nd statement: 
Listing Id, Item Description, Start Date/Time, Start End/Time, Subsidy, Sold Items 30 days, Subsidy Due 30 days, Sold Items 60 Days, Subsidy Due 60 Days 
4 - Make Lightning page dynamic as follows: 

Page Title should be Deal Statement Name 

Bring in Deal Statement Id and query for Deals related to that ID 

If Deal Statement Status is '1st Statement' - use Deal Adjustment 1st Statement 
if Deal Statement Status is '2nd Statement' use Deal Adjustment 2nd Statement 
Listing Id should be hyperlinked to the Deal record 
All field are read only 
Additional editable fields for Sold_Items_Disputes__c, Dispute_Approval_Comments__c both fields are required for a line item if one is entered. 

Remove drop down icon next to each line item. Replace Approval All & Reject All buttons with Save and Cancel. Save Updates the relevant records that had information populated. Cancel returns records to previous page

*/
/*********************************************************************************************************************************
@ Class:          DD_DisputeAdjustmentsController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0009180 - [NA] Migrate Disputes Microsite for Seller Case creation
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.04.2021 /Vadhanak Voun/ Migrated from join-instance
*********************************************************************************************************************************/
public without sharing class DD_DisputeAdjustmentsController {
    static Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
    
    
    public class ColData {
        @AuraEnabled public string value {set; get;}
        @AuraEnabled public string colApiName {set; get;}
        
        @AuraEnabled public boolean required {set; get;}
        @AuraEnabled public string colDisplayType {set; get;}
        @AuraEnabled public boolean display {set; get;}       
        @AuraEnabled public String colmax {set; get;}
        @AuraEnabled public boolean disabled {set; get;}
        
        
    } 
    
    public class RowData {
        
        @AuraEnabled public ColData[] rowData {set; get;}
        @AuraEnabled public String recordid {set; get;}
        
        
        
        public RowData(EBH_Deal__c deal, Schema.FieldSetMember[] flst, boolean soldItemDisputeisEmpty) {
            rowData = new List<ColData>(); 
            for(Schema.FieldSetMember f: flst){
                ColData coldata = new ColData();
                coldata.value = deal.get(f.getFieldPath()) == null ? '' : String.valueOf(deal.get(f.getFieldPath()));
                coldata.colApiName = f.getFieldPath();
                coldata.required = false;
                coldata.display = true;
                coldata.disabled = true;
                   
                if (soldItemDisputeisEmpty && coldata.colApiName=='Sold_Items_Further_Disputes__c') { coldata.display = false; }
                
                if (deal.Dispute_Type__c == 'Quantity Variance' && coldata.colApiName == 'Sold_Items_Disputes__c')
                    //(coldata.colApiName == 'Sold_Items_Disputes__c' || coldata.colApiName == 'Dispute_Approval_Comments__c'))
                { coldata.disabled = false;  }
                
                if (coldata.colApiName == 'Dispute_Approval_Comments__c') { coldata.disabled = false; }
                
                if ( deal.Dispute_Type__c == 'Subsidy Per Unit' && coldata.colApiName == 'Subsidy_per_Unit_Disputes__c') {
                    coldata.display = false;
                    coldata.disabled = false;
                }
                
                if ( deal.Dispute_Type__c == 'Quantity Variance;Subsidy Per Unit' && coldata.colApiName == 'Subsidy_per_Unit_Disputes__c' 
                    || deal.Dispute_Type__c == 'Quantity Variance;Subsidy Per Unit' && coldata.colApiName == 'Sold_Items_Disputes__c') {
                    coldata.display = false;
                    coldata.disabled = false;
                }
                
                rowData.add(coldata);
            }
        }
    } 
    
    /**
    * constructor
    * @params  String fieldApiName
    * @params  String fieldLabel
    * @params  Schema.DisplayType fieldDataType
    * @params  List<String> fieldValues
    */ 

    
    @AuraEnabled
    public static Map<String, Object> getDeals(String recId){                            
         try {
            Map<String, Object> mpRes = new Map<String, Object>{'isSuccess' => true, 'message'=> 'success'};
            Schema.SObjectType convertType = gd.get('EBH_Deal__c');
            
            List<Map<String, Object>> labels = new List<Map<String, Object>>();
            Map<String, Schema.FieldSet> fieldSetNameMapToFieldSet = convertType.getDescribe().fieldSets.getMap();          
            Schema.FieldSetMember[] flst = fieldSetNameMapToFieldSet.get('Deal_Disputes').getFields();
            String query = 'SELECT ';
            for(Schema.FieldSetMember f: flst){
                    query += f.getFieldPath() + ', ' ;
                labels.add(new Map<String, Object>{'Label' => f.getLabel(), 'Width' => '100'});
            }
            String valueNA = 'N/A'; 
            String valueEmpty = '';

            query += 'Id FROM EBH_Deal__c WHERE Deal_Statement__c =: recId AND ((Dispute_Status__c !=:valueNA AND Dispute_Status__c !=: valueEmpty) oR Dispute_Type__c !=: valueEmpty)';

            List<EBH_Deal__c> dealLst = Database.query(query); 
             
            RowData[] rowLst = new List<RowData>();
            for (EBH_Deal__c deal : dealLst) {
                
                RowData rd = new RowData(deal,flst,deal.Sold_Items_Disputes__c==null);
                
                rd.recordid = deal.Id;
                rowLst.add(rd);
            }
            
            mpRes.put('label', labels);
            mpRes.put('dealList', rowLst);
            
            return mpRes;
        } catch(Exception ex) { throw new AuraHandledException(ex + ' : ' + ex.getStackTraceString()); }
    }   
    
    
    @AuraEnabled
    public static Map<String, Object> save(String rowdatajson){
        
        try {
            
            Map<String, Object> mpRes = new Map<String, Object>{'isSuccess' => true, 'message'=> 'success'};
            
            List<RowData> row =  (List<RowData>)JSON.deserialize(rowdatajson, List<RowData>.class);
            
            System.debug('>> ' + row );
            List<EBH_Deal__c> ds2update = new List<EBH_Deal__c>();
            
            for (RowData d : row) {

                 EBH_Deal__c ds = new EBH_Deal__c();
                 ds.Id = d.recordId;
                                
                for (ColData cd : d.rowData) {
                        
                    if (cd.colApiName=='Dispute_Approval_Comments__c') {
                        ds.Dispute_Approval_Comments__c = cd.value;
                    }  else if (cd.colApiName=='Sold_Items_Disputes__c') {
                        
                        try {
                            ds.Sold_Items_Disputes__c = Decimal.valueOf(cd.value);
                        } catch (TypeException e) {
                           ds.Sold_Items_Disputes__c = null;
                        }

                    } else if (cd.colApiName=='Sold_Items_Further_Disputes__c') {
                        
                            try {
                            ds.Sold_Items_Further_Disputes__c = Decimal.valueOf(cd.value);
                        } catch (TypeException e) {
                           ds.Sold_Items_Further_Disputes__c = null;
                        }
                    }
                    
                    if (cd.colApiName=='Subsidy_per_Unit_Disputes__c' && cd.value != '') {
                        ds.Subsidy_per_Unit_Disputes__c = Decimal.valueOf(cd.value);
                    }
                    if  (cd.colApiName=='Dispute_Status__c' && cd.value != '') {
                        ds.Dispute_Status__c = cd.value;
                    }
                        
                    
                }
                    ds2update.add(ds);
                
            }
            
            if (!ds2update.isEmpty()) {
                update ds2update;
            }
            
            return mpRes;
        
         } catch(Exception ex) { throw new AuraHandledException(ex + ' : ' + ex.getStackTraceString()); }
        

    }
    
    
    @AuraEnabled
    public static Map<String,List<String>> getPicklistValueData(List<String> picklistObjs, List<String> picklistFields) {
    	Map<String,List<String>> fieldValues = new Map<String,List<String>>();
    	try{
			Map<String,Schema.SObjectField> propertySObject = getSObjectField(picklistObjs[0]);
			for(String oneField: picklistFields){
				List<String> optionlist = new List<String>();
	        	List<Schema.PicklistEntry> picklistValues;
	        
					//System.debug('property === ' + propertySObject.get(oneField));
				picklistValues = propertySObject.get(oneField).getDescribe().getPickListValues();
				
				for (Schema.PicklistEntry p: picklistValues) {
		            optionlist.add(p.getValue());
		        }

		        fieldValues.put(oneField,optionlist);
	        
			}
			
		} catch(Exception e){ System.debug(LoggingLevel.Error, 'ERROR ' + e); AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString()); auraError.setMessage(e.getMessage() + e.getStackTraceString()); throw auraError; }
        
    	return fieldValues;
    }

    public static Map<String,Schema.SObjectField> getSObjectField(String obj){
    	
    	Map<String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
            Schema.SObjectType sobjType = gd.get(obj);
            Schema.DescribeSObjectResult r = sobjType.getDescribe();
            Map<String,Schema.SObjectField> M = r.fields.getMap();
    	return M;
    }
}