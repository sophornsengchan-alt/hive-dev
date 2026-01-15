/*********************************************************************************************************************************
@ Class:          EBH_ExitCodeUploader
@ Version:        1.0
@ Author:         Neha Lund
@ Purpose:        Handler Class for Page EBH_CSVUploader    
                  EPH-5851
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 29.05.2018 / Neha Lund /Created the class
@				: 23.07.2018 / Vadhanak Voun / set withoutsharing to support Standard User
*********************************************************************************************************************************/
global without sharing class EBH_ExitCodeController { 
    
    public String csvData {get;set;}
    public boolean noTargetedSellers {get;set;}
    
    
    public Id filterId;
    /*****************************************************************************************************************************
    @ Constructor:    EBH_ExitCodeController
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        initiates the class                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2018 / NEHA LUND / Created the Constructor.
    *****************************************************************************************************************************/
    public EBH_ExitCodeController(ApexPages.StandardController controller) {
        
        filterId = controller.getId();
        noTargetedSellers = false;
        //If there are no targeted sellers
        if( Database.query('SELECT id from EBH_TargetedSeller__c where EBH_SellerList__c = :filterId Limit 1').isEmpty()){
            noTargetedSellers = true;
        }
        
    }   
    
    /*****************************************************************************************************************************
    @ Method:         createTargetedSellers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        creates the Targeted Seller records                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]:     sellerIds - parsed from CSV uploaded on Seller List Snaphot
                      Id:           parentID
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    global static void createTargetedSellers(String[] sellerIds, Id filterId) {
        
        List<EBH_TargetedSeller__c> updateTargetedSellers = new List<EBH_TargetedSeller__c>();
        
        //to reset the existing ones
        List<EBH_TargetedSeller__c> resetTargetedSellers = new List<EBH_TargetedSeller__c>();
        
        
        for(EBH_TargetedSeller__c ts: Database.query(EBH_ConstantsUtility.EXIT_EXISTINGTARGET )){
            
            ts.EBH_ExitCode__c = EBH_ConstantsUtility.RESET_Code;
            resetTargetedSellers.add(ts);
            
        }
        
        if(!resetTargetedSellers.isEmpty()){
            update resetTargetedSellers;
        }
        
        for(EBH_TargetedSeller__c ts : Database.query(EBH_ConstantsUtility.EXIT_TARGETEDSELLERQUERY)){
            
            ts.EBH_ExitCode__c = EBH_ConstantsUtility.EXIT_Code;
            updateTargetedSellers.add(ts);
        } 
        
        if(!updateTargetedSellers.isEmpty()) {
            //Note: exception handling done in page - remote handling
            Database.update(updateTargetedSellers);
           
           //Calculate Generated Control Group Size on Seller List
           EBH_Filter__c filter = new EBH_Filter__c(ID = filterId);
           filter.EBH_GeneratedControlGroupSize__c = (Database.countQuery(EBH_ConstantsUtility.EXIT_TARGETEDCOUNT)/updateTargetedSellers.size() )*100;
           update filter;
        }
        
       
    }
    
    /*****************************************************************************************************************************
    @ Method:         fetchSellers
    @ Version:        1.0
    @ Author:         NEHA LUND
    @ Purpose:        fetches the valid seller oracle ids and id filtered by param oracle ids/ids                      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      String[]: sellerIds - seller oracle ids or ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Map<String, List<String>>: map of valid seller oracle ids and ids
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    @RemoteAction
    global static Map<String, List<String>> fetchTargetedSellers(String[] sellerIds, String filterId) {
        
        //Sellers oracle id and id map on the Oracle Id/Id
        Map<String, List<String>> sellerMap
            = new Map<String, List<String>> { EBH_ConstantsUtility.CSV_IDS => new List<String>(), 
                                              EBH_ConstantsUtility.CSV_OIDS => new List<String>() };
        
      
            //fetch the sellers and populate the final map of valid sellers
            for(EBH_TargetedSeller__c seller : Database.query(EBH_ConstantsUtility.EXIT_TARGETEDSELLERQUERY)) {
                sellerMap.get(EBH_ConstantsUtility.CSV_IDS).add(seller.EBH_Seller__c);
                sellerMap.get(EBH_ConstantsUtility.CSV_OIDS).add(seller.EBH_Seller__r.EBH_OracleId__c);
            }
        
        sellerMap.put('SIZE', new List<String>{sellerMap.size()+''});
        
        return sellerMap;
    }
    
    
}