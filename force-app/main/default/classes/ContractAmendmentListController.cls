/*****************************************************************************************************************************
    @ Method:         ContractAmendmentListController
    @ Author:         SRONG TIN
    @ Purpose:        US-0033057
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.07.2025 / SRONG TIN / Created Class
    @                 26.09.2025 / Mony Nou  / US-0033245 - Enhancements to Consolidated Pricing View 
    *****************************************************************************************************************************/
public with sharing class ContractAmendmentListController {

    private final static String contractSoql = 'Select Id From Contract Where Id = :recordId OR EBH_LinkedContract__c = :recordId';
    private final static String pricingSoql = 'Select Id,Status__c,CurrencyIsoCode, EBH_ContractId__r.ContractNumber,EBH_ContractId__r.RecordType.DeveloperName,EBH_ContractId__c,Name,NonCumulative__c,EBH_Site__c,TargetType__c,EBH_MetaCategory__c,EBH_ACPValue__c,EBH_ListingValue__c,EBH_ACPExposure__c,ExposureVIP__c,EBH_ListingExposure__c,EBH_Projected12MGMV__c From EBH_Pricing__c Where EBH_ContractId__c In :contractIds';
    private final static String feeTypeSoql = 'Select Id,RelatedContract__r.ContractNumber, RelatedPricing__c,RelatedContract__c,Name,TypeofFee__c,ListingFormat__c,FeeValue__c,DiscountType__c,PrimarySite__c,RelatedContract__r.RecordType.DeveloperName From FeeType__c Where RelatedContract__c In :contractIds';
    private final static String contractRecordTypeACP = 'EBH_ACP';
    private final static String contractRecordTypeLA = 'EBH_ListingAgreement';
    private final static String contractRecordTypeVIP = 'VIP_Contracts';
    private static Map<String, String> feeTypeMappingTypeOfFee = new Map<String, String>{
        'STORE_SUBSCRIPTION_DISCOUNT' => 'Store Subscription Discount',
        'EBAY_TOP_RATED_SELLER_DISCOUNT' => 'eTRS',
        'FINAL_VALUE_FEE_ORDER_LEVEL_FIXED_FEE' => 'Final Value Fee Order Level Fixed',
        'INSERTION_FEE' => 'Insertion Fees',
        'SUBTITLE_FEE' => 'Subtitle Fee',
        'GALLERY_PLUS_FEE' => 'Gallery Plus Fee',
        'INTERNATIONAL_VISIBILITY_FEE' => 'International Site Visibility',
        'PICTURE_PACK_FEE' => 'Picture Pack Fee',
        'PICTURE_PACK_PLUS_FEE' => 'Picture Pack Plus',
        'BOLD_TITLE_FEE' => 'Bold Title Fee'
    };

    private static Map<String, String> feeTypeMappingListingFormat = new Map<String, String>{
        'AUCTION' => 'Auction',
        'FIXED' => 'Fixed Price',
        'DEFAULT' => 'Default (Fixed Price and Auction)'
    };

    /*****************************************************************************************************************************
    @ Method:         getContractData
    @ Author:         SRONG TIN
    @ Purpose:        US-0033057
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     recordId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.07.2025 / SRONG TIN / Created Method
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String, Object> getContractData(String recordId) {

        Map<String, Object> mResult = new Map<String, Object>();
        try{
            
            // Get contract master/amendment id
            List<Contract> contracts = ApexSafe.query().doQuery(contractSoql,new Map<String, Object> {'recordId' => recordId});
            List<Id> contractIds = new List<Id>();
            for( Contract con:  contracts){
                contractIds.add(con.Id);
            }
            
            // get pricing related records from master / amendment contract
            List<EBH_Pricing__c> pricingList = ApexSafe.query().doQuery(pricingSoql,new Map<String, Object> {'contractIds' => contractIds});
            // get fee type related records from master / amendment contract
            List<FeeType__c> feeTypes = ApexSafe.query().doQuery(feeTypeSoql,new Map<String, Object> {'contractIds' => contractIds});
            List<FeeType__c> feeTypeList = new List<FeeType__c>();
            Map<Id,List<FeeType__c>> pricingFeeMapping = new Map<Id,List<FeeType__c>>();

            for(FeeType__c feeType: feeTypes){

                feeType.TypeofFee__c = feeTypeMappingTypeOfFee.get(feeType.TypeofFee__c);
                feeType.ListingFormat__c = feeTypeMappingListingFormat.get(feeType.ListingFormat__c);

                if(String.isNotBlank(feeType.RelatedPricing__c)){
                    // add fee type to listing
                    if(!pricingFeeMapping.containsKey(feeType.RelatedPricing__c)){
                        pricingFeeMapping.put(feeType.RelatedPricing__c, new List<FeeType__c>{feeType});
                    }else{
                        List<FeeType__c> feeType_list = pricingFeeMapping.get(feeType.RelatedPricing__c);
                        feeType_list.add(feeType);
                        pricingFeeMapping.put(feeType.RelatedPricing__c,feeType_list);
                    }
                }else{
                    // add fee type that not in related with pricing
                    feeTypeList.add(feeType);
                }
            }
            // mapping listing fee type and pricing to data listing
            List<PricingRelatedListWrapper> pricingListWrapper = new List<PricingRelatedListWrapper>();
            List<PricingRelatedListWrapper> pricingFeeTypeRelated = new List<PricingRelatedListWrapper>();
            for(EBH_Pricing__c p: pricingList){
                PricingRelatedListWrapper onePricing = new PricingRelatedListWrapper();
                onePricing.pricing = p;
                onePricing.isACP = p.EBH_ContractId__r.RecordType.DeveloperName == contractRecordTypeACP;
                onePricing.isLA = p.EBH_ContractId__r.RecordType.DeveloperName == contractRecordTypeLA;
                onePricing.isVIP = p.EBH_ContractId__r.RecordType.DeveloperName == contractRecordTypeVIP;
                
                if(pricingFeeMapping.containsKey(p.Id)){
                    onePricing.feeTypes = pricingFeeMapping.get(p.Id);
                    onePricing.isHasRelatedFeeType = true;
                    pricingFeeTypeRelated.add(onePricing);
                }else{
                    pricingListWrapper.add(onePricing);
                }
                
            }
            // all pricing
            pricingFeeTypeRelated.addAll(pricingListWrapper);

            // add record list to mResult
            mResult.put('pricingList',pricingFeeTypeRelated);
            mResult.put('feeTypeList',feeTypeList);
            //mResult.put('contracts',contracts);
            mResult.put('success','true');

        }catch(Exception e){
            mResult.put('success','false');
            EBH_ApexLogger.logError(new List<Exception> { e }, 'ContractAmendmentListController','execute');
        }
        
        return mResult;
    }

    public Class PricingRelatedListWrapper{

        @AuraEnabled public EBH_Pricing__c pricing {get; set;}
        @AuraEnabled public Boolean isHasRelatedFeeType {get; set;}
        @AuraEnabled public Boolean isLA {get; set;}
        @AuraEnabled public Boolean isACP {get; set;}
        @AuraEnabled public Boolean isVIP {get; set;}
        @AuraEnabled public List<FeeType__c> feeTypes {get; set;}
    }
}