/*********************************************************************************************************************************
@ Class:          DealListViewFilterControllerTest
@ Version:        1.0
@ Author:         Sochettra Saing
@ Purpose:        Ability to run test the logic in class DealListViewFilterController(EBAY-756)
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 25.10.2021 / Sochettra Saing / Created the class.
*********************************************************************************************************************************/

@IsTest 
private class DealListViewFilterControllerTest {

    static String objAPIName = 'EBH_Deal__c';
    static List<String> field_names= new List<String>{'EBH_ReasonforRejection__c'};
    
    @IsTest
    static void testGetAllPickListValue(){
        Test.startTest();
        Map<String, List<DealListViewFilterController.SelectOptionObj>> allPickListValue = DealListViewFilterController.getAllPickListValue(objAPIName,field_names,'77');
        //System.debug('>>>>>> allPickListValue:'+ allPickListValue);
        // System.assert(allPickListValue.get('Seller_Portal_Status__c').size() > 0); // Sambath Seng - 15/01/2024 - US-0013136
        DealListViewFilterController.metadaWrapperClass filterFieldsMetadata =  DealListViewFilterController.filterFieldsMetadata(objAPIName, 'DE_Created_Today'); //MN-08112021-US-0010640 - Pass value to new param
        //System.debug('>>>>>> filterFieldsMetadata:'+ filterFieldsMetadata);
        List<Seller_Portal_List_View_Filter__mdt> allCMT = filterFieldsMetadata.fieldsMetadata;
        String userLanguage = filterFieldsMetadata.userLanguage;
        System.assert(allCMT.size() > 0);
        System.assert(userLanguage != '');
        //en_US
        //System.debug('>>>>>> allCMT:'+ allCMT);
        //System.debug('>>>>>> userLanguage:'+ userLanguage);
        DealListViewFilterController.PickListWrapperClass objPicklistWrapper = new DealListViewFilterController.PickListWrapperClass();
        List<EBH_Deal__c> statusOptions = objPicklistWrapper.statusOptions;
        List<EBH_Deal__c> getRejectionReason = objPicklistWrapper.getRejectionReason;
        List<EBH_Deal__c> getDealFormat = objPicklistWrapper.getDealFormat;
        
        Test.stopTest();
    }
}