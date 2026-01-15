/*********************************************************************************************************************************
@ Class:          CreateRevisedQuoteController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        Controller Class for CreateRevisedQuote.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  21.10.2020 / Sophal Noch / Created the class.
@               :  11.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync                
*********************************************************************************************************************************/
public without sharing class CreateRevisedQuoteController {

    private final static String OPP_CLOSE_WON_STAGE = 'Closed Won';
    private final static Id STANDARD_ADS_USER_PROFILE_ID = '00e3u000001l5JL';

    private final static String QUOTE_SOBJECT = 'Quote';
    private final static String QUOTE_OPP_ID_FIELD = 'OpportunityId';
    private final static String OPP_PRIMARY_QUOTE_FIELD = 'Primary_Quote__c';
    //US-0008802 : 10.12.2020 / Sophal Noch / adding Buyer_Accepted__c field to QUOTE_FIELD_TO_SKIPPED
    //US-0008874 : 23.12.2020 / Sophal Noch / adding HasBeenPrimary__c field to QUOTE_FIELD_TO_SKIPPED
    //US-0014020 : 11.09.2023 / Sophal Noch / adding Invoice_Authorization__c to QUOTE_FIELD_TO_SKIPPED
    private final static Set<String> QUOTE_FIELD_TO_SKIPPED = new Set<String>  {OPP_PRIMARY_QUOTE_FIELD.toLowerCase(),'dually_signed__c','legacy_sfdc_id__c','buyer_accepted__c','hasbeenprimary__c','io__c', 'invoice_authorization__c'}; // should be lower case here

    private final static Set<String> QLI_FIELD_TO_SKIPPED = new Set<String>  {'legacy_sfdc_id__c'}; // Sophal: 03/08/2021: US-0010053

    private final static String QUOTE_LINE_ITEM_SOBJECT = 'QuoteLineItem';
    private final static String REVISED_QUOTE_VERSION = ' v';
    private final static String BUTTON_NAME = 'Create_Revised_Quote';

    private final static String PRODUCT_RT_PACKAGE = 'Package';	 // 30.06.2021 / Sophal Noch / US-0009885



    /*****************************************************************************************************************************************************************
    @ Method:         apexInit
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008517
    @                 As a Advertising user in Hive Want to be able to rely upon the Opportunity record as the source of truth
    @                 So thatwe can facilitate forecasting and reconciliation of actuals
    @                 Short Description : The ability for a user to create a Revised Quote assocaited to an Opportunity after the Opportunity is Stage = 'Closed Won'
    @                 AC 1) Users are able to see a button labeled 'Create Revised Quote' from the Opportunity record. 
    @                 AC 2) When the user 'Clicks' the 'Create Revised Quote' there is a checkbox for indicating that the Quote is a 'Revised Quote'
    @                 AC 3) This 'Revised Quote' should be prevented from making changes or delete if they have a start date <= today
    @                 AC 4) the Quote should be submitted for Approval Processes if there are quote line items.
    @                 AC 5) Users Should be able to see a new checkbox on the Quote record to indicate that the Quote has been 'Dually Signed'.
    @                 AC 6) When the Checkbox 'Dually Signed' is set to true the revised Quote should be designated as the new Primary Quote.
    @                 AC 7) The existing Ad Product records must be edited to reflect any changes to the amount or end date.
    @ Event:		  when user click button 'Create Revised Quote'
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    @               :  01.12.2020/ vadhanak voun/ US-0008677 - [Ads 2020] Auto Direct to Quote record when creating a quote
    @               :  18.12.2020/ sophal noch/ US-0008678 - [Ads 2020] Naming Convention for Revision Quotes
    @               :  26.04.2021/ sophal noch/ US-0009456 - BUG - Unable to Create Revised Quote or Make Edits to Line Items
    @               :  21.05.2021/ sophal noch/ US-0009572 - Ads Bug : Error message throw while create new Revised Quote
    @               :  30.06.2021/ sophal noch/ US-0009885 - Bug in Create Revised Quote
    @               :  22.03.2022/ Loumang SENG / US-0011508 - NA ADS - Unable to Create Revised Quote on PG Opps
    ***********************************************************************************************************************************************************/
    @AuraEnabled
	public static Map<String,Object> apexInit(String oppId){

        Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
        try {
            Id profileId = Userinfo.getprofileId();
            // US-0008517 only admin and advertising user are allowed to use this feature
            // if(profileId != EBH_ConstantsUtility.ADMIN_PROFILE_ID && profileId != STANDARD_ADS_USER_PROFILE_ID ){ mapResult.put('status','ko');mapResult.put('error',System.Label.Error_No_Permission_To_Create_Revised_Quote);return mapResult;}
            
            // US-0009572 only admin or user with permission set 'eBay Ads - CSM' is allowed
            if(profileId != EBH_ConstantsUtility.ADMIN_PROFILE_ID && !Util.hasPermission(BUTTON_NAME)){mapResult.put('status','ko');mapResult.put('error',System.Label.Error_No_Permission_To_Create_Revised_Quote);return mapResult;}

            // US-0008517 The Opp stage must be 'Closed Won' and There is a primary Quote look up to The Opp.
            List<Opportunity> oppList = [
                Select Id,
                Name,
                Number_of_Quotes__c
                FROM Opportunity 
                Where Id =: oppId 
                And StageName =:OPP_CLOSE_WON_STAGE
                And Number_of_Primary_Quotes__c > 0 // primary quote must be exist. this field is roll-up summary.
                Limit 1
            ];
            if(oppList.isEmpty()){mapResult.put('status','ko');mapResult.put('error',System.Label.Error_Revised_Quote_Can_Not_Be_Created);return mapResult;}


            // US-0008517 get soql string for quote.
            // ex: Select Id,Name ... From Quote Where OpportunityId = 'xxxx' and Primary_Quote__c = true Limit 1
            Map<String, Schema.SObjectField> quoteFields = Schema.SObjectType.Quote.fields.getMap();
            String quoteSoqlFields = getSoqlFields(quoteFields,QUOTE_FIELD_TO_SKIPPED); // US-0008517 get all fields from object and skip some field if need
            quoteSoqlFields = 'Select '+quoteSoqlFields+' From '+QUOTE_SOBJECT+' Where '+QUOTE_OPP_ID_FIELD+' =:oppId And '+OPP_PRIMARY_QUOTE_FIELD+ ' = true Order By Id Desc Limit 1'; // must be order Id by Desc to get the latest result

            Quote quote = Database.query(quoteSoqlFields);
            Id quoteId = quote.Id;

            Quote clonedQuote = quote.clone(false, false, false, false);
            clonedQuote.Is_Revised_Quote__c = true; // US-0008517 set cloned quote to revised quote
            clonedQuote.Name = oppList[0].Name + REVISED_QUOTE_VERSION + (oppList[0].Number_of_Quotes__c + 1); //US-0008678
            clonedQuote.Status = 'Draft';//Loumang - US-0011508
            clonedQuote.Primary_Quote__c = false;//Loumang - US-0011508
            insert clonedQuote;

            Map<String, Schema.SObjectField> quoteLineItemFields = Schema.SObjectType.QuoteLineItem.fields.getMap();
            String qliQuery = getSoqlFields(quoteLineItemFields, QLI_FIELD_TO_SKIPPED); // US-0008517 get all fields from object and skip some field if need
            // US-0009572 use normal soql instead of inner soql to avoid inner soql limitation error
            qliQuery += ',Product2.RecordType.Name'; // 30.06.2021 / Sophal Noch / US-0009885 for checking Qli is package or not
            qliQuery = 'Select '+qliQuery+' From '+QUOTE_LINE_ITEM_SOBJECT+' Where QuoteId =: quoteId Order By package_line_item__c, Id ASC';

            Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex = new Map<Id, PackageQliIndexWrapper>();

            // US-0008517 cloning quote line item
            List<QuoteLineItem> listClonedQlItem = new List<QuoteLineItem>(); 
            Integer qIndex = 0;
            for(QuoteLineItem eachItem : Database.query(qliQuery)){
                QuoteLineItem eachClonedItem = eachItem.clone(false, false, false, false);
                eachClonedItem.QuoteId = clonedQuote.Id;
                eachClonedItem.AdProduct__c = eachItem.AdProduct__c;
                eachClonedItem.package_line_item__c = null; // 30.06.2021 / Sophal Noch / US-0009885 all child qli.package_line_item__c will be updated with new parent later.
                
                populatePackageQliIndex(eachItem, qIndex, mapOldQliIdToPkQliIndex); // 30.06.2021 / Sophal Noch / US-0009885 get index of package qli into map

                listClonedQlItem.add(eachClonedItem);

                qIndex++;
            }

            if(!listClonedQlItem.isEmpty()){

                GW_QuoteLineItem.byPassValidation = true;  //Sophal:26/04/2021:US-0009456
                insert listClonedQlItem;
                updatePkLineItemToChild(listClonedQlItem, mapOldQliIdToPkQliIndex);  // 30.06.2021 / Sophal Noch / US-0009885 update parent package qli to child package qli for revised qli
                GW_QuoteLineItem.byPassValidation = false;
            }

            mapResult.put('status','ok');
            //NK:01/12/2020:US-0008677
            mapResult.put('qid',clonedQuote.Id); //US-0008802 //US-0008677
            // mapResult.put('msg1',clonedQuote);
            // mapResult.put('msg2',listClonedQlItem);


        }catch(DMLException dex)
    	{	Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex)
    	{   Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}

        return mapResult;
    }


    private static String getSoqlFields(Map<String, Schema.SObjectField> mapFields, Set<String> fieldsToSkip){

        // US-0008517 get all fields except the one in variable fieldsToSkip. ex: primary_quote__c,dually_signed__c

        String fields = '';
        for(String fieldApiName : mapFields.keySet()){
            fieldApiName = fieldApiName.toLowerCase(); // when debugging, it shows lower case string by default but i use .toLowerCase() to make sure it is 100% lowercase.
            Schema.SObjectField field = mapFields.get(fieldApiName);
            Schema.DescribeFieldResult fieldDetail = field.getDescribe();
            if(!(fieldDetail.isCalculated() || fieldDetail.isAutoNumber()) && !fieldsToSkip.contains(fieldApiName)){ // 10.12.2020 / Sophal Noch / Will also get field names regardless of profile field permission
                fields += fieldApiName + ',';
            }
        }
        fields = fields != '' ? fields.removeEnd(',') : fields;
        return fields;
        
    }

    /*****************************************************************************************************************************************************************
    @ Method:         setRevisedQuoteToPrimary
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008517
    @                 AC 6) When the Checkbox 'Dually Signed' has been set to True for a 'Revised Quote' 
    @                 - the revised Quote should be designated as the new Primary Quote.
    @ Event:           It is called from Process Builder 'eBay Ads Updates for Existing Quotes',
    @                  When Quote is a Revised Quote and checkbox 'Dually Signed' and is set to True.
    ----------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  21.10.2020 / Sophal Noch / Created the class.
    ***********************************************************************************************************************************************************/
    @InvocableMethod
    public static void setRevisedQuoteToPrimary(List<Quote> listQuote){
        // US-0008517 call from Process Builder 'eBay Ads Updates for Existing Quotes',
        // On Criteria Name 'Set Revised Quote to Primary When Dually Signed Is True'.
        
        // US-0008517 set quotes in the list = primary
        Map<Id,Quote> mapQuoteToSetPrimary = new Map<Id,Quote>();
        Set<Id> setOppId = new Set<Id>();
        for(Quote q : listQuote){
            
            if(!q.Primary_Quote__c){ // only update quote that is not primary to primary.
                mapQuoteToSetPrimary.put(q.Id,new Quote(Id=q.Id,Primary_Quote__c = true));
                setOppId.add(q.OpportunityId);
            }
            
        }

        if(!mapQuoteToSetPrimary.isEmpty()){
            // US-0008517 set quotes not in the list but share the same opportunity = not primary
            List<Quote> listQuoteToUnSetPrimary = new List<Quote>();
            for(Quote q : [Select Id,Primary_Quote__c From Quote Where OpportunityId IN:setOppId And Id Not IN:mapQuoteToSetPrimary.keySet()]){
                listQuoteToUnSetPrimary.add(new Quote(Id=q.Id,Primary_Quote__c = false));
            }

            List<Quote> listQuoteToUpdate = mapQuoteToSetPrimary.values();
            if(!listQuoteToUnSetPrimary.isEmpty()){
                listQuoteToUpdate.addAll(listQuoteToUnSetPrimary);
            }

            update listQuoteToUpdate;

            // US-0008517 set cloned quote has quote line items, submit it for approval 
            Id userId = UserInfo.getUserId();
            List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
            for(Id quoteId : mapQuoteToSetPrimary.keySet()){
                Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
                req.setComments('Submitted for approval. Please approve.');
                req.setObjectId(quoteId);
                req.setSubmitterId(userId);
                requests.add(req);
            }
            if(!Test.isRunningTest()){Approval.process(requests);}
            


        }

    }

    private static void populatePackageQliIndex(QuoteLineItem eachQli, Integer qIndex, Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex){

        if(eachQli.Product2.RecordType.Name == PRODUCT_RT_PACKAGE)
        {
            mapOldQliIdToPkQliIndex.put(eachQli.Id, new PackageQliIndexWrapper(qIndex, new List<Integer>()));
        }
        if(
                eachQli.package_line_item__c != null
                && mapOldQliIdToPkQliIndex.containsKey(eachQli.package_line_item__c) 
                && mapOldQliIdToPkQliIndex.get(eachQli.package_line_item__c).mainPkQliIndex != qIndex
        ){
                mapOldQliIdToPkQliIndex.get(eachQli.package_line_item__c).childPkQliIndexs.add(qIndex);
        }
    }

    private static void updatePkLineItemToChild(List<QuoteLineItem> listClonedQlItem, Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex){

        if(!mapOldQliIdToPkQliIndex.isEmpty()){
            List<QuoteLineItem> listQliToUpdateMainPkId = new List<QuoteLineItem>();

            for(PackageQliIndexWrapper qliPkIndexWr : mapOldQliIdToPkQliIndex.values()){

                if(!qliPkIndexWr.childPkQliIndexs.isEmpty()){

                    Id mainPkQliId = listClonedQlItem[qliPkIndexWr.mainPkQliIndex].Id;

                    for(Integer childPkIndex : qliPkIndexWr.childPkQliIndexs){

                        QuoteLineItem qliToUpdate = new QuoteLineItem(Id = listClonedQlItem[childPkIndex].Id, package_line_item__c = mainPkQliId);
    
                        listQliToUpdateMainPkId.add(qliToUpdate);
                    }

                }

            }

            if(!listQliToUpdateMainPkId.isEmpty()){
                update listQliToUpdateMainPkId;
            }
        }
    }

    class PackageQliIndexWrapper{

        Integer mainPkQliIndex;
        List<Integer> childPkQliIndexs;

        PackageQliIndexWrapper(Integer mainPkQliIndex, List<Integer> childPkQliIndexs){

            this.mainPkQliIndex = mainPkQliIndex;
            this.childPkQliIndexs = childPkQliIndexs;
        }

    }

    
}