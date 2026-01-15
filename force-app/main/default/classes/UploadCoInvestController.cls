/*********************************************************************************************************************************
@ Method:         UploadCoInvestController
@ Version:        1.0
@ Author:         Mony Nou
@ Purpose:        US-0033626 - POP - Ability for Coupon Managers to Upload Coupon Item Exclusions in HIVE 
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  11.12.2025 / Mony Nou / Created the method.
*********************************************************************************************************************************/
public with sharing class UploadCoInvestController implements Callable {
    private static final String TXT_IMPORT_EXCLUSIVE_COINVEST = 'importExcCoInvestPreDML';
    private static final String TXT_METHOD_NOT_IMPLEMENTED = 'Method not implemented';
    private static final String TXT_START_INDEX = 'startIndex';
    private static final String TXT_STATUS = 'status';
    private static final String TXT_LIST_RECORD = 'listRecord';
    private static final String TXT_MAP_INDEX_TO_ERROR_MSG = 'mapIndexToErrMsg';
    private static final String COINVEST_EXCLUSION_RECORDTYPE = 'Coupon_Co_invest_Exclusions';

    /*********************************************************************************************************************************
    @ Method:         importExcCoInvestPreDML
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0033626 - Pre-DML validation for bulk uploading Exclusive Co-Invest records via Excel import
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      mapArgs - Contains listRecord, startIndex, parentId, hasHeader, isExcelImporterV2
    @ Return:         Map<String, Object> - Contains status, listRecord, mapIndexToErrMsg
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    @testVisible
    private Map<String,Object> importExcCoInvestPreDML(Map<String,Object> mapArgs){
        Map<String, Object> mapResult = new Map<String, Object>();
        List<Map<String,String>> listRecord = (List<Map<String,String>>)(JSON.deserialize(JSON.serialize(mapArgs.get(TXT_LIST_RECORD)), List<Map<String,String>>.class));
        
        Integer startIndex = Integer.valueOf(mapArgs.get(TXT_START_INDEX));
        String couponSellerId = String.valueOf(mapArgs.get('parentId'));
        Boolean hasHeader = Boolean.valueOf(mapArgs.get('hasHeader'));
        Boolean isExcelImporterV2 = Boolean.valueOf(mapArgs.get('isExcelImporterV2'));
        
        Map<Integer, String> mapIndexToErrMsg = new Map<Integer, String>();
        
        // Query Record Type once for all records
        RecordType recType = ApexUtil.getRecordTypeByName('Coupon_Co_Invest__c', COINVEST_EXCLUSION_RECORDTYPE);
        
        // Process each record
        for (Integer i = 0; i < listRecord.size(); i++) {
            String errMsg = ''; 
            Integer rowIndex = startIndex + i; // each chunk of record/batch run this method, startIndex tracks where the current index of chunk of record/batch
            // Integer rowNum = rowIndex + 1;
            
            // Validate Item_ID__c is not blank
            String itemId = String.isNotBlank(listRecord[i].get('item_id__c')) ? listRecord[i].get('item_id__c').trim() : '';
            
            if (String.isBlank(itemId)) {
                errMsg = 'eBay Item Id '+Label.ExcelImporter_Label_9; // 'is Required Field.'
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }
            
            // Validate Item_Title__c is not blank
            String itemTitle = String.isNotBlank(listRecord[i].get('item_title__c')) ? listRecord[i].get('item_title__c').trim() : '';
            if (String.isBlank(itemTitle)) {
                errMsg = 'eBay Item Title '+Label.ExcelImporter_Label_9; // 'is Required Field.'
                mapIndexToErrMsg.put(rowIndex, errMsg); continue;
            }
            
            // Prepopulate Coupon Seller lookup field
            listRecord[i].put('Coupon_Seller__c', couponSellerId);
            
            // Assign Record Type ID for Coupon Co-invest Exclusions
            listRecord[i].put('RecordTypeId', recType.Id);
            
            // Add validation logic here in future iterations
        }
        
        mapResult.put(TXT_STATUS, 'ok');
        mapResult.put(TXT_LIST_RECORD, listRecord);
        mapResult.put(TXT_MAP_INDEX_TO_ERROR_MSG, mapIndexToErrMsg);
        
        return mapResult;
    }

    /*********************************************************************************************************************************
    @ Method:         call
    @ Version:        1.0
    @ Author:         Mony Nou
    @ Purpose:        US-0033626 - POP - Ability for Coupon Managers to Upload Coupon Item Exclusions in HIVE
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  11.12.2025 / Mony Nou / Created the method.
    *********************************************************************************************************************************/
    public Object call(String action, Map<String, Object> args) {
        // when class is implemented Callable, method "call" must also be implement.
        if(action == TXT_IMPORT_EXCLUSIVE_COINVEST) { 
            return this.importExcCoInvestPreDML(args);
        }
        else{
            throw new CallableClassException(TXT_METHOD_NOT_IMPLEMENTED);
        }
    }


    private class CallableClassException extends Exception {}
}