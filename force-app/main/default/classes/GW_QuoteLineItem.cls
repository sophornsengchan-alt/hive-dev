/*****************************************************************************************************************************
@ Class:   GW_QuoteLineItem
@ Purpose:  Class Handler for QuoteLineItem Trigger
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 05.11.2021/ Sophal Noch / Modified the Class, US-0010628 - ADS - Allow edit rights on Revised Quote Line Items in past (with date validation)
@				: 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
*****************************************************************************************************************************/
public with sharing class GW_QuoteLineItem {

    public static Boolean byPassValidation = false;

    //public static final Set<String> qliFieldsForJunctionDeltaValue = new Set<String>{Util.NS + 'SalesPriceNet__c', 'Quantity',Util.NS + 'Budget__c'};	
    
    //NK:03/12/2020:US-0008676 - [Ads 2020] Validation Exception on Start and End Dates in the Past on Quote
    //Description,Contracted Unit, Cost Per Unit,Estimated Budget
    // ------------------------------------------------------------------------------------------------------------
    //Sophal Noch: 07/12/2020:US-0008578 - [Ads 2020] Re-create Ability to Book Ad Products from the Opportunity Object
    //Field to ignore: Targeting
    // Sophal:29/12/2020: US-0008873: add subtotal, totalprice
    //NK:08/02/2021:US-0008913 // Sophal/ 08.02.2021 / US-0009094 from hotfix // Sophal/ 26.04.2021 / US-0009456 stop using variable QLI_FIELD_TO_IGNORE
    // private final static Set<String> QLI_FIELD_TO_IGNORE = new Set<String>  {'availability__c','last_availability_forecast__c','description','adproduct__c','until_date__c','budget__c','quantity__c','quantity','salespricenet__c','budget__c','sortorder__c','targeting__c','quote_adproduct_unique_key__c','subtotal','totalprice'}; // should be lower case here
    // Sophal/ 26.04.2021 / US-0009456 allow all field to change when from_date__c is in the past except from_date__c, billing_category__c

    // 28.05.2021 / Sophal Noch / US-0009582 QLI_FIELD_TO_VALIDATE not used anymore
    // private final static Set<String> QLI_FIELD_TO_VALIDATE = new Set<String>  {'from_date__c','billing_category__c'}; // should be lower case here


    // Sophal Noch: US-0008517,US-0008866 / 23/12/2020: QLI_FIELD_TO_IGNORE_ENDDATE_IN_THE_PAST this ignore fields below are for quotelineitem of Revised quote has no ad product yet 
    // and its until date is in the past 
    // and its parent record, Quote is being set to Primary which mean Quotelineitem will be sync to ad product.
    // NK:24/12/2020:US-0008873: allow end date to be changed
    // Sophal:29/12/2020: US-0008873: not allow end date to be changed. removing 'until_date__c'. It is dangerous to let end date in past of revised quotelineitem changed to future.
    //NK:08/02/2021:US-0008913 // Sophal/ 08.02.2021 / US-0009094 from hotfix
     // 28.05.2021 / Sophal Noch / US-0009582 use field set instead
    // private final static Set<String> QLI_FIELD_TO_IGNORE_ENDDATE_IN_THE_PAST = new Set<String> {'sortorder__c','adproduct__c','quote_adproduct_unique_key__c'}; // should be lower case here

    private final static String QLI_FROM_DATE_FNAME = 'from_date__c';
    private final static String QLI_BILLCATE_FNAME = 'billing_category__c';


	public static boolean isRevision(QuoteLineItem qli ){
		//return qli.Quote.Opportunity.Type == Label.OPP_TYPE_DIRECT_REVISION; //MN-01072019 - We no longer use Direct Revision RecordType or any picklist value anymore
        return qli.Quote.Media_Plan__r.IsRevision__c;
	}
	
    // Sophal:01/03/2021:US-0009134 need to change Billing_Category__c to multi-select picklist value
	// public static boolean isCPM(QuoteLineItem qli ){
	// 	return qli.Product2.Billing_Category__c == 'CPM';
	// }

    private static Set<String> setQliFields; // 28.05.2021 / Sophal Noch / US-0009582 

    
    private final static String QLI_UNTIL_DATE_FNAME = 'until_Date__c';
    // @ Change history : 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
    // private final static Set<String> SET_QLI_FIELDS_WITH_PS = new Set<String>{
    //     'Quantity','Quantity__c','Budget__c','Subtotal','TotalPrice',QLI_UNTIL_DATE_FNAME
    // };
    // private final static Set<String> SET_DAULLY_SIGNED_PERM = new Set<String>{'eBay_Ads_Set_Dually_Signed_Closed_Won'}; 
    // end  US-0009038
    private static Boolean hasDuallSignPermiss = false;

    public static Map<Id, IO_LineItem__c> getMapQliId2IOline(List<QuoteLineItem> qlis){
    	//Map<Id, QuoteLineItem> mapQli = new Map<Id, QuoteLineItem>(qlis);
        if( qlis.isEmpty() ) return new Map<Id, IO_LineItem__c>();
    	Set<Id> IOIds = new Set<Id>();
    	for(QuoteLineItem qli :qlis){
    		IOIds.add(qli.Quote.IO__c);
    	}
        
        Map<String, IO_LineItem__c> mapIOLines = new Map<String, IO_LineItem__c>((List<IO_LineItem__c>) QueryUtil.queryRecords(Util.NS+'IO_LineItem__c', Util.NS+'IO__c IN:value1', new Map<String,Object>{'value1'=>IOIds}) );
        Map<String, QuoteLineItem> mapQlis = new Map<String, QuoteLineItem>(qlis);
        Map<Id, IO_LineItem__c> mapQliId2IOLineItems = new Map<Id, IO_LineItem__c>();
        for(IO_LineItem_Junction__c junc: (List<IO_LineItem_Junction__c>) QueryUtil.queryRecords(Util.NS + 'IO_LineItem_Junction__c', Util.NS+'IO_LineItem__c IN:value1 and '+Util.NS+'Quote_LineItem__c IN:value2', new Map<String, Object>{'value1'=>mapIOLines.keySet(), 'value2'=>mapQlis.keySet() }) ) {
            String qliId = junc.Quote_LineItem__c;
            String ioLineId = junc.IO_LineItem__c;

            if(!mapQlis.containsKey(qliId) || !mapIOLines.containsKey(ioLineId)) continue;

            IO_LineItem__c IOLineItem= mapIOLines.get(ioLineId);
            mapQliId2IOLineItems.put(qliId, IOLineItem);
        }
        return mapQliId2IOLineItems;

    }

    public static Map<Id, IO_LineItem__c> getMapQliId2IOline(Set<String> qliIds){
        //Map<Id, QuoteLineItem> mapQli = new Map<Id, QuoteLineItem>(qlis);
        if( qliIds.isEmpty() ) return new Map<Id, IO_LineItem__c>();
        return GW_QuoteLineItem.getMapQliId2IOline( (List<QuoteLineItem>) QueryUtil.queryRecords('QuoteLineItem', new Set<String>{ 'Quote.'+Util.NS+'IO__c'}, qliIds) )  ;

    }

    public static List<IO_LineItem__c> getIOLines(List<QuoteLineItem> qlis){
        return GW_QuoteLineItem.getMapQliId2IOline(qlis).values();
    }

    public static void updateIOLineItem(List<QuoteLineItem> qlis ){
    	List<QLI2IOLI_Mapping__mdt> fieldMappers = (List<QLI2IOLI_Mapping__mdt>) QueryUtil.queryRecords(Util.NS+'QLI2IOLI_Mapping__mdt',Util.NS+'update__c=true');
    	if(fieldMappers.isEmpty() || qlis.isEmpty()) return;
    	Map<Id, IO_LineItem__c> mapQliId2IOline = GW_QuoteLineItem.getMapQliId2IOline(qlis) ;
        Map<Id, IO_LineItem__c> mapIOLineToUpdate = new Map<Id, IO_LineItem__c>();
        for(QuoteLineItem qli:qlis){
            if(!mapQliId2IOline.containsKey(qli.Id)) continue;
            Id IOLineIdOfQli = mapQliId2IOline.get(qli.Id).Id;
            IO_LineItem__c IOLine = mapIOLineToUpdate.containsKey(IOLineIdOfQli) ? mapIOLineToUpdate.get(IOLineIdOfQli) : new IO_LineItem__c(Id=IOLineIdOfQli);
            for(QLI2IOLI_Mapping__mdt fieldMapper: fieldMappers) {
                
                IOLine.put(fieldMapper.IO_LineItem_Field__c, qli.get( fieldMapper.Quote_LineItem_Field__c) );
            }
            mapIOLineToUpdate.put(IOLineIdOfQli, IOLine);
        }
		update mapIOLineToUpdate.values();
    }

    public static boolean isCopiedQli(QuoteLineItem qli) { return String.isNotBlank(qli.ClonedFrom__c); }

    //MN-28092019
    public static void deleteIOLI (Set<Id> qliIds) {

        //Find corresponding IOLI to delete
        List<IO_LineItem_Junction__c> iolijs = (List<IO_LineItem_Junction__c>) QueryUtil.queryRecords(Util.NS+'IO_LineItem_Junction__c', Util.NS+'Quote_LineItem__c IN:value1', new Map<String,Object>{'value1'=>qliIds});

        Set<Id> sIOLIIds = new Set<Id>();
        
        for (IO_LineItem_Junction__c iolij : iolijs) sIOLIIds.add(iolij.IO_LineItem__c);

        System.debug('##### sIOLIIds :: ' + sIOLIIds);

        if (!sIOLIIds.isEmpty()) delete [SELECT Id FROM IO_LineItem__c WHERE Id IN:sIOLIIds];
    }

/*****************************************************************************************************************************************************************
    @ Method:         prepopulateQLIFields
    @ Version:        1.0
    @ Author:         Mony Nou (mony.nou@gaea-sys.com)
    @ Purpose:        US-0009582
    @                 All the values that are set on QLI in GW_Quote2.copyDiscountsFromQuoteToQuoteLineItems need to be set in the product configurator (where some are editable) 
                      and written to the QLI on insert.
    @ Event:		  it run when trigger is before insert or before update from class QuoteLineItemMainTriggerHandler
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  27.05.2021 / Mony Nou / Created method.
    ***********************************************************************************************************************************************************/
    public static void prepopulateQLIFields (List<QuoteLineItem> newList, Map<Id,QuoteLineItem> oldMap) {
        
        for (QuoteLineItem qli : newList) {

            // QuoteLineItem old_qli = (oldMap != null)?oldMap.get(qli.Id):new QuoteLineItem(); // 28.05.2021 / Sophal Noch // modified, because need old qli need to be null if trigger is insert
            
            QuoteLineItem old_qli = (oldMap != null) ? oldMap.get(qli.Id) : null;
            validateAdproductLookup(qli, old_qli);  // 28.05.2021 / Sophal Noch / US-0009582 move to here instead.
            if(old_qli == null){old_qli = new QuoteLineItem();}

            //Calculate for QLI.Amount_Net_Net_Net__c
            if (oldMap == null || ( qli.Sales_Price_incl_Targeting__c != old_qli.Sales_Price_incl_Targeting__c
                || qli.Billing_Category__c != old_qli.Billing_Category__c
                || qli.Quantity != old_qli.Quantity
                || qli.Special_Agency_Discount_Percent__c != old_qli.Special_Agency_Discount_Percent__c
                || qli.Rate_Discount_I__c != old_qli.Rate_Discount_I__c
                || qli.Rate_Discount_II__c != old_qli.Rate_Discount_II__c)) {

                qli.Amount_Net_Net_Net__c = GW_Quote2.calculateAmountNetNetNet(qli); 
                //qli.Budget__c = GW_Quote2.calculateBudget(qli);   maybe an option for user manually input
                qli.Quantity__c = qli.Quantity;
            }
       
        }
    }


/*****************************************************************************************************************************************************************
    @ Method:         preventDeletingOrUpdatingQli
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008517
    @                 AC 3) This 'Revised Quote' should be user editable however the user should be prevented from making changes to the 'Start Date' of 
    @                 any QuoteLineItems by greying / preventing the user from changing them out if they have a start date <= today
    @                 3a - no changes should be allowed if both the start date and end date are in the past (all fields greyed)
    @                 3b - a quote line item cannot be deleted if the start date is in the past. However, any line that has both dates in the future, 
    @                 can be deleted if required.
    @ Event:		  it run when trigger is before insert or before delete. it validates only quotelineitems of revised quote.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.12.2020 / Sophal Noch / Update the method.
    @               : 24.12.2020 / vadhanak voun/ US-0008873 - [Ads 2020] Bug - Unable to Change Budget, Quantity, CPU when Start Date is in the past
    @               : 29.12.2020 / Sophal Noch/ US-0008873 - Revert back some conditions in code.
    @               : 04.10.2021 / Sophal Noch/ US-0010555 - ADS - Validation skip on setting AD on Ad product for PVP
    @				: 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
    ***********************************************************************************************************************************************************/
    public static void preventDeletingOrUpdatingQli(List<QuoteLineItem> listOldQli,Map<Id,QuoteLineItem>  mapNewQli){
        
        Date todayDate = System.today();
        Boolean isDeleted = mapNewQli == null ? true : false;

        for(QuoteLineItem oldQli : listOldQli){
            
            //Trigger is delete, we add error to old trigger. Trigger is update, we add error to new trigger
            QuoteLineItem qliToPrevent = isDeleted ? oldQli : mapNewQli.get(oldQli.Id);

            // 18.12.2020 / Sophal Noch / US-0008866 if ad product is booked and the ad product is lookup to quotelineitem. the quotelineitem must not be deleted.
            // if(isDeleted && String.isNotBlank(qliToPrevent.Adproduct_Ad_Id__c)){qliToPrevent.addError(Label.Error_QuoteLineItem_Cannot_Be_Deleted_When_AdProduct_Has_Been_Booked);}

            // 04.10.2021 / Sophal Noch / US-0010555
            if(isDeleted && qliToPrevent.IsInGamOrCallisto__c){qliToPrevent.addError(Label.Error_QuoteLineItem_Cannot_Be_Deleted_When_AdProduct_Has_Been_Booked);}

            /*
                // 28.05.2021 / Sophal Noch / US-0009582 move this to other method prepopulateQLIFields;

                // 18.12.2020 / Sophal Noch / US-0008866 validata AdProduct__c field in quotelineitem
                if(!isDeleted){validateAdproductLookup(qliToPrevent,oldQli);}
            
            */

            // US-0008517 use old trigger quotelineitem date fields to check regardless if trigger is delete or update.
            // but Is_Revised_Quote__c must be from new trigger if trigger is update.
            if(
                // qliToPrevent.Is_Revised_Quote__c && (oldQli.until_Date__c < todayDate) //NK:24/12/2020:US-0008873
                qliToPrevent.Is_Revised_Quote__c && (oldQli.from_Date__c <= todayDate || oldQli.until_Date__c <= todayDate) //Sophal :29/12/2020:US-0008873 add back conditon
            ){

                String updateErrorMsg = '';

                // US-0008517 skip adding error to Quotelineitem if no field changed and it lookup to newly created Ad Product, and end date in future
                 
                Set<String> changedFields = new Set<String>();
                // Set<String> changedFieldsWhenEndDateInThePast = new Set<String>();
                if(!isDeleted){

                    if(byPassValidation){return;} //Sophal:26/04/2021:US-0009456
                    
                    /* 
                    // 28.05.2021 / Sophal Noch / US-0009582 no need to check every field at first.

                    // changedFields is for fields that can be ignore when quotelineitem is updated and its until_date__c is not the past
                    changedFields = hasFieldChanged(setQliFields,oldQli,mapNewQli.get(oldQli.Id)); // 28.05.2021 / Sophal Noch / US-0009582 pass set string of fiedl instead of Schema.SObjectField
                    if(changedFields.isEmpty()){continue;}

                    */
                    
                    // Boolean endDateGetSmallerThanToday = (oldQli.from_Date__c <= todayDate && oldQli.until_Date__c >= todayDate && qliToPrevent.until_Date__c < todayDate) ? true : false;
                    // 05.11.2021 / Sophal Noch / US-0010628 : when user decease past end date
                    Boolean endDateGetSmallerThanToday = qliToPrevent.until_Date__c < oldQli.until_Date__c && qliToPrevent.until_Date__c < todayDate;
                      

                    if(
                        oldQli.until_Date__c < todayDate || endDateGetSmallerThanToday // Sophal/ 26.04.2021 / US-0009456 if end date is today, you can increase it but you can not decrease it.
                    ){

                         /* 
                                // 28.05.2021 / Sophal Noch / US-0009582 we don't check every field anymore so because old record obj might be == new record obj.

                                // // Sophal Noch: US-0008517,US-0008866 / 23/12/2020

                                // // this is for revised quotelineitem who in the past and has no ad product yet and it is being sync to ad product for the first time
                                // for(String ignoredField : QLI_FIELD_TO_IGNORE_ENDDATE_IN_THE_PAST){
                                //     if(changedFields.contains(ignoredField)){changedFields.remove(ignoredField);}
                                // }


                         */

                        if(oldQli != qliToPrevent){ // 28.05.2021 / Sophal Noch / US-0009582 if there are difference between old record obj and new record obj, check to find different fields
                            changedFields = hasFieldChanged(oldQli,qliToPrevent); 
                        }
                        
                        // 05.11.2021 / Sophal Noch / US-0010628 with daully sign permission set, it won't allow to change past date even furthur in th past
                        
                        // if(endDateGetSmallerThanToday && hasDuallSignPermiss){changedFields.add(QLI_UNTIL_DATE_FNAME);} // @ Change history : 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
                        
                        updateErrorMsg =  endDateGetSmallerThanToday ? Label.Error_Revised_QLI_Can_Not_Be_Updated_DueTo_EndDateIsToday : Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Updated;

                    }else if(
                        oldQli.until_Date__c >= todayDate && qliToPrevent.until_Date__c >= todayDate &&
                        // && (oldQli.from_date__c != qliToPrevent.from_date__c || oldQli.billing_category__c != qliToPrevent.billing_category__c) // 28.05.2021 / Sophal Noch / US-0009582 only 2 fields so check this in condition instead of set string field. // @ Change history : 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
                        (oldQli.billing_category__c != qliToPrevent.billing_category__c) // 28.05.2021 / Sophal Noch / US-0009582 only 2 fields so check this in condition instead of set string field.
                        
                    ){

                        /*
                        // 28.05.2021 / Sophal Noch / US-0009582 only 2 fields, so not used block of code below anymore, so need to use set string field

                        // this is for revised quotelineitem who in the past and has no ad product yet and it is being sync to ad product for the first time
                        // for(String ignoredField : QLI_FIELD_TO_IGNORE){
                        //     if(changedFields.contains(ignoredField)){changedFields.remove(ignoredField);}
                        // }

                        // Sophal/ 26.04.2021 / US-0009456 field in QLI_FIELD_TO_VALIDATE can not be modified if start date is in the past
                       
                        
                        // Set<String> notAllowedFields = new Set<String>(); 
                        // for(String validatedField : QLI_FIELD_TO_VALIDATE){
                        //     if(changedFields.contains(validatedField)){notAllowedFields.add(validatedField);}
                        // }
                        // changedFields = notAllowedFields;

                        */

                       // if(oldQli.from_date__c != qliToPrevent.from_date__c){changedFields.add(QLI_FROM_DATE_FNAME);} // 28.05.2021 / Sophal Noch / US-0009582 // @ Change history : 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
                        if(oldQli.billing_category__c != qliToPrevent.billing_category__c){changedFields.add(QLI_BILLCATE_FNAME);} // 28.05.2021 / Sophal Noch / US-0009582

                        updateErrorMsg = Label.Error_Revised_QLI_Can_Not_Be_Updated_DueTo_FromDate;

                    }

                    if(changedFields.isEmpty()){continue;}

                }

                String errorMsg = isDeleted ? Label.Error_Revised_Quote_Line_Item_Can_Not_Be_Deleted : updateErrorMsg + ' : '+changedFields;
                qliToPrevent.addError(errorMsg);
            }
            

        }
    }
    
    private static Set<String> hasFieldChanged(QuoteLineItem oldQli, QuoteLineItem neWQli){
        // 28.05.2021 / Sophal Noch / US-0009582 static variable setFields, use set string of field instead of field schema
        
        if(setQliFields == null){ // 28.05.2021 / Sophal Noch / US-0009582 store only field that are not formula and auto number

            Set<String> fieldsToIgnore = new Set<String>();
            for(Schema.FieldSetMember f : SObjectType.QuoteLineItem.FieldSets.QLI_FIELD_TO_IGNORE_ENDDATE_IN_THE_PAST.getFields()){ // 28.05.2021 / Sophal Noch / US-0009582 store ignore field in field set 
                fieldsToIgnore.add(f.getFieldPath());
            }

            // @ Change history : 26.07.2022 / Chetra Sarom / US-0009038 - Edit/ Delete line items with dates in the past
            // // 05.11.2021 / Sophal Noch / US-0010628 with permission set, we enable to update following fields in SET_QLI_FIELDS_WITH_PS
            // hasDuallSignPermiss = ApexUtil.checkPermissionSet(SET_DAULLY_SIGNED_PERM);
            // if(hasDuallSignPermiss){
                // fieldsToIgnore.addAll(SET_QLI_FIELDS_WITH_PS);
            // }
            // end US-0009038

            setQliFields = new Set<String>();
            for(Schema.SObjectField field : Schema.SObjectType.QuoteLineItem.fields.getMap().values()){

                Schema.DescribeFieldResult fieldDetail = field.getDescribe();

                if(!(fieldDetail.isCalculated() || fieldDetail.isAutoNumber())){

                    String fieldApiName = fieldDetail.getName();
                    if(!fieldsToIgnore.contains(fieldApiName)){ // 28.05.2021 / Sophal Noch / US-0009582 ignore fields in constant, so no need to check those later.
                        setQliFields.add(fieldApiName);
                    }
                    
                }
            }

        }
        
        Set<String> changedFields = new Set<String>();
        // US-0008517
        for(String fieldApiName : setQliFields){
            
            if(oldQli.get(fieldApiName) != neWQli.get(fieldApiName)){
                // changedFields.add(fieldApiName.toLowerCase()); // 28.05.2021 / Sophal Noch / US-0009582 no need to do lower case anymore because we already ignore some fields when getting all qli fields
                changedFields.add(fieldApiName);  // 28.05.2021 / Sophal Noch / US-0009582
            }
        }
        return changedFields;
        
    }

    // /*****************************************************************************************************************************************************************
    // @ Method:         validateAdproductLookup
    // @ Version:        1.0
    // @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    // @ Purpose:        US-0008866
	// @                 As a...
    // @                 Advertising User in Hive
    // @                 Want to...
    // @                 ensure that Quote Line Items and Ad Products cannot be deleted once they have been booked to DFP
    // @                 So that...
    // @                 we can ensure that delivery and financial forecasts are not deleted.
    // @                 Description
    // @                 AC 1) As any user, I should not be able to delete a Quote Line Item & Ad Product when the Ad Product has been booked to DFP.
    // @                 Any Ad Product with an 'Ad Id' populated means that it has been booked to DFP - the Ad Product should not be able to be deleted.
    // @                 
    // @                 Where the Ad Product has an Ad Id - the associated Quote Line Item (via Lookup to Ad Product) should also not be able to be deleted.
    // ----------------------------------------------------------------------------------------------------------------------------------------------------------
    // @ Change history:  18.12.2020 / Sophal Noch / Created the method.
    // @ Change history:  28.05.2021 / Sophal Noch / US-0009582 method not used anymore
    // ***********************************************************************************************************************************************************/
    // public static void validateAdproductLookup(List<QuoteLineItem> listNewQli){
    //     for(QuoteLineItem newQli : listNewQli){
    //         validateAdproductLookup(newQli, null);
    //     }
    // }

    /*****************************************************************************************************************************************************************
    @ Method:         validateAdproductLookup
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008866
	@                 As a...
    @                 Advertising User in Hive
    @                 Want to...
    @                 ensure that Quote Line Items and Ad Products cannot be deleted once they have been booked to DFP
    @                 So that...
    @                 we can ensure that delivery and financial forecasts are not deleted.
    @                 Description
    @                 AC 1) As any user, I should not be able to delete a Quote Line Item & Ad Product when the Ad Product has been booked to DFP.
    @                 Any Ad Product with an 'Ad Id' populated means that it has been booked to DFP - the Ad Product should not be able to be deleted.
    @                 
    @                 Where the Ad Product has an Ad Id - the associated Quote Line Item (via Lookup to Ad Product) should also not be able to be deleted.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.12.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************/

    public static void validateAdproductLookup(QuoteLineItem newQli, QuoteLineItem oldQli){
        


        if(oldQli == null || newQli.AdProduct__c != oldQli.AdProduct__c){

            // 18.12.2020 / Sophal Noch / US-0008866 : one AdProduct Id must be belong to one opportunity only
            if(newQli.AdProduct__c != null &&  newQli.QuoteOpportunityId__c != newQli.AdproductOpportunityId__c){
                newQli.AdProduct__c = null; 
            }

            // 18.12.2020 / Sophal Noch / US-0008866 : one Quotelineitem.AdProduct__c can not have duplicate value in the same Quote
            if(newQli.AdProduct__c != null){
                newQli.Quote_AdProduct_Unique_Key__c = newQli.QuoteId + '_' + newQli.AdProduct__c;
            }else{
                newQli.Quote_AdProduct_Unique_Key__c = null;
            }

        }


    }


}