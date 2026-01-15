/*********************************************************************************************************************************
@ Class:         CloneQuoteController
@ Version:       1.0
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0009693 - Modify Clone Quote Functionality
@                   - Controller Class for CloneQuote Lightning Component
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  	15.06.2021 / Mony Nou (mony.nou@gaea-sys.com) / Created the class.
@               :   11.09.2023 / Sophal Noch / US-0014020 - PL Opportunity Process - Ad product Sync      
@               :   30.06.2025 / Sambath Seng / US-0033002 Cannot withdraw approval on quote that I approved
*********************************************************************************************************************************/
public without sharing class CloneQuoteController {

    private static String PERMISSION_CLONEQUOTE = 'eBay_Ads_Clone_Quote'; // 30.06.2025 Sambath Seng  US-0033002
    private static Set<String> VALID_PROFILE = new Set<String>{'Standard Ads User Profile','Standard Ads EU User Profile', 'System Administrator'};
    private static Set<String> sLinkRelField = new Set<String>{'Account.Name', 'Opportunity.Name'};
    private static Map<String,String> mapLinkField = new Map<String,String>{'Name'=>'Name','AccountId'=>'AccountId', 'OpportunityId' => 'OpportunityId'};
    private final static String PRODUCT_RT_PACKAGE = 'Package';	

    private final static String DEFAULT_TARGETING_RECORD_TYPE_ID = Schema.SObjectType.Targeting__c.getRecordTypeInfosByDeveloperName().get('Targeting').getRecordTypeId();

    private static Set<Id> sValidProfileIds {
        get {
            if (sValidProfileIds ==  null) {
                sValidProfileIds = new Set<Id>();
                for (Profile p : [SELECT Id From Profile WHERE Name IN:VALID_PROFILE]) sValidProfileIds.add(p.Id);
            }

            return sValidProfileIds;
        }
        private set;
    }

    //Check Permission - Only user with 'ebay ads - CSM' permission set and 'Standard Ads User Profile' or 'Standard Ads EU User Profile' able to use this logic
    public static Boolean isValid() {
        return FeatureManagement.checkPermission(PERMISSION_CLONEQUOTE) || Test.isRunningTest(); // 30.06.2025 Sambath Seng US-0033002 remove checking for profile name
    }

    @AuraEnabled
    public static Map<String,Object> apexInit(String oppId) {	
        
        Map<String,Object> mapResult = new Map<String,Object>();
        Opportunity opp = [Select Id, RecordTypeId From Opportunity Where Id =: oppId Limit 1];
        String sWhereQuote  = ' Where Opportunity.RecordTypeId = \''+opp.RecordTypeId+'\''; // Sophal: 02/08/2021: US-0010053 remove 'Legacy_SFDC_ID__c = NULL' from condition.
        List<ColName> listColNameQuote = new List<ColName>();
        Set<String> setFieldNameQuote = new Set<String>{'id'};
        for(Schema.FieldSetMember f: SObjectType.Quote.FieldSets.Clone_Quote.getFields())
        {   
            
            setFieldNameQuote.add(f.getFieldPath());
            listColNameQuote.add(
                new ColName(f.getLabel(),
                f.getFieldPath(),
                f.getType()+'')
            );
        }

        setFieldNameQuote.addAll(sLinkRelField);



        String soql_quote = 'Select '+String.join(new List<String>(setFieldNameQuote),',')+' From Quote';
        mapResult.put('status','ok');
        mapResult.put('soql_quote',soql_quote);
        mapResult.put('sWhereQuote',sWhereQuote);
        mapResult.put('listColNameQuote',listColNameQuote);
        mapResult.put('sitePrefix',Site.getPathPrefix());
        

        return mapResult;
    }
    
    @AuraEnabled
	public static Map<String,Object> apexSave(String quoteId, String oppId){

		Map<String,Object> mapResult = new Map<String,Object>();
        Savepoint sp = Database.setSavepoint();
		try {

            // List<Quote> quotes = (List<Quote>) QueryUtil.queryRecords('Quote', 'Id=:value1',new Set<String>(), new Map<String,Object>{'value1'=>quoteId});
            String quoteSoqlQuery = getSoqlFields(Schema.SObjectType.Quote.fields.getMap());
            quoteSoqlQuery = 'Select '+ quoteSoqlQuery +' From Quote Where Id =: quoteId';
            List<Quote> quotes = Database.query(quoteSoqlQuery);

            Quote cloneQuote = quotes[0].clone(false, false, false, false);
            cloneQuote.OpportunityId = oppId;
            resetQuote(cloneQuote);
            insert cloneQuote;

            // List<QuoteLineItem> listQli = (List<QuoteLineItem>) QueryUtil.queryRecords('QuoteLineItem', 'QuoteId=:value1 Order By package_line_item__c, Id ASC',new Set<String>{'PriceBookEntry.Product2Id','Product2.RecordType.Name','Product2.Name'}, new Map<String,Object>{'value1'=>quoteId});
            String qliSoqlQuery = getSoqlFields(Schema.SObjectType.QuoteLineItem.fields.getMap());
            qliSoqlQuery += ',PriceBookEntry.Product2Id,Product2.RecordType.Name,Product2.Name';
            qliSoqlQuery = 'Select '+ qliSoqlQuery + ' From QuoteLineItem Where QuoteId =: quoteId Order By package_line_item__c, Id ASC';
            List<QuoteLineItem> listQli = Database.query(qliSoqlQuery);

            if(!listQli.isEmpty()){

                Map<Id,Product2> mapProduct = new Map<Id,Product2>();
                Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex = new Map<Id, PackageQliIndexWrapper>();
                // 28.05.2021 / Sophal Noch / US-0009753 get products, available site, and package Qli index
                getProductsAndQliPackages(listQli,mapProduct, mapOldQliIdToPkQliIndex);
    
                Map<Integer, Targeting__c> mQliId2InsertTg = new Map<Integer, Targeting__c>();
                Map<String,String> mapQli2Targeting = new Map<String,String>();
                // 28.05.2021 / Sophal Noch / US-0009753 generate clone qli, prepare targeting, store index of package qli
                List<QuoteLineItem> listClonedQli = generateClonedQli(cloneQuote.Id, listQli, mapProduct, mQliId2InsertTg, mapQli2Targeting);

                GW_QuoteLineItem.byPassValidation = true;
                // 28.05.2021 / Sophal Noch / US-0009753 insert targeting, cloned qli to database
                listClonedQli = createTargetingAndClonedQli(listClonedQli, mQliId2InsertTg, mapQli2Targeting, mapOldQliIdToPkQliIndex);
                GW_QuoteLineItem.byPassValidation = false;

            }

			mapResult.put('status','ok');
            mapResult.put('clonedId',cloneQuote.Id);

		}catch(DMLException dex)
    	{   Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
    	}catch(Exception ex)
    	{   Database.rollback(sp);mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());	}
        
		return mapResult;
	}

    private static void getProductsAndQliPackages(List<QuoteLineItem> listQli, Map<Id,Product2> mapProduct, Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex ){
        
        Set<String> setProductId = new Set<String>();
        Integer qIndex = 0;
        for(QuoteLineItem qli : listQli){

            if(qli.Product2.RecordType.Name == PRODUCT_RT_PACKAGE)
			{
                mapOldQliIdToPkQliIndex.put(qli.Id, new PackageQliIndexWrapper(qIndex, new List<Integer>()));
            }
            if(
                qli.package_line_item__c != null
                && mapOldQliIdToPkQliIndex.containsKey(qli.package_line_item__c) 
                && mapOldQliIdToPkQliIndex.get(qli.package_line_item__c).mainPkQliIndex != qIndex
            ){
                mapOldQliIdToPkQliIndex.get(qli.package_line_item__c).childPkQliIndexs.add(qIndex);
            }


            if(qli.Product2Id != null) setProductId.add(qli.Product2Id);
            if(qli.Product2Id==null && qli.PriceBookEntry <> null) setProductId.add(qli.PriceBookEntry.Product2Id);
            
            qIndex++;
        }

        if (!setProductId.isEmpty()) {
            for (Product2 prod : [SELECT Id,Advertising_Medium__r.AdServer_Keywords_Key_Values__c, (SELECT Available_Site__c FROM Available_Sites__r) FROM Product2 WHERE Id IN:setProductId])
            {
                mapProduct.put(prod.Id,prod);
            } 
        }


    }

    private static List<QuoteLineItem> generateClonedQli(Id clonedQuoteId, List<QuoteLineItem> listQli,Map<Id,Product2> mapProduct,  Map<Integer, Targeting__c> mQliId2InsertTg, Map<String,String> mapQli2Targeting){
        
        List<QuoteLineItem> listClonedQli = new List<QuoteLineItem>();

        Integer qIndex = 0;
        for(QuoteLineItem qli : listQli){

            QuoteLineItem clonedQli = qli.clone(false, false, false, false);

            String tgId = clonedQli.Targeting__c;

            if( tgId==null) {

                Product2 prodWithAdsMedium = (mapProduct.containsKey(qli.Product2Id)) ? (mapProduct.get(qli.Product2Id)) : null;
				String adServerKeyWordKeyValue = (prodWithAdsMedium != null && prodWithAdsMedium.Advertising_Medium__r != null) ? prodWithAdsMedium.Advertising_Medium__r.AdServer_Keywords_Key_Values__c : null;

                mQliId2InsertTg.put(qIndex, new Targeting__c(Description__c = qli.Product2.Name + ' Targeting',KeyValueString__c=adServerKeyWordKeyValue));

            }else{
                //no id here because QLI not yet insert
                mapQli2Targeting.put(qIndex+'',tgId);
            }

            clonedQli.QuoteId = clonedQuoteId;
            resetQli(clonedQli);

            listClonedQli.add(clonedQli);

            qIndex++;
        }
        return listClonedQli;
    }

    // private static Map<Integer,String> cloneTargetingAndItsAssociations(Map<String,String> mapQli2Targeting, Boolean removeTgRecType){

    //     // System.debug('nsp: custom  mapQli2Targeting == '+mapQli2Targeting);   

    //     Set<Id> targetingId = new Set<Id>();
    //     for(Id oldTarId : mapQli2Targeting.values()){
    //         targetingId.add((Id)oldTarId);
    //     }
    
    //     Map<Id,Targeting__c> mapOldTargeting = new Map<Id,Targeting__c>((List<Targeting__c>) QueryUtil.queryRecords(Util.NS+'Targeting__c',' Id IN:value1',new Map<String, Object>{'value1'=>targetingId}));
    //     Map<String,Targeting__c> mapOldTarIndexWithNewTar = new Map<String,Targeting__c>();
    //     Map<String,List<Targeting__c>> mapOldTarIdWithNewListTar = new Map<String,List<Targeting__c>>();

    //     for(String qIndex : mapQli2Targeting.keySet()){

    //         String oldTarId = mapQli2Targeting.get(qIndex);

    //         if(mapOldTargeting.containsKey(oldTarId)){

    //             Targeting__c cloneTargeting = mapOldTargeting.get(oldTarId).clone();
    //             if(removeTgRecType){
    //                 cloneTargeting.RecordTypeId = DEFAULT_TARGETING_RECORD_TYPE_ID;
    //             }
    //             mapOldTarIndexWithNewTar.put(qIndex, cloneTargeting);

    //             if(!mapOldTarIdWithNewListTar.containsKey(oldTarId)){
    //                 mapOldTarIdWithNewListTar.put(oldTarId, new List<Targeting__c>());
    //             }
    //             mapOldTarIdWithNewListTar.get(oldTarId).add(cloneTargeting); // cloneTargeting in mapOldTarIndexWithNewTar and mapOldTarIdWithNewListTar are linked by object reference.
                

    //         }
    //     }

    //     mapOldTargeting.clear();
    //     insert mapOldTarIndexWithNewTar.values();

    //     Map<Integer,String> mapQli2NewTargeting = new Map<Integer,String>();
    //     for(String qliIndex : mapQli2Targeting.keySet()){
    //         String newTarId = mapOldTarIndexWithNewTar.containsKey(qliIndex) ? mapOldTarIndexWithNewTar.get(qliIndex).Id : null;
    //         mapQli2NewTargeting.put(Integer.valueOf(qliIndex), newTarId);
    //     }
    
    //     Set<String> setAssociationSObjects = new Set<String>
    //                     {Util.NS+'TargetingGeographyAssociation__c',
    //                     Util.NS+'TargetingKeyValueAssociation__c',
    //                     Util.NS+'TargetingDeviceAssociation__c',
    //                     Util.NS+'TargetingConnectionAssociation__c',
    //                     Util.NS+'TargetingFrequencyAssociation__c',
    //                     Util.NS+'PlacementTargetingAssociation__c',
    //                     Util.NS+'TargetingContentAssociation__c'};

    //         for(String sObjectName : setAssociationSObjects){

    //             List<SObject> listAssocToInsert = new List<SObject>();
    
    //             for(sObject associateExisting: QueryUtil.queryRecords(sObjectName,Util.NS+'Targeting__c IN:value1 Order By Targeting__c ASC', new Map<String,Object>{'value1'=>targetingId})) {
    
    //                 Id tgOldId = (Id)associateExisting.get(Util.NS+'Targeting__c');
    
    //                 if(mapOldTarIdWithNewListTar.containsKey(tgOldId)){

    //                     for(Targeting__c newTarget : mapOldTarIdWithNewListTar.get(tgOldId)){

    //                         SObject associateNew = associateExisting.clone();
    //                         Id tgNewId = newTarget.Id;
    //                         associateNew.put(Util.NS+'Targeting__c', tgNewId );
        
    //                         if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingKeyValueAssociation__c')) {                            
    //                             String kvId = associateExisting.get('GAM_Key_Value__c') <> null?associateExisting.get('GAM_Key_Value__c')+'':associateExisting.get('Audience_Segment__c')+'';
    //                             associateNew.put(Util.NS+'TargetKeyValue__c', tgNewId+''+kvId+''+associateNew.get(Util.NS+'Operator__c'));
        
    //                         } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingDeviceAssociation__c')) {
    //                             associateNew.put(Util.NS+'TargetDevice__c', tgNewId+''+associateNew.get(Util.NS+'Device__c'));
    //                         } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingConnectionAssociation__c')) {
    //                             associateNew.put(Util.NS+'TargetConnection__c', tgNewId+''+associateNew.get(Util.NS+'Connection__c'));
    //                         } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingGeographyAssociation__c')) {
    //                             associateNew.put(Util.NS+'TargetGeography__c', tgNewId+''+associateNew.get(Util.NS+'Geography__c'));
    //                         } else if(sObjectName.equalsIgnoreCase(Util.NS+'TargetingContentAssociation__c')) {
    //                             associateNew.put(Util.NS+'Target_Content_Key__c', tgNewId+''+associateNew.get(Util.NS+'TargetingContent__c'));
    //                         } 
        
    //                         listAssocToInsert.add(associateNew);
    //                     }


    
    //                 }
    
    //             }

    //             if(!listAssocToInsert.isEmpty()){
    //                 insert listAssocToInsert;
    //             }
    
    //         }

    //         // System.debug('nsp: custom  mapQli2NewTargeting == '+mapQli2NewTargeting);   

    //         return mapQli2NewTargeting;
    
    // }


    private static List<QuoteLineItem> createTargetingAndClonedQli(List<QuoteLineItem> listClonedQli, Map<Integer, Targeting__c> mQliId2InsertTg, Map<String,String> mapQli2Targeting, Map<Id, PackageQliIndexWrapper> mapOldQliIdToPkQliIndex){
        
        if(!mQliId2InsertTg.isEmpty())
        {
            insert mQliId2InsertTg.values();	
            
            for(Integer k : mQliId2InsertTg.keySet())
            {
                listClonedQli[k].Targeting__c = mQliId2InsertTg.get(k).Id;                 
            }
        }
        if(!mapQli2Targeting.isEmpty())
        {
            Map<Integer,String> mapResult = GW_Targeting.copyProdPackageTargetingToLine(mapQli2Targeting); // 05.06.2021 / Sophal Noch / US-0009753 use exising cloning targeting__c method
            // Map<Integer,String> mapResult = cloneTargetingAndItsAssociations(mapQli2Targeting,true); // 05.06.2021 / Sophal Noch / US-0009753 another cloning targeting__c method, not used for now.
            for(Integer i : mapResult.keySet())
            {
                listClonedQli[i].Targeting__c = mapResult.get(i);
            }
        }
        insert listClonedQli;

        if(!mapOldQliIdToPkQliIndex.isEmpty()){

            List<QuoteLineItem> listQliToUpdateMainPkId = new List<QuoteLineItem>();

            for(PackageQliIndexWrapper qliPkIndexWr : mapOldQliIdToPkQliIndex.values()){

                if(!qliPkIndexWr.childPkQliIndexs.isEmpty()){

                    Id mainPkQliId = listClonedQli[qliPkIndexWr.mainPkQliIndex].Id;
                    for(Integer childPkIndex : qliPkIndexWr.childPkQliIndexs){
                        listClonedQli[childPkIndex].package_line_item__c = mainPkQliId;
                        QuoteLineItem qliToUpdate = new QuoteLineItem(Id = listClonedQli[childPkIndex].Id, package_line_item__c = mainPkQliId);
                        listQliToUpdateMainPkId.add(qliToUpdate);
                    }
                }
                
            }

            if(!listQliToUpdateMainPkId.isEmpty()){
                update listQliToUpdateMainPkId;
            }

        }

        return listClonedQli;
    }

    private static void resetQuote(Quote quote) {

        quote.status = 'Draft';
        quote.Dually_Signed__c = false;
        quote.Buyer_Accepted__c = false;
        quote.Invoice_Authorization__c = false; // 11.09.2023 / Sophal Noch / US-0014020
        quote.Primary_Quote__c = false;
        quote.Is_Revised_Quote__c = false;
        quote.hasbeenprimary__c = false;
        quote.legacy_sfdc_id__c = null;
        quote.IO__c = null;


    }
    private static void resetQli(QuoteLineItem clonedQli) {
        clonedQli.AdProduct__c = null;
        clonedQli.Targeting__c = null;
        clonedQli.package_line_item__c = null;
        clonedQli.ClonedFrom__c = null;
        clonedQli.Legacy_SFDC_ID__c = null; // Sophal: 03/08/2021: US-0010053
    }

    private static String getSoqlFields(Map<String, Schema.SObjectField> mapFields){

        String fields = '';
        for(String fieldApiName : mapFields.keySet()){
            fieldApiName = fieldApiName.toLowerCase();
            Schema.SObjectField field = mapFields.get(fieldApiName);
            Schema.DescribeFieldResult fieldDetail = field.getDescribe();
            if(!(fieldDetail.isCalculated() || fieldDetail.isAutoNumber())){
                fields += fieldApiName + ',';
            }
        }
        fields = fields != '' ? fields.removeEnd(',') : fields;
        return fields;
        
    }

    class ColName{

    	@AuraEnabled
    	public String label;
    	
    	@AuraEnabled
    	public String fieldName;
      
        @AuraEnabled
    	public String type;
    	
    	@AuraEnabled
    	public Map<String,Object> typeAttributes;
    	
    	public ColName(String label,String fieldName,String type)
    	{
    		this.label = label;
    		this.fieldName = fieldName;
    		this.type = type.toLowerCase();
    		if(mapLinkField.containsKey(fieldName))
    		{
    			typeAttributes = new Map<String,Object>{
    				'label' => new Map<String,Object>{'fieldName'=>mapLinkField.get(fieldName)},
    				'target'=>'_blank',
    				'tooltip'=>''
    			};

    			this.fieldName = 'link_'+mapLinkField.get(fieldName);
    			this.type = 'url';

    		}else if(this.type.equalsIgnoreCase('datetime')){
                this.type = 'date';
                typeAttributes = new Map<String,Object>{
                    'label' => new Map<String,Object>{'fieldName'=>fieldName},
                    'day' => 'numeric',
                    'month'=> 'short',
                    'year'=> 'numeric',
                    'hour'=> '2-digit',
                    'minute'=> '2-digit',
                    'second'=> '2-digit',
                    'hour12'=> false
                };
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