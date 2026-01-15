/*********************************************************************************************************************************
@ Class:          EBH_PricingTriggerHandler
@ Version:        1.0
@ Author:         NEHA LUND 
@ Purpose:        Handler Class for Pricing Trigger
                  EPH-6 : Contract Management
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18.05.2017 / NEHA LUND / Created the class.
@ Change history: 24.05.2018 / David Herrero / Update method hasPricingMatrixChanged for taking in consideration when category changes
                  24.05.2018 / Neha Lund / Default FVF Cap to null before calculating it for metacategories
                  31.05.2024 / Sambath Seng / US-0015367 - Auto calculate VIP Contract value and Exposure
                  03.07.2024 / LoumAng SENG / US-0015413 - VIP Pricing Threshold fields
                  13.08.2024 / LoumAng SENG / US-0015451 - VIP Types - Flat rate and P&A
                  09.01.2025 / Sambath Seng / US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
                  11.03.2025 / Sambath Seng / US-0016887 - Manual Contract Exposure Field for Flat Rate Contracts
                  25.09.2025 / Sovantheany Dim / US-0033097 - eBay Live: Feedback Enhancements
                  02.12.2025 / Leon Morocki / US-0033985 - Correct Pricing Timestamp for Daylight Savings on Hive
*********************************************************************************************************************************/

public without sharing class EBH_PricingTriggerHandler {
    
    public final static String PRICING_REC_P2 = 'Listing_Pricing_P2_0'; //NK:28/07/2020: US-0007883
    public static final String CONTRACT_LISTINGRECORDTYPE       = 'EBH_ListingAgreement';
    public static final String CONTRACT_ACPRECORDTYPE           = 'EBH_ACP';
    public static final String CONTRACT_RSRECORDTYPE            = 'EBH_RevenueShare';   
    public static final String CONTRACT_VIPRECORDTYPE           = 'VIP_Contracts'; // SB 31.05.2024 US-0015367
    public static final String PRICING_VIPRECORDTYPE            = 'VIP_Pricing'; // SB 31.05.2024 US-0015367
    public static final String CONTRACT_FVFDISCOUNTRECORDTYPE = 'FVF_Discount_Contract'; //TH:US-0033097: Allow automation for FVFDscount record type
    private static final String QUARTERLY_TARGETTYPE            =  'Quarterly'; // LA-13.08.2024-US-0015451
    public final static String CONTRACT_SOQL = 'SELECT Id, Status FROM Contract'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_STATUS_PRICING_CONFIGURATION = 'Pricing Configuration'; // SB 09.01.2025 US-0016114

    private final static String CONTRACT_RECORDTYPE_VIP = 'VIP_Contracts'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RECORDTYPE_LA = 'EBH_ListingAgreement'; // SB 09.01.2025 US-0016114
    private final static String CONTRACT_RECORDTYPE_ACP = 'EBH_ACP'; // SB 09.01.2025 US-0016114
    private final static Set<String> CONTRACT_RECORDTYPE_FOR_PRICING_CONFIGURATION = new Set<String>{
        CONTRACT_RECORDTYPE_VIP,
        CONTRACT_RECORDTYPE_LA,
        CONTRACT_RECORDTYPE_ACP
    };
    private final static String CONTRACT_DICSOUNTTYPE_FLATRATE = 'Flat rate'; // SB 11.03.2025 0016887
    public static final String CONTRACT_PRICINGCONTRACTQUERY 
    = ' SELECT GMVTarget__c,TargetType__c,StartDate,EndDate,id, EBH_ContractExposure__c,CurrencyISOCode,EBH_Site__c,EBH_IncrementalGMVonly__c, EBH_AverageTakeRate__c, EBH_StoreSubscription__c, '
    + ' EBH_ContractValue__c, RecordType.DeveloperName, EBH_RebateTierrebate__c, EBH_RevenueShareRate__c, EBH_OnBoardingFees__c,AM_Bolt_on__c, VolumeBasedDiscount__c, DiscountType__c, ManualContractExposure__c,'
    + '(SELECT Id,FVFBaseRate504__c,ExposureVIP__c, EBH_GMVTarget__c ,CurrencyISOCode, EBH_ListingExposure__c, EBH_ListingValue__c, EBH_ACPValue__c, EBH_ACPExposure__c,TargetType__c, '
    + ' EBH_RevenueExposure__c, EBH_PriorYearGMV__c, EBH_RevenueValue__c, EBH_StoreSubscription__c, '
    + ' EBH_Site__c, RecordType.DeveloperName, '
    //+ ' Up_to_GMV_Tier_1__c, Between_GMV_Tier_1_and_2__c, Between_GMV_Tier_2_and_3__c, Between_GMV_Tier_3_and_4__c, Over_GMV_Tier_5__c, ' // SB 31.05.2024 US-0015367. // LA-03-07-2024-US-0015413
    + ' GMVThreshold0__c,GMVThreshold1__c,GMVThreshold2__c,GMVThreshold3__c,GMVThreshold4__c,GMVThreshold5__c, ' // LA-03-07-2024-US-0015413
    + ' Tier_0_bps_Discount__c, Tier_1_bps_Discount__c, Tier_2_bps_Discount__c, Tier_3_bps_Discount__c, Tier_4_bps_Discount__c, Tier_5_bps_Discount__c ' // SB 31.05.2024 US-0015367
    + ' FROM EBH_Pricing__r) from Contract where id IN :parents ';   

    public static final String CONTRACT_PARENTCHILDQUERY 
        = 'SELECT GMVTarget__c, TargetType__c,StartDate,EndDate,Id,EBH_RebateTierrebate__c, EBH_ContractExposure__c,CurrencyISOCODE,EBH_Site__c,EBH_IncrementalGMVonly__c, EBH_AverageTakeRate__c, '
        + 'EBH_StoreSubscription__c, EBH_ContractValue__c, RecordType.DeveloperName, EBH_OnBoardingFees__c, AM_Bolt_on__c, VolumeBasedDiscount__c, DiscountType__c, ManualContractExposure__c,'
        + '(SELECT Id,FVFBaseRate504__c,ExposureVIP__c, CurrencyISOCode,EBH_GMVTarget__c , EBH_ListingExposure__c,  EBH_ListingValue__c, EBH_ACPValue__c, EBH_ACPExposure__c,TargetType__c, '
        + ' EBH_RevenueExposure__c, EBH_RevenueValue__c, EBH_PriorYearGMV__c, '
        //+ ' Up_to_GMV_Tier_1__c, Between_GMV_Tier_1_and_2__c, Between_GMV_Tier_2_and_3__c, Between_GMV_Tier_3_and_4__c, Over_GMV_Tier_5__c, ' // SB 31.05.2024 US-0015367. // LA-03-07-2024-US-0015413
        + ' GMVThreshold0__c,GMVThreshold1__c,GMVThreshold2__c,GMVThreshold3__c,GMVThreshold4__c,GMVThreshold5__c, ' // LA-03-07-2024-US-0015413
        + ' Tier_0_bps_Discount__c, Tier_1_bps_Discount__c, Tier_2_bps_Discount__c, Tier_3_bps_Discount__c, Tier_4_bps_Discount__c, Tier_5_bps_Discount__c, ' // SB 31.05.2024 US-0015367
        + ' EBH_StoreSubscription__c, EBH_Site__c, RecordType.DeveloperName FROM EBH_Pricing__r'
        + ' ) '
        + 'FROM Contract WHERE Id IN: parentIds AND '
        + ' RecordTypeId IN (SELECT Id FROM RecordType WHERE DeveloperName=\''+CONTRACT_LISTINGRECORDTYPE+'\''
        + ' OR DeveloperName = \'' + CONTRACT_RSRECORDTYPE + '\''
        + ' OR DeveloperName = \'' + CONTRACT_ACPRECORDTYPE + '\''
        + ' OR DeveloperName = \'' + CONTRACT_VIPRECORDTYPE + '\'' // SB 31.05.2024 US-0015367
        + ' OR DeveloperName = \'' + CONTRACT_FVFDISCOUNTRECORDTYPE + '\''//TH 25.09.2025 US-0033097
        + ' ) ';  
    
    //To get the store subscription fees for each Site
   // static Map<String, EBH_SiteStoreSubscriptionFees__c> SubscriptionFees = new Map<String, EBH_SiteStoreSubscriptionFees__c>();
    static Map<String,EBH_ListingPricingExposure__c> exposureMap = new Map<String, EBH_ListingPricingExposure__c>();
    static EBH_CurrencyConverter  cConverter = new EBH_CurrencyConverter ();
    /*****************************************************************************************************************************
    @ Method:         updateCustomRollUp
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Updates custom roll ups on Contract (record type: Listing Agreement) from all child Pricings of record Type 
                      Listing Agreement
                       - Contract Listing Value - Value + Store Subscription Fees (if subscription type is Free)
                       - Contract Exposure Value - Exposure + Store Subscription Fees (if subscription type is Non Free) 
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.12.2017 / NEHA LUND / Created the  Method.
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2021 / Sophal Noch / Modified the  Method.
    *****************************************************************************************************************************/
    public static void updateCustomRollUp(List<EBH_Pricing__c> pricings, Map<Id, EBH_Pricing__c> pricingOldMap) {        
        
        Set<Id> parentIds = new Set<Id>();    //distinct parent ids of the Pricings in trigger scope
        List<Contract> parents;               //list of distinct parents from parentIds
        
        for(EBH_Pricing__c con : pricings) { 
            
            //get distinct parent ids from trigger scope Pricings and populate parentIds if any aggregate fields has changed
            if(hasRollupChanged(con, pricingOldMap)) {              
                
                Id pId = con.EBH_ContractId__c;
                
                if(!String.isBlank(pId)) {
                    parentIds.add(pId); 
                }
            }
            
            //if Contract is changed, then both old and new parents need to be updated
            if(hasParentChanged(con, pricingOldMap)){
                
                Id pId = pricingOldMap.get(con.id).EBH_ContractId__c;
                
                if(!String.isBlank(pId)) {
                    parentIds.add(pId); 
                }
            }
        }        
        
        
        //fetch the Contract & child Pricing records
        //parents = Database.query(CONTRACT_PARENTCHILDQUERY);
        parents = ApexSafe.query().secCheck(false).doQuery(CONTRACT_PARENTCHILDQUERY,new Map<String, Object> {'parentIds' => parentIds});
        
        if( !parents.isEmpty() ){
            try {
                updateContractValueExposure(parents, true);
            } catch (DmlException ex) {
                // Sophal / 02.09.2021 / US-0010295 show cleaner error message by getting error message from exception and add to each pricing record.
                //DmlException dmlEx = new DmlException(ex.getDmlMessage(0));
                Map<Id,String> mapContIdToError = new Map<Id,String>();
                for(Integer i = 0; i < ex.getNumDml(); i++) {
                    mapContIdToError.put(ex.getDmlId(i), ex.getDmlMessage(i));
                }
                String defaultErr = ex.getMessage();
                for(EBH_Pricing__c pricing : pricings){
                    String errToDisplay = mapContIdToError.get(pricing.EBH_ContractId__c);
                    errToDisplay = (errToDisplay != null && errToDisplay.contains(Label.ErrorInvalidSellerSignatoryContact)) ? errToDisplay : defaultErr;
                    pricing.addError(errToDisplay);
                }
            }
            

            
        }
        
     }
     
     /*****************************************************************************************************************************
    @ Method:         updatePricingCapDiscount
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        EPH-5008 : Reusable method for both Pricing & Contract two way synchronization
                      Updates custom roll ups on Contract (record type: Listing Agreement) from all child Pricings of record Type 
                      Listing Agreement
                       - Contract Listing Value - Value + Store Subscription Fees (if subscription type is Free)
                       - Contract Exposure Value - Exposure + Store Subscription Fees (if subscription type is Non Free) 
                       
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.11.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
   
    public static void updateFFExposure( List<EBH_Pricing__c> pricings, Map<ID, EBH_Pricing__c> pricingMap ){
        
        EBH_ListingPricingExposure__c exposure = new EBH_ListingPricingExposure__c();
        Decimal exposureValue = 0;
        for(EBH_ListingPricingExposure__c lp: [SELECT Name, Id, CurrencyISOCODE,EBH_GalleryPlus__c , EBH_Store__c,
                                                EBH_InsertionFees__c , EBH_InternationalSiteVisibility__c ,
                                                EBH_PicturePack__c , EBH_Subtitle__c from 
                                                EBH_ListingPricingExposure__c]){
            exposureMap.put(lp.Name, lp);
        }
        
        for(EBH_Pricing__c con : pricings) { 
            
            
            exposureValue = 0;
            if( exposureMap.containsKey(con.EBH_Site__c)){
                exposure = exposureMap.get(con.EBH_Site__c);
               
                if( con.EBH_InsertionFees__c != null && con.EBH_InsertionFees__c == EBH_constantsUtility.PRICING_FREESUBSCRIPTION){
                    exposureValue += cconverter.convert(exposure.EBH_InsertionFees__C, exposure.CurrencyISOCOde, con.CurrencyISOCode);
                }
                
                if( con.EBH_InternationalSiteVisibility__c != null && con.EBH_InternationalSiteVisibility__c == EBH_constantsUtility.PRICING_FREESUBSCRIPTION){
                    exposureValue += cconverter.convert(exposure.EBH_InternationalSiteVisibility__c,  exposure.CurrencyISOCOde, con.CurrencyISOCode);
                }
                if( con.EBH_subTitle__c != null && con.EBH_Subtitle__c == EBH_constantsUtility.PRICING_FREESUBSCRIPTION){
                    exposureValue += cconverter.convert(exposure.EBH_Subtitle__C, exposure.CurrencyISOCOde, con.CurrencyISOCode);
                }
                if( con.EBH_GalleryPlus__c != null && con.EBH_GalleryPlus__c == EBH_constantsUtility.PRICING_FREESUBSCRIPTION){
                    exposureValue += cconverter.convert(exposure.EBH_GalleryPlus__C,exposure.CurrencyISOCOde, con.CurrencyISOCode);
                }
               
               con.EBH_FFExposure__c = exposureValue;
                
            }
        }    
        
    }
    
     /*****************************************************************************************************************************
    @ Method:         updatePricingCapDiscount
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        EPH-4178: Reusable method for both Pricing & Contract two way synchronization
                      Updates custom roll ups on Contract (record type: Listing Agreement) from all child Pricings of record Type 
                      Listing Agreement
                       - Contract Listing Value - Value + Store Subscription Fees (if subscription type is Free)
                       - Contract Exposure Value - Exposure + Store Subscription Fees (if subscription type is Non Free) 
                       
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.11.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
   
    public static void updatePricingCapDiscount( List<EBH_Pricing__c> pricings, Map<ID, EBH_Pricing__c> pricingMap ){
        
            
            Set<ID> pricingIds = new Set<ID> ();
            
            for(EBH_Pricing__c con : Pricings) { 
            
                //get distinct parent ids from trigger scope Pricings and populate parentIds if any aggregate fields has changed
                if(hasPricingMatrixChanged(con, pricingMap)) {              
                     
                        pricingIds.add(con.EBH_ContractPricingMatrix__c);
                }
            }
            
            Map<ID, EBH_ContractPricingMatrix__c> pMatrixMap = new Map<ID, EBH_ContractPricingMatrix__c>
                    ([SELECT EBH_BusinessVerticalName__c, EBH_CAP__c,
                    EBH_Currency__c,currencyISOCode, EBH_FVF__c, EBH_ListingFormat__c, EBH_MetaCategoryL2__c, EBH_SiteCountry__c,
                    EBH_SiteID__c from EBH_ContractPricingMatrix__c where ID IN :pricingIds]);
                    
            
            EBH_ContractPricingMatrix__c pm = new EBH_ContractPricingMatrix__c();
            
            for(EBH_Pricing__c con : Pricings) { 
               
                //get distinct parent ids from trigger scope Pricings and populate parentIds if any aggregate fields has changed
                if(hasPricingMatrixChanged(con, pricingMap)) {              
                
                        //EPH-5858 : to default FVF cap to blank when related product category doesn't have any FVF cap
                        con.EBH_DefaultFVFCap__c = null;
                        
                        if(pMatrixMap.containsKey(con.EBH_ContractPricingMatrix__c)){
                            pm = pMatrixMap.get(con.EBH_ContractPricingMatrix__c);
                            if(pm.EBH_Cap__c != null)
                            con.EBH_DefaultFVFCap__c = cconverter.convert(pm.EBH_Cap__c,pMatrixMap.get(con.EBH_ContractPricingMatrix__c).CurrencyISOCode,con.CurrencyISOCode  );
                           
                            con.EBH_DefaultFVFDiscount__c = pm.EBH_FVF__c;
                        }
                }
            }
                    
        
    }
    
    /*****************************************************************************************************************************
    @ Method:         updateContractValueExposure
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        US-0017: Reusable method for both Pricing & Contract two way synchronization
                      Updates custom roll ups on Contract (record type: Listing Agreement) from all child Pricings of record Type 
                      Listing Agreement
                       - Contract Listing Value - Value + Store Subscription Fees (if subscription type is Free)
                       - Contract Exposure Value - Exposure + Store Subscription Fees (if subscription type is Non Free) 
                       
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2017 / NEHA LUND / Created the  Method.
    @               : 26/04/2018/ Vadhanak Voun/ EPH-5479 Additional bolt-ons for Listing and ACP
    @                updated acp and listing to get new calculation
    @               : 28.07.2020/ Vadhanak Voun / US-0007883 - Contract P2.0 Value and Contract Exposure calculation for Listing Agreement contracts
    @               :10.11.2020/ Vadhanak Voun /US-0007957 - ST-002994 - Contract 2460: Exposure (Store Subscription and AM Bolt-ons) needs to be adjusted to 3 months period
    @               : 31.05.2024 / Sambath Seng / US-0015367 - Auto calculate VIP Contract value and Exposure
    @               : 13.08.2024 / LoumAng SENG / US-0015451 - VIP Types - Flat rate and P&A
    @               : 11.03.2025 / Sambath Seng / US-0016887 - Manual Contract Exposure Field for Flat Rate Contracts
    @               : 25.09.2025 / Sovantheany Dim / US-0033097 - eBay Live: Feedback Enhancements 
    *****************************************************************************************************************************/   
    public static List<Contract> updateContractValueExposure( List<Contract> parents, boolean updateContracts ){
       
        List<EBH_Pricing__c> pricingList = new List<EBH_Pricing__c>();
        String listingExposureSQOL = 'SELECT Name, CurrencyISOCode, Id,EBH_GalleryPlus__c  ,EBH_Store__c,EBH_InsertionFees__c,EBH_InternationalSiteVisibility__c,EBH_PicturePack__c ,EBH_Subtitle__c from EBH_ListingPricingExposure__c';
        List<EBH_ListingPricingExposure__c> lstExposures = ApexSafe.query().secCheck(false).doQuery(listingExposureSQOL);
        for(EBH_ListingPricingExposure__c lp: lstExposures){                                     
            exposureMap.put(lp.Name, lp);
        } 
        //query Contract to get child Pricing records
        Map<ID, Contract> contractMap = new Map<ID, Contract>((List<Contract>)Database.query(CONTRACT_PRICINGCONTRACTQUERY));
        //EPH-4145
        Decimal boardingFees = 0;
        Decimal conversionRate = 1;
        
        //NK:26/04/2018
        Map<String,Contract_Fee__c> mapAllFee =  getMapContractFee();
        //parse through Parents        
        for(Contract contractRecord : parents) {
            Decimal valPeriod = calDatePeriod(contractRecord.StartDate,contractRecord.EndDate);
            //NK:26/04/2018 custom setting record exist and price <> null -> convert currency
            //EPH-5479 Additional bolt-ons for Listing and ACP
            Decimal ampBoltOnFee = (mapAllFee.get('AM_Bolt_on__c'+contractRecord.EBH_Site__c) <> null && mapAllFee.get('AM_Bolt_on__c'+contractRecord.EBH_Site__c).Price__c <> null)
            ? cconverter.convert( mapAllFee.get('AM_Bolt_on__c'+contractRecord.EBH_Site__c).Price__c ,mapAllFee.get('AM_Bolt_on__c'+contractRecord.EBH_Site__c).CurrencyCode__c,  contractRecord.CurrencyISOCode):0;
            ampBoltOnFee    = ampBoltOnFee * valPeriod; //NK:10/11/2020:US-0007957

            Decimal subcriptionFeeNew = (mapAllFee.get('EBH_StoreSubscription__c'+contractRecord.EBH_Site__c+contractRecord.EBH_StoreSubscription__c) <> null && mapAllFee.get('EBH_StoreSubscription__c'+contractRecord.EBH_Site__c+contractRecord.EBH_StoreSubscription__c).Price__c <> null)
                                        ? cconverter.convert( mapAllFee.get('EBH_StoreSubscription__c'+contractRecord.EBH_Site__c+contractRecord.EBH_StoreSubscription__c).Price__c ,mapAllFee.get('EBH_StoreSubscription__c'+contractRecord.EBH_Site__c+contractRecord.EBH_StoreSubscription__c).CurrencyCode__c,  contractRecord.CurrencyISOCode):0;
                                        subcriptionFeeNew   = subcriptionFeeNew * valPeriod; //NK:10/11/2020:US-0007957
            boardingFees = 0;
            if( contractRecord.EBH_OnBoardingFees__c != null ){
                boardingFees = contractRecord.EBH_OnBoardingFees__c;
            }
            
            Decimal storeFreeFees    
            = contractRecord.EBH_StoreSubscription__c != null && contractRecord.EBH_StoreSubscription__c.equalsIgnoreCase(EBH_ConstantsUtility.PRICING_FREESUBSCRIPTION) && 
                      exposureMap.containsKey(contractRecord.EBH_Site__c) ? 
                      cconverter.convert(exposureMap.get(contractRecord.EBH_Site__c).EBH_Store__c, exposureMap.get(contractRecord.EBH_Site__c).CurrencyISOCode, contractRecord.CurrencyISOCode ): EBH_ConstantsUtility.STORE_FEES;
                      
                      Decimal storeNonFreeFees 
                      = contractRecord.EBH_StoreSubscription__c!= null && contractRecord.EBH_StoreSubscription__c.equalsIgnoreCase(EBH_ConstantsUtility.PRICING_NONFREESUBSCRIPTION) && 
                      exposureMap.containsKey(contractRecord.EBH_Site__c)? 
                      cconverter.convert(exposureMap.get(contractRecord.EBH_Site__c).EBH_Store__c,exposureMap.get(contractRecord.EBH_Site__c).CurrencyISOCode,  contractRecord.CurrencyISOCode): EBH_ConstantsUtility.STORE_FEES;
            
            contractRecord.EBH_ContractValue__c = contractRecord.EBH_ContractExposure__c = EBH_ConstantsUtility.STORE_FEES;

            //11.03.2025 Sambath Seng US-0016887
            Boolean isManualContractExposure = contractRecord.DiscountType__c == CONTRACT_DICSOUNTTYPE_FLATRATE && contractRecord.ManualContractExposure__c != null;

            //NK:26/04/2018: acp and listing
            if( contractMap.get(contractRecord.id).RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_LISTINGRECORDTYPE)
            || contractMap.get(contractRecord.id).RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_ACPRECORDTYPE) 
            ){        
                //reset the roll ups
                contractRecord.EBH_ContractValue__c    = (contractRecord.AM_Bolt_on__c == EBH_ConstantsUtility.CONTRACT_AMBOLT_STANDARD ? ampBoltOnFee : 0);
                contractRecord.EBH_ContractExposure__c = (contractRecord.EBH_StoreSubscription__c <>EBH_ConstantsUtility.CONTRACT_AMBOLT_STANDARD? 
                                                        subcriptionFeeNew:0) + (contractRecord.AM_Bolt_on__c==EBH_ConstantsUtility.CONTRACT_AMBOLT_FREE? ampBoltOnFee:0);
            }
            else if(contractMap.get(contractRecord.id).RecordType.DeveloperName.equalsIgnoreCase(EBH_ConstantsUtility.CONTRACT_RSRECORDTYPE) ){
                contractRecord.EBH_ContractValue__c = contractRecord.EBH_ContractExposure__c = boardingFees;
             
            }
            // Start - 11.03.2025 Sambath Seng US-0016887
            else if(contractMap.get(contractRecord.id).RecordType.DeveloperName.equalsIgnoreCase(CONTRACT_RECORDTYPE_VIP) && isManualContractExposure){
                contractRecord.EBH_ContractExposure__c = contractRecord.ManualContractExposure__c;
            }// End - 11.03.2025 Sambath Seng US-0016887 
            //TH 25.07.2025 : US-0033097: FVF_Discount_Contract Calculate exposure using Formula: (13% - Pricing.FVFBaseRate504__c) × Contract.GMV Target × 1.1
            else if (contractMap.get(contractRecord.id).RecordType.DeveloperName.equalsIgnoreCase(CONTRACT_FVFDISCOUNTRECORDTYPE)) {
                Decimal baseExposure = 0;
                // Get pricing records for this contract to calculate exposure
                List<EBH_Pricing__c> fvfPricingList = updateContracts ? contractRecord.EBH_Pricing__r : contractMap.get(contractRecord.id).EBH_Pricing__r;
                // Use only the first pricing record where FVFBaseRate504__c is not null
                EBH_Pricing__c validPricing = null;
                for(EBH_Pricing__c pricing : fvfPricingList) {
                    if(pricing.FVFBaseRate504__c != null) {
                        validPricing = pricing;
                        break;
                    }
                }
                if(validPricing != null && contractRecord.GMVTarget__c != null) {
                    baseExposure = ((13 - validPricing.FVFBaseRate504__c) * contractRecord.GMVTarget__c) * 1.1/100;  
                }
                contractRecord.EBH_ContractExposure__c = baseExposure;
                contractRecord.EBH_ContractValue__c = contractRecord.GMVTarget__c;
            }
            else{
                contractRecord.EBH_ContractExposure__c = storeFreeFees;
            }
            
            //aggregate from child Pricings, if context is Contract Trigger then use the Contract Map
            //if Context of execution is Pricing Trigger then use the contractRecord
            pricingList = updateContracts ? contractRecord.EBH_Pricing__r: contractMap.get(contractRecord.id).EBH_Pricing__r;
             
            //parse through Pricing Records
            for(EBH_Pricing__c pricing : pricingList) {
                
                //Pricing RecordType Listing
                if(pricing.RecordType.DeveloperName == EBH_ConstantsUtility.PRICING_LISTINGRECORDTYPE || pricing.RecordType.DeveloperName == PRICING_REC_P2) { //NK:28/07/2020: US-0007883
                    
                  
                    //aggregate and populate roll ups at parent
                    contractRecord.EBH_ContractValue__c    
                        += pricing.EBH_ListingValue__c != Null ?
                           cconverter.convert(pricing.EBH_ListingValue__c, pricing.currencyISOCode,contractRecord.currencyISOCode )
                           : EBH_ConstantsUtility.STORE_FEES;
                   
                    contractRecord.EBH_ContractExposure__c 
                        += pricing.EBH_ListingExposure__c != Null ? 
                           cconverter.convert(pricing.EBH_ListingExposure__c , pricing.currencyISOCode,contractRecord.currencyISOCode): EBH_ConstantsUtility.STORE_FEES;
                }
                //Pricing RecordType ACP Target
                else
                if(pricing.RecordType.DeveloperName == EBH_ConstantsUtility.PRICING_ACPTARGETRECORDTYPE ){
                    //aggregate and populate roll ups at parent
                    contractRecord.EBH_ContractValue__c    
                        += pricing.EBH_GMVTarget__c != null && contractRecord.EBH_AverageTakeRate__c != Null ?
                          cconverter.convert( (pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c)/100 , pricing.currencyISOCode,contractRecord.currencyISOCode) 
                          : 0;
                    
                    
                   /*contractRecord.EBH_ContractExposure__c 
                        += pricing.EBH_GMVTarget__c!= null && contractRecord.EBH_AverageTakeRate__c!= null && contractRecord.EBH_RebateTierrebate__c != null? 
                       cconverter.convert(  (pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c * contractRecord.EBH_RebateTierrebate__c)/10000, pricing.currencyISOCode,contractRecord.currencyISOCode) : 0;
                    */
                    
                    //Updated: LA/07-04-2021/US-0009303
                    
                    Decimal contractExposure = 0;

                    if(pricing.EBH_GMVTarget__c!= null && contractRecord.EBH_AverageTakeRate__c!= null && contractRecord.EBH_RebateTierrebate__c != null){

                        Decimal contrPrice;
                        if(contractRecord.VolumeBasedDiscount__c){
                            contrPrice = ( pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c * contractRecord.EBH_RebateTierrebate__c * (1-(contractRecord.VolumeDiscounts__c==null?0:contractRecord.VolumeDiscounts__c/100)));
                        }else{
                            contrPrice = pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c * contractRecord.EBH_RebateTierrebate__c;
                        }
                        contractExposure = cconverter.convert( contrPrice/10000, pricing.currencyISOCode, contractRecord.currencyISOCode);

                    }
                    contractRecord.EBH_ContractExposure__c += contractExposure;
                 }
                //Pricing RecordType Revenue Share Target
                else
                if(pricing.RecordType.DeveloperName == EBH_ConstantsUtility.PRICING_REVENUESHARETARGETRECORDTYPE) {
                    decimal gmv = pricing.EBH_GMVTarget__c;
                    //EPH-5058 
                    if( contractRecord.EBH_IncrementalGMVonly__c && pricing.EBH_PriorYearGMV__c != null){
                        gmv = gmv*0.15;
                           
                   }
                    //aggregate and populate roll ups at parent
                    contractRecord.EBH_ContractValue__c    
                        +=  (pricing.EBH_GMVTarget__c != null &&  contractRecord.EBH_AverageTakeRate__c != null && 
                           contractRecord.EBH_RebateTierrebate__c != null ?
                         cconverter.convert(  (pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c * 
                           contractRecord.EBH_RebateTierrebate__c)/10000, 
                            pricing.currencyISOCode,contractRecord.currencyISOCode)
                           : 0);
                  
                   
                   
                    contractRecord.EBH_ContractExposure__c 
                        += (pricing.EBH_GMVTarget__c != null &&  contractRecord.EBH_AverageTakeRate__c != null && 
                           contractRecord.EBH_RebateTierrebate__c != null ? 
                        cconverter.convert(   (gmv * contractRecord.EBH_AverageTakeRate__c * 
                           contractRecord.EBH_RebateTierrebate__c)/10000,pricing.currencyISOCode,contractRecord.currencyISOCode) : 0);
                }
                // Start SB 31.05.2024 US-0015367
                // 11.03.2025 Sambath Seng US-0016887 add condition isManualContractExposure
                else if(pricing.RecordType.DeveloperName == PRICING_VIPRECORDTYPE && !isManualContractExposure) {
                    contractRecord.EBH_ContractValue__c += pricing.EBH_GMVTarget__c != null && contractRecord.EBH_AverageTakeRate__c != Null ?
                        cconverter.convert((pricing.EBH_GMVTarget__c * contractRecord.EBH_AverageTakeRate__c)/100, pricing.currencyISOCode, contractRecord.currencyISOCode) : 0;

                    Decimal gmvTarget = pricing.EBH_GMVTarget__c;
                    //START LA-03-07-2024-US-0015413: Replace fields from gmvThreshold0 to tier0bps
                    Decimal gmvThreshold0 = pricing.GMVThreshold0__c;
                    Decimal gmvThreshold1 = pricing.GMVThreshold1__c;
                    Decimal gmvThreshold2 = pricing.GMVThreshold2__c;
                    Decimal gmvThreshold3 = pricing.GMVThreshold3__c;
                    Decimal gmvThreshold4 = pricing.GMVThreshold4__c;
                    Decimal gmvThreshold5 = pricing.GMVThreshold5__c;
                    Decimal tier0bps = pricing.Tier_0_bps_Discount__c;
                    //END LA-03-07-2024-US-0015413
                    Decimal tier1bps = pricing.Tier_1_bps_Discount__c;
                    Decimal tier2bps = pricing.Tier_2_bps_Discount__c;
                    Decimal tier3bps = pricing.Tier_3_bps_Discount__c;
                    Decimal tier4bps = pricing.Tier_4_bps_Discount__c;
                    Decimal tier5bps = pricing.Tier_5_bps_Discount__c;
                    Decimal result = 0;
                    Decimal exposureVIP = 0;

                    if (gmvThreshold0 <= gmvTarget && gmvThreshold0 != null && tier0bps != null) { //LA-03-07-2024-US-0015413: add condition gmvThreshold0
                        result += gmvThreshold1 != null ? (Math.min(gmvThreshold1, gmvTarget) - gmvThreshold0) * (tier0bps/10000) : (gmvTarget - gmvThreshold0) * (tier0bps/10000);//LA-08-07-2024-US-0015413: Check gmvThreshold1
                    }

                    if (gmvThreshold1 <= gmvTarget && gmvThreshold1 != null && tier1bps != null) {
                        result += gmvThreshold2 != null ? (Math.min(gmvThreshold2, gmvTarget) - gmvThreshold1) * (tier1bps/10000) : (gmvTarget - gmvThreshold1) * (tier1bps/10000);//LA-08-07-2024-US-0015413: Check gmvThreshold2
                    }

                    if (gmvThreshold2 <= gmvTarget && gmvThreshold2 != null && tier2bps != null) {
                        result += gmvThreshold3 != null ? (Math.min(gmvThreshold3, gmvTarget) - gmvThreshold2) * (tier2bps/10000) : (gmvTarget - gmvThreshold2) * (tier2bps/10000);//LA-08-07-2024-US-0015413: Check gmvThreshold3
                    }

                    if (gmvThreshold3 <= gmvTarget && gmvThreshold3 != null && tier3bps != null) {
                        result += gmvThreshold4 != null ? (Math.min(gmvThreshold4, gmvTarget) - gmvThreshold3) * (tier3bps/10000) : (gmvTarget - gmvThreshold3) * (tier3bps/10000);//LA-08-07-2024-US-0015413: Check gmvThreshold4
                    }

                    if (gmvThreshold4 <= gmvTarget && gmvThreshold4 != null && tier4bps != null) {
                        result += gmvThreshold5 != null? (Math.min(gmvThreshold5, gmvTarget) - gmvThreshold4) * (tier4bps/10000) : (gmvTarget - gmvThreshold4) * (tier4bps/10000);//LA-08-07-2024-US-0015413: Check gmvThreshold5
                    }

                    if (gmvThreshold5 <= gmvTarget && gmvThreshold5 != null && tier5bps != null) {
                        result += (gmvTarget - gmvThreshold5) * (tier5bps/10000);
                    }

                    exposureVIP = cconverter.convert(result, pricing.currencyISOCode, contractRecord.currencyISOCode);

                    //==START== LA-13.08.2024-US-0015451
                    if(pricing.TargetType__c == QUARTERLY_TARGETTYPE){//LA-13-08-2024-US-0015451:(AC4)
                        contractRecord.EBH_ContractExposure__c += (exposureVIP * 4);
                    } else {
                        contractRecord.EBH_ContractExposure__c += exposureVIP;
                    }
                    //==END== LA-13.08.2024-US-0015451

                    
                }
                // End SB 31.05.2024 US-0015367
            }
            
        }
        
        //if context of execution is Pricing trigger, then we should have an explicit update of Contracts
        if( updateContracts ){
           
           List<Database.saveResult> sr = new List<Database.SaveResult>();

          // try {
                sr= Database.update(parents);
                
          /*  }catch(DMLException ex) {
                EBH_ApexLogger.logError(new List<Exception> { ex }, EBH_ConstantsUtility.PRICE_CLASSHANDLER, 
                                        EBH_ConstantsUtility.PRICE_CLASSMETHOD);
                                 
            }*/
        }
     
     //return contracts modified in this method, so that they get updated in Contract trigger context
     return parents;

    }
    /*****************************************************************************************************************************
    @ Method:         calDatePeriod
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:       US-0007957 - ST-002994 - Contract 2460: Exposure (Store Subscription and AM Bolt-ons) needs to be adjusted to 3 months period                    
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      startDate,Enddate
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 10.11.2020/ Vadhanak Voun /US-0007957 - ST-002994 - Contract 2460: Exposure (Store Subscription and AM Bolt-ons) needs to be adjusted to 3 months period
    @               : Days360(Contract.Contract Start Date, Contract.Contract End Date)/360*
    *****************************************************************************************************************************/   
    private static Decimal calDatePeriod(Date dStart,Date dEnd)
    {
        return Decimal.valueOf(dStart.daysBetween(dEnd))/Decimal.valueOf(360);
    }

    /*****************************************************************************************************************************
    @ Method:         hasRollupChanged
    @ Version:        1.0
    @ Author:         NEHA LUND 
    @ Purpose:        Check and returns true if any of the following fields has changed in Pricing passed in param:
                       - Listing Value
                       - Listing Exposure 
                       - Store Subscription
                       - Contract
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      con:           Pricing to check field(s) change for
                      PricingOldMap: Pricing old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2017 / NEHA LUND / Created the  Method.
    @               : 03.06.2024 / Sambath Seng / US-0015367 - Auto calculate VIP Contract value and Exposure
    @               : 25.09.2025 / Sovantheany Dim / US-0033097 - eBay Live: Feedback Enhancements 
    *****************************************************************************************************************************/
    public static Boolean hasRollupChanged(EBH_Pricing__c pr, Map<Id, EBH_Pricing__c> pricingOldMap) {
        
        EBH_Pricing__c oldPr = pricingOldMap != Null ? pricingOldMap.get(pr.Id) : pr;
        
        return pr.EBH_ListingValue__c != oldPr.EBH_ListingValue__c ||
               pr.EBH_ListingExposure__c != oldPr.EBH_ListingExposure__c ||
               pr.EBH_ACPValue__c != oldPr.EBH_ACPValue__c ||
               pr.EBH_ACPExposure__c != oldPr.EBH_ACPExposure__c ||
               pr.EBH_RevenueValue__c != oldPr.EBH_RevenueValue__c ||
               pr.EBH_RevenueExposure__c != oldPr.EBH_RevenueExposure__c ||
               pr.EBH_ContractId__c != oldPr.EBH_ContractId__c || pricingOldMap == null ||
               //pr.Exposure_VIP__c != oldPr.Exposure_VIP__c; // SB 03.06.2024 US-0015367
               (pr.ExposureVIP__c != oldPr.ExposureVIP__c) || // LA-19-08-2024-US-0015451
               (pr.FVFBaseRate504__c != oldPr.FVFBaseRate504__c); // TH-25-09-2025-US-0033097
               
    } 
     /*****************************************************************************************************************************
    @ Method:         hasPricingMatrixChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        EPH-4178: Check and returns true if Pricing Matrix has changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      con:           Pricing to check field(s) change for
                      PricingOldMap: Pricing old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 09.11.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasPricingMatrixChanged(EBH_Pricing__c con, Map<Id, EBH_Pricing__c> PricingOldMap) {
        
        EBH_Pricing__c oldCon = PricingOldMap != Null ? PricingOldMap.get(con.Id) : con;
        
        return (con.EBH_ContractPricingMatrix__c  != oldCon.EBH_ContractPricingMatrix__c  ||  
                con.CurrencyISOCODe != oldCon.CurrencyISOCode ||  
                con.EBH_Category__c!=oldCon.EBH_Category__c || // Added by DHE 2018/05/24 EPH-5858
                pricingOldMap == null ) &&
                con.EBH_ContractPricingMatrix__c != null;
    }    
    /*****************************************************************************************************************************
    @ Method:         hasParentChanged
    @ Version:        1.0
    @ Author:         Neha Lund
    @ Purpose:        Check and returns true if parent has changed in old Pricing passed in param
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      con:           Pricing to check field(s) change for
                      PricingOldMap: Pricing old map from trigger scope to compare
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: True if any of the field changed
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 18.05.2017 / NEHA LUND / Created the  Method.
    *****************************************************************************************************************************/
    public static Boolean hasParentChanged(EBH_Pricing__c con, Map<Id, EBH_Pricing__c> PricingOldMap) {
        
        EBH_Pricing__c oldCon = PricingOldMap != Null ? PricingOldMap.get(con.Id) : con;
        
        return con.EBH_ContractId__c != oldCon.EBH_ContractId__c;
    }    
    
    /*****************************************************************************************************************************
    @ Method:         getMapContractFee
    @ Version:        1.0
    @ Author:         Vadhanak Voun
    @ Purpose:        poppulate custom setting (Contract_Fee__c) records into map for easy usage
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      
    ------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        Boolean: map of custom setting: Contract_Fee__c
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 26.04.2018 / Vadhanak Voun / Created the  Method.
    *****************************************************************************************************************************/
    private static Map<String,Contract_Fee__c> getMapContractFee()
    {
        Map<String,Contract_Fee__c> mapAllFee = new Map<String,Contract_Fee__c>();
        Map<String,Contract_Fee__c> custFee = Contract_Fee__c.getAll();
        for(Contract_Fee__c c: custFee.values())
        {
            mapAllFee.put(c.Field__c+c.Site__c+(String.isBlank(c.Type__c)?'':c.Type__c),c);
        }
        return mapAllFee;
    }
    
    /*****************************************************************************************************************************
    @ Method:         updateCustomVIPflag
    @ Version:        1.0
    @ Author:         Veenus Gollapalli
    @ Purpose:        Updates customVIP flag on Contract (record type: VIP Contract) based on custom child Pricings of record Type 
					  VIP Template
                       - customVIP checkbox - true if any of the child Pricings of record Type VIP Template are custom type 
						otherwise false
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:      Pricings:      Pricings from the trigger scope
                      PricingOldMap: Pricings old map from the trigger scope
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.29.2024 / Veenus Gollapalli / Created the  Method.
    *****************************************************************************************************************************/
    public static void updateCustomVIPflag(List<EBH_Pricing__c> Pricings, Map<Id, EBH_Pricing__c> PricingOldMap) {   
        Set<Id> parentIdsneedflagging = new Set<Id>();
        Set<Id> parentIdsneedcheckflag = new Set<Id>();
        List<Contract> parentsneedtrueflag = new List<Contract>();               
        List<Contract> parentsneedfalseflag = new List<Contract>();
        Id PRICING_VIPRECORDTYPEId = ApexUtil.getRecordTypeByName('EBH_Pricing__c',PRICING_VIPRECORDTYPE).Id;
        Id CONTRACT_VIPRECORDTYPEId = ApexUtil.getRecordTypeByName('Contract',CONTRACT_VIPRECORDTYPE).Id;
        
        
        //get distinct parent ids from trigger scope Pricings and populate parentIds if any aggregate fields has changed
        if(PricingOldMap==null) {
            for(EBH_Pricing__c con : Pricings) {
                if(con.EBH_ContractPricingMatrix__c == null && con.RecordTypeId == PRICING_VIPRECORDTYPEId){
                    parentIdsneedflagging.add(con.EBH_ContractId__c);
                }
                
            }
        }else if(PricingOldMap!=null && (Pricings !=null)){
            for(EBH_Pricing__c con : Pricings) {
                if(con.RecordTypeId == PRICING_VIPRECORDTYPEId){
                    EBH_Pricing__c oldCon = PricingOldMap.get(con.id);
                    if((con.EBH_ContractPricingMatrix__c == null && oldCon.EBH_ContractPricingMatrix__c !=null)||(con.EBH_ContractPricingMatrix__c != null && oldCon.EBH_ContractPricingMatrix__c ==null)){
                    	parentIdsneedcheckflag.add(con.EBH_ContractId__c);
                         
                    }
  
                } 
            }
        }else{
            for(EBH_Pricing__c oldcon : PricingOldMap.values()) {
                if(oldcon.EBH_ContractPricingMatrix__c == null && oldcon.RecordTypeId == PRICING_VIPRECORDTYPEId){
                    parentIdsneedcheckflag.add(oldcon.EBH_ContractId__c);
                }
                
            }
        }
        
        if(!parentIdsneedflagging.isEmpty()){
            List<Contract> contractrecord = [Select Id,Custom_VIP__c from Contract Where Id IN: parentIdsneedflagging and Custom_VIP__c = false and RecordTypeId =: CONTRACT_VIPRECORDTYPEId];
            if(!contractrecord.isEmpty()){
                for(Contract contract: contractrecord){
                    contract.Custom_VIP__c = true;
                    parentsneedtrueflag.add(contract);
                }                
            }
        }
        if(!parentIdsneedcheckflag.isEmpty()){
            List<Contract> contractpricingrecord = [Select Id,Custom_VIP__c,(Select Id,EBH_ContractPricingMatrix__c FROM EBH_Pricing__r where EBH_ContractPricingMatrix__c=null) from Contract Where Id IN: parentIdsneedcheckflag and RecordTypeId =: CONTRACT_VIPRECORDTYPEId];
            if(!contractpricingrecord.isEmpty()){
                for(Contract contract : contractpricingrecord){
                    if(contract.Custom_VIP__c == false && (!contract.EBH_Pricing__r.isEmpty()) ){
                        contract.Custom_VIP__c = true;
                        parentsneedtrueflag.add(contract);
                    }
                    if(contract.Custom_VIP__c == true && (contract.EBH_Pricing__r.isEmpty()) ){
                        contract.Custom_VIP__c = false;
                        parentsneedfalseflag.add(contract);
                    }
                }
            }
        }
        if(!parentsneedtrueflag.isEmpty()){
            Database.update(parentsneedtrueflag,false);
        }
        if(!parentsneedfalseflag.isEmpty()){
            Database.update(parentsneedfalseflag,false);
        }
     
    }

    /*****************************************************************************************************************************
    @ Method:   validateLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
	@ Event:	before update
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 09.01.2025 / Sambath Seng / Method Creation
	*****************************************************************************************************************************/
    public static void validateLockedFields(Map<Id, EBH_Pricing__c> oldMap, Map<Id, EBH_Pricing__c> newMap) {

        // Check if user has custom permission to bypass locked fields
        Boolean isPricingManager = FeatureManagement.checkPermission('Pricing_Manager');
        Boolean hasBypassPermission = FeatureManagement.checkPermission('BypassLockedPricingConfiguration');

        If(hasBypassPermission) return;
        
        List<Schema.FieldSetMember> lockedFieldSet = SObjectType.EBH_Pricing__c.FieldSets.PricingConfigurationFieldsLocked.getFields();
        Set<String> lockedFieldNames = new Set<String>();
        for (Schema.FieldSetMember field : lockedFieldSet) {
            lockedFieldNames.add(field.getFieldPath());
        }

        // Collect contract IDs
        Set<Id> contractIds = new Set<Id>();
        for (EBH_Pricing__c newPricing : newMap.values()) {
            contractIds.add(newPricing.EBH_ContractId__c);
        }

        // Query contracts
        List<Contract> contractsList = ApexSafe.query().doQuery(CONTRACT_SOQL + ' WHERE Id IN :contractIds AND RecordType.DeveloperName IN :recordtypeSet', new Map<String, Object> {'contractIds' => contractIds, 'recordtypeSet' => CONTRACT_RECORDTYPE_FOR_PRICING_CONFIGURATION});
        Map<Id, Contract> contractMap = new Map<Id, Contract>(contractsList);

        // Check for locked fields
        Set<Id> pricingIdsToError = checkForPricingLockedFields(oldMap, newMap, contractMap, lockedFieldNames, isPricingManager);

        // Add errors to the records
        for (Id pricingId : pricingIdsToError) {
            EBH_Pricing__c newPricing = newMap.get(pricingId);
            newPricing.addError(System.Label.PricingConfigurationLockedFieldsMessage);
        }
    }

    /*****************************************************************************************************************************
    @ Method:   checkForPricingLockedFields
    @ Author: 	Sambath Seng
    @ Purpose:	US-0016114 - Pricing Configuration Record Lock - CPM, Contract other
    ------------------------------------------------------------------------------------------------------------------------------
   	@ Change history: 21.01.2025 / Sambath Seng / Method Creation
	*****************************************************************************************************************************/
    private static Set<Id> checkForPricingLockedFields(Map<Id, EBH_Pricing__c> oldMap, Map<Id, EBH_Pricing__c> newMap, Map<Id, Contract> contractMap, Set<String> lockedFieldNames, Boolean isPricingManager) {
        Set<Id> pricingIdsToError = new Set<Id>();
        Set<String> pricingBypassFields = new Set<String>{'Status__c', 'ListingItemFormat__c'};
        for (Id pricingId : newMap.keySet()) {
            EBH_Pricing__c oldPricing = oldMap.get(pricingId);
            EBH_Pricing__c newPricing = newMap.get(pricingId);

            if (oldPricing != null && newPricing != null) {
                Contract parentContract = contractMap.get(newPricing.EBH_ContractId__c);
                if (parentContract != null && parentContract.Status == CONTRACT_STATUS_PRICING_CONFIGURATION) {
                    for (String fieldName : lockedFieldNames) {

                        if(pricingBypassFields.contains(fieldName) && isPricingManager) continue;

                        Object oldValue = oldPricing.get(fieldName);
                        Object newValue = newPricing.get(fieldName);

                        if (oldValue != newValue) {
                            pricingIdsToError.add(pricingId);
                            break; // Exit the loop as soon as a locked field is detected
                        }
                    }
                }
            }
        }
        return pricingIdsToError;
    }

    /*****************************************************************************************************************************
    @ Method:         populateTimezoneOffsets
    @ Version:        1.0
    @ Author:         GitHub Copilot
    @ Purpose:        US-0033985: Populate Start Date Offset and End Date Offset fields based on EBH_Site__c using timezone names to handle DST
                      Uses Contract StartDate and EndDate through EBH_ContractId__r relationship, only triggers on site changes
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 02.12.2025 / GitHub Copilot / Method Creation - Updated to use timezone names and handle DST
    @ Change history: 02.12.2025 / GitHub Copilot / Updated to use Contract dates and only trigger on site changes
    *****************************************************************************************************************************/
    public static void populateTimezoneOffsets(List<EBH_Pricing__c> newPricings, Map<Id, EBH_Pricing__c> oldMap) {
        // Collect Contract IDs for records that need timezone offset updates
        Set<Id> contractIdsToQuery = new Set<Id>();
        Map<Id, EBH_Pricing__c> pricingsToUpdate = new Map<Id, EBH_Pricing__c>();
        
        for (EBH_Pricing__c pricing : newPricings) {
            EBH_Pricing__c oldPricing = oldMap?.get(pricing.Id);
            
            // Only trigger on site changes (insert or site field change) or when offset fields are null
            if (pricing.EBH_Site__c != null && 
                (oldPricing == null || 
                 pricing.EBH_Site__c != oldPricing.EBH_Site__c ||
                 pricing.StartDateOffset__c == null ||
                 pricing.EndDateOffset__c == null)) {
                
                if (pricing.EBH_ContractId__c != null) {
                    contractIdsToQuery.add(pricing.EBH_ContractId__c);
                    pricingsToUpdate.put(pricing.Id, pricing);
                }
            }
        }
        
        // Query Contract records to get StartDate and EndDate
        if (!contractIdsToQuery.isEmpty()) {
            String contractQuery = 'SELECT Id, StartDate, EndDate FROM Contract WHERE Id IN :contractIdsToQuery';
            List<Contract> contractList = ApexSafe.query().secCheck(false).doQuery(contractQuery, new Map<String, Object> {'contractIdsToQuery' => contractIdsToQuery});
            Map<Id, Contract> contractMap = new Map<Id, Contract>(contractList);
            
            // Update offset fields using Contract dates
            for (EBH_Pricing__c pricing : pricingsToUpdate.values()) {
                Contract relatedContract = contractMap.get(pricing.EBH_ContractId__c);
                
                if (relatedContract != null) {
                    // Check and populate Start Date Offset using Contract StartDate
                    if (relatedContract.StartDate != null) {
                        pricing.StartDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.StartDate, pricing.EBH_Site__c);
                    }
                    
                    // Check and populate End Date Offset using Contract EndDate
                    if (relatedContract.EndDate != null) {
                        pricing.EndDateOffset__c = ApexUtil.getDateTimezoneOffsetForSite(relatedContract.EndDate, pricing.EBH_Site__c);
                    }
                }
            }
        }
    }
    
}