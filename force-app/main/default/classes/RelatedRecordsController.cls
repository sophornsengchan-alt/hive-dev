/*********************************************************************************************************************************
@ Class:         RelatedRecordsController
@ Version:       1.0
@ Author:        vadhanak voun (vadhanak.voun@gaea-sys.com)
@ Purpose:       US-0009768 - [Pro-Trader] New Home Page - Charts,Detail and BoB Categories component to be added
@                   - Controller for aura: RelatedRecords
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	27.06.2021 / vadhanak voun (vadhanak.voun@gaea-sys.com) / Created the class.
*********************************************************************************************************************************/
public with sharing class RelatedRecordsController {

    @AuraEnabled
    public static Map<String,Object> apexInit(String soql,String soqlWhere,String recordId,String orderBy,String sobjectName)
    {
        //System.debug('---recordId: '+recordId);
         String fullSoql = soql + soqlWhere+orderBy;
         String soqlCount = 'Select count() FROM '+sobjectName +soqlWhere;
         Integer totalRecord = Database.countQuery(soqlCount);
         List<SObject> listRows = Database.query(fullSoql);

         return new Map<String,Object>{
             'status'=>'ok',
             'totalRecord'=>totalRecord,
             'listRows'=>listRows
         };

    }
     
}