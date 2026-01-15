/*********************************************************************************************************************************
@ Class:          CreateNewPricingController
@ Version:        1.0
@ Author:         LoumAng SENG (loumang.seng@gaea-sys.com)
@ Purpose:        US-0008204 - [Contracts] New Custom Button "Create New Pricing" in Contracts Detail Page
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.03.2021 / LoumAng SENG / Created the class.
@               : 21.05.2024 / Sambath Seng / US-0015201 - Create new VIP Pricing record type
*********************************************************************************************************************************/
public without sharing class CreateNewPricingController {
    private final static Map<String, String> MAP_FNAME_PRICING_CONTRACT = new Map<String, String>{
        'EBH_ContractId__c' => 'Id'
   	};
    private final static Map<String, String> MAP_PRICINGVERSION_RT = new Map<String, String>{
        'P1.0' => 'EBH_ListingPricing',
        'P2.0' => 'Listing_Pricing_P2_0'
    };

    private final static String FNAME_PRICE_VERSION = 'PricingVersion__c';
    private final static String FNAME_EBH_PRICING = 'EBH_Pricing__c';


    private final static Map<String, String> MAP_RT_CONTRACT_PRICING = new Map<String, String>{
        'EBH_ACP' => 'EBH_ACPTargets',
        'EBH_RevenueShare' => 'EBH_RevenueShareTargets',
        'VIP_Contracts' => 'VIP_Pricing' // SB 21.05.2024 US-0015201
    };
        
    @AuraEnabled
    public static Map<String, Object> doCreatePricing(String recordId) {
        Map<String, Object> mResult = new Map<String, Object>();

        try{
            String queryStr = 'SELECT RecordType.DeveloperName,' + FNAME_PRICE_VERSION + ',' + String.join((Iterable<String>)MAP_FNAME_PRICING_CONTRACT.values(), ',') +' FROM Contract WHERE Id =: recordId LIMIT 1';
            Contract contr = Database.query(queryStr);
            Map<String, Object> mField = new Map<String, Object>();
            
            for(String pricingField : MAP_FNAME_PRICING_CONTRACT.keySet()){

                Object ctFieldVal = contr.get(MAP_FNAME_PRICING_CONTRACT.get(pricingField));
                if(ctFieldVal == null) continue;
                mField.put(pricingField, ctFieldVal);
            }

            String rtContr = String.valueOf(contr.getSObject('RecordType').get('DeveloperName'));
            String rtPricing;
            if(MAP_RT_CONTRACT_PRICING.containsKey(rtContr)){
                rtPricing = MAP_RT_CONTRACT_PRICING.get(rtContr);
            }else{
                rtPricing = MAP_PRICINGVERSION_RT.get(String.valueOf(contr.get(FNAME_PRICE_VERSION)));
            }
            
            
            mResult.put('recordTypeId', ApexUtil.getRecordTypeByName(FNAME_EBH_PRICING, rtPricing).Id);
            mResult.put('params', mField);
            mResult.put('isSuccess', true);
        } catch (Exception ex) {
            mResult.put('isSuccess', false);
            mResult.put('msg', ex.getMessage());
        }

        return mResult;
    }
        

}