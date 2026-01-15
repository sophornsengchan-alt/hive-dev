/*********************************************************************************************************************************
@ Class:          CustomerController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  08.01.2024 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public with sharing class CustomerController {


    /*********************************************************************************************************************************
    @ Method:         unlinkParentLegalEntity
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014518 - Allow Users to Unlink Deleted Sellers from Legal Entity Legal
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  08.01.2024 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    @AuraEnabled
    public static  Map<String, Object> unlinkParentLegalEntity(String sellerId){

        Savepoint sp = Database.setSavepoint();
        Map<String, Object> mapResult = new Map<String, Object>();
        try{
            AccountUpdateHelper.unlinkParentLegalEntity(sellerId);
            mapResult.put('status', 'ok');
        }catch(Exception ex){
            Database.rollback(sp); 
            mapResult.put('status', 'ko');
            mapResult.put('error', ex.getMessage());
            EBH_ApexLogger.logError(new List<Exception> { ex }, 'CustomerController','unlinkParentLegalEntity');
        }
        
        return mapResult;
    }
}