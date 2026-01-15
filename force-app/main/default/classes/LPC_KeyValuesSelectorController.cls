/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 *  - Key Value on Targeting
 * @references:
 *  - LPC_KeyValueSelector lightning component
 * @changeLog:
 *
 */
/*********************************************************************************************************************************
@ Class:          LPC_KeyValuesSelectorController
@ Version:        1.0
@ Author:         
@ Purpose:         
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 02.02.2021 /Vadhanak Voun/ Continue from legacy class
@                                          / US-0008913 - [NA Ads] Cleanup of Dart_KeyValue_2 object in Hive
@				: 24.02.2021/Vadhanak Voun/US-0009123 - [Ads 2020] Optimize the Targetings Screen - KeyValues section
@				: 27.04.2021/Mony Nou/US-0009422 - Filtering the avaialble KeyValue from field Display_Name__c as well 
@													because Na & EU using different fields to store GAM values. 
@													NA using Name field and EU using Display_Name__c field
@				: 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
*********************************************************************************************************************************/
public without sharing class LPC_KeyValuesSelectorController {
    // public final static String DEFAULT_CONJUN_OUT_SET = ' - OR - ';
    // public final static String DEFAULT_CONJUN_IN_SET = ' AND ';
    // public final static String DEFAULT_CONJUN_IN_VALUE = ' OR ';

	private final static String BIG_OR =' - OR - ';
	private final static String BIG_AND  = ' - AND - ';

	static final String KV_TYPE_AS = DART6_KeyValueController.KV_TYPE_AudienceSegment;
    /**
     * Get Key list available on product
     * @param lineItemId, QuoteLineItem Id
     * @return List<GAM_Key_Value__c>
	 * ----------------------------------------------------------------------------------------------------------------------------------
     * Change history: 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
     */
	@AuraEnabled
    public static RemoteResponse initKeyN(String lineItemId){
    	Id quoteLineId = lineItemId;
    	if (Schema.QuoteLineItem.SObjectType != quoteLineId.getSobjectType()) {
    		return new RemoteResponse('Only OpportunityLine Item can apply the key values targetting. This record is a basket.', RemoteResponse.STATUSCODE_ERROR);
    	}

    	QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, AdKeywords__c, Product2Id From QuoteLineItem Where Id =: lineItemId];
		String proId = quoteLine.Product2Id;
		String targetId = quoteLine.Targeting__c;
		if (quoteLine.Targeting__c == null) {
			Targeting__c tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');
			insert tg;
			targetId = tg.Id;
			quoteLine.Targeting__c =  tg.Id;
			update quoteLine;
		}

		try {
			//Available keys on product
			KeyWrp[] keyList = new List<KeyWrp>();
		 	List<Product2> lstPrd2  =[Select Advertising_Medium__r.AdServer_Keywords_Key_Values__c, site__c,site__r.Name,Available_Key_Values__c From Product2 where Available_Key_Values__c<> null and Id =: proId];
			if(lstPrd2.isEmpty()){
				return new RemoteResponse('No Available key value assign for this product - ' + proId, RemoteResponse.STATUSCODE_ERROR);
			}
			Product2 curProduct = lstPrd2.get(0);	
			String site = curProduct.site__r.Name;

			if((curProduct.Available_Key_Values__c+'').containsIgnoreCase(KV_TYPE_AS)) {

				//String soql_AS = 'Select '+String.join(DART6_KeyValueController.listAS_Fields,',') +' From GAM_Audience_Segment__c WHERE Site__r.Name =:site AND Active__c =TRUE' ;
				

				// for(GAM_Key_Value__c key : [Select Key_Value__c,Id,Key_Value_Name__c, Key_ValueType_FreeForm__c, Site__c From GAM_Key_Value__c where DFPEXTID__c = :DART6_KeyValueController.KV_TYPE_AudienceSegment and Active__c = true] ){
			 	// 	KeyWrp keyOne = new KeyWrp(key.Id, key.Key_Value__c, key.Key_Value_Name__c, key.Key_ValueType_FreeForm__c, key.Site__c);
			 	// 	keyList.add(keyOne);
				 // }
				
				//  for(GAM_Audience_Segment__c aseg : Database.query(soql_AS))
				//  {
				// 	//KeyWrp keyOne = new KeyWrp(aseg.Id, aseg.Name, aseg.Name, false, aseg.Site__r.Name);
				// 	//keyList.add(keyOne);
				//  }
				KeyWrp keyOne = new KeyWrp(KV_TYPE_AS, KV_TYPE_AS, KV_TYPE_AS, false, site);
				keyList.add(keyOne);
			}
			
			
			List<String> lstAvailableKey = (curProduct.Available_Key_Values__c+'').split(';');
			// for(GAM_Key_Value__c key : [Select Key_Value__c,Id,Key_Value_Name__c, Key_ValueType_FreeForm__c, Site__c, DFPEXTID__c From GAM_Key_Value__c where Site__c =: curProduct.Site__c and Active__c = true And Node_ID__c = null And Name IN: lstAvailableKey And Key__c <> null order by Name] ){
		 	// 	if(DART6_KeyValueController.KV_TYPE_AudienceSegment.equalsIgnoreCase(key.DFPEXTID__c)) continue;
		 	// 	KeyWrp keyOne = new KeyWrp(key.Id, key.Key_Value__c, key.Key_Value_Name__c, key.Key_ValueType_FreeForm__c, key.Site__c);
		 	// 	keyList.add(keyOne);
			 // }
			Id rec_kv_key = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Key').Id;
			String soql_Main = 'Select '+String.join(DART6_KeyValueController.listKV_Fields,',') + ' From GAM_Key_Value__c WHERE Site__r.Name =:site AND Active__c =TRUE AND (NAME=:lstAvailableKey OR  Disaplay_Name__c=:lstAvailableKey) AND RecordtypeId =:rec_kv_key Order by Disaplay_Name__c' ; //MN-27042021-US-0009422
			for(GAM_Key_Value__c key : Database.query(soql_Main))
			{
				KeyWrp keyOne = new KeyWrp(key.Id, key.Name, key.Disaplay_Name__c, (key.Type__c==DART6_KeyValueController.KEY_TYPE_FREEFORM), key.Site__r.Name);
				keyList.add(keyOne);
			}

		 	//Existing keyvalues on QuoteLineItem
		 	List<KeyValueSetWrp> keyValueSetWrpList = initExistingKeyValueSetList(targetId);


		 	RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
            	'keyList' => keyList,
            	'keyValueSetWrpList' => keyValueSetWrpList,
            	//'predefinedKeyValue' => quoteLine.AdKeywords__c
				'predefinedKeyValue' => curProduct.Advertising_Medium__r.AdServer_Keywords_Key_Values__c //NK:24/02/2021:US-0009123
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Get Value list available on key
     * @param nodeId, GAM_Key_Value__c Id
     * @return List<GAM_Key_Value__c>
	 * ----------------------------------------------------------------------------------------------------------------------------------
     * Change history: 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
     */
	@AuraEnabled
	public static RemoteResponse initValueN(String nodeId, String valueSearch, String quoteLineId) {
	    String valueSearchQuery = '%' + String.escapeSingleQuotes(valueSearch) + '%';
		ValueWrp[] valueList = new List<ValueWrp>();
		try {
			GAM_Key_Value__c[] values = new List<GAM_Key_Value__c>();
			Boolean isAudSeg = false;
			// for(GAM_Key_Value__c k : [select id from GAM_Key_Value__c where id=:nodeId and DFPEXTID__c = :DART6_KeyValueController.KV_TYPE_AudienceSegment]) {
			// 	isAudSeg = true;
			// 	for(QuoteLineItem item : [select Product2.Site__r.Name from QuoteLineItem where id=:quoteLineId]) {
			// 		String siteName = item.Product2.Site__r.Name;
			// 		if(String.isNotBlank(siteName)) {
			// 			values = (List<GAM_Key_Value__c>) Database.query('Select '+Util.NS+'Dart6_ValueId__c, '+Util.NS+'Key_Value__c, Id, '+Util.NS+'Key_Value_Name__c, '+Util.NS+'Value_Display_Name__c ' + 
			// 																'From '+Util.NS+'GAM_Key_Value__c where '+Util.NS+'Node_ID__c =\'' + k.id + '\' and '+Util.NS+'Active__c = true and '+Util.NS+'dc_seg_Value_For_'+siteName+'__c = true and ' + 
			// 																							'('+Util.NS+'Key_Value_Name__c like: valueSearchQuery OR '+Util.NS+'Value_Display_Name__c LIKE: valueSearchQuery) limit 500' );
			// 		}
			// 	}
			// }

			QuoteLineItem qitem = [select Product2.Site__r.Name from QuoteLineItem where id=:quoteLineId];
			String siteName = qitem.Product2.Site__r.Name;

			String soqlVal = 'Select '+String.join(DART6_KeyValueController.listKV_Fields,',')  + ' From GAM_Key_Value__c WHERE Parent__c=:nodeId AND Active__c = true AND Site__r.Name =:siteName AND RecordTypeId =:rectype_val AND (NAME LIKE :valueSearchQuery OR Disaplay_Name__c LIKE :valueSearchQuery) Order by Disaplay_Name__c LIMIT 500' ; 
			Id rectype_val = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Value').Id;
			
			//add AS if it is
			if(nodeId != KV_TYPE_AS) // 13.06.2025 /Sophal Noch/ US-0012504 : change == to != after remove GAM_Audience_Segment__c query section
			{
				//values = [Select Dart6_ValueId__c, Key_Value__c,Id,Key_Value_Name__c, Value_Display_Name__c From GAM_Key_Value__c where Node_ID__c =: nodeId and Active__c = true And (Key_Value_Name__c like: valueSearchQuery OR Value_Display_Name__c LIKE: valueSearchQuery) And Key_Value__c <> Null limit 500];				
				for(GAM_Key_Value__c val : Database.query(soqlVal) )
				{
					ValueWrp valueOne = new ValueWrp(val.Id, val.Name, val.Disaplay_Name__c, val.Disaplay_Name__c );
					valueList.add(valueOne);
				}
				
			}			
		 
			// for(GAM_Key_Value__c val : values){
		 	// 	ValueWrp valueOne = new ValueWrp(val.Id, val.Key_Value_Name__c, val.Key_Value_Name__c, val.Value_Display_Name__c );
			// 	valueList.add(valueOne);
			 // }
			 
		 	RemoteResponse response = new RemoteResponse();
            response.content = valueList;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.message = valueSearch;

            return response;
		} catch(Exception e) {
            system.debug(e); return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

	}

	/**
     * Get Key Value template list on Targeting__c
     * @param targetId, Targeting__c Id
     * @return List<KeyValueSetWrp>
     */
	@AuraEnabled
    public static RemoteResponse loadKeyValueTemplate(String itemId, String targetId){
    	try {
		 	List<KeyValueSetWrp> keyValueSetWrpList = initExistingKeyValueSetList(targetId);


		 	RemoteResponse response = new RemoteResponse();
            response.content = new Map<String, Object>{
            	'keyValueSetWrpList' => keyValueSetWrpList
            };
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            system.debug(e);return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
    }

	    /*********************************************************************************************************************************
		@ Method:               initMapsKvAsso  
		@ Migrated From:        Advertising Instance (Legacy Code)
		@ Purpose:              prepare TargetingKeyValueAssociation__c map
		----------------------------------------------------------------------------------------------------------------------------------
		@ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
		*********************************************************************************************************************************/
	static void initMapsKvAsso(String targetId, Map<String, TargetingKeyValueAssociation__c> mKeyAss, Map<String, TargetingKeyValueAssociation__c> mValAss) {
		RecordType rec_kv_key = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Key');
		//RecordType rec_kv_val = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Value');
		for(TargetingKeyValueAssociation__c ass : [ Select
														TargetKeyValue__c, KeysetOrder__c,Operator__c,Operator_Set__c,Key_Order__c,Value_Order__c,
														// DART_KeyValue__c, Operator__c, 
														// DART_KeyValue__r.Key_Value__c, 
														// DART_KeyValue__r.Node_ID__c, 
														// DART_KeyValue__r.Dart6_ValueId__c,
														// DART_KeyValue__r.Key_Value_Name__c,
														// DART_KeyValue__r.Key_ValueType_FreeForm__c,
														// DART_KeyValue__r.Site__c,
														// DART_KeyValue__r.Value_Display_Name__c
														GAM_Key_Value__c, GAM_Key_Value__r.Name, GAM_Key_Value__r.GAM_ID__c,
														GAM_Key_Value__r.Type__c,GAM_Key_Value__r.Parent__c,GAM_Key_Value__r.Site__c,GAM_Key_Value__r.Site__r.Name,
														GAM_Key_Value__r.Disaplay_Name__c,GAM_Key_Value__r.Match_Type__c,GAM_Key_Value__r.RecordTypeId
													From TargetingKeyValueAssociation__c Where Targeting__c = :targetId]) {

			//system.debug('>>>ass: '+ass);
			if(ass.GAM_Key_Value__c <> null)
			{
				//if(String.isBlank(ass.DART_KeyValue__r.Node_ID__c)) {
				if(rec_kv_key.Id+'' == ass.GAM_Key_Value__r.RecordTypeId+'') {
					// mKeyAss.put(ass.DART_KeyValue__r.Key_Value__c, ass);
					// mKeyAss.put(ass.DART_KeyValue__r.Key_Value_Name__c, ass);
					mKeyAss.put(ass.GAM_Key_Value__r.Name, ass);
					mKeyAss.put(ass.GAM_Key_Value__r.Disaplay_Name__c, ass);

				} else{
					// mValAss.put(ass.DART_KeyValue__r.Key_Value__c, ass);
					// mValAss.put(ass.DART_KeyValue__r.Key_Value_Name__c, ass);
					mValAss.put(ass.GAM_Key_Value__r.Name, ass);
					mValAss.put(ass.GAM_Key_Value__r.Disaplay_Name__c, ass);
				}
			}											
			
		}	
    } 
    static KeyValueSetWrp getEmptyKvSet(integer index) {
    	KeyValueSetWrp s = new KeyValueSetWrp();
		s.index = index;
		s.operator1 = 'OR'; //default
		s.valueListSel = new List<ValueWrp>();
		s.keyOneSel = new KeyWrp(null, '', '', false, null);
		s.keyValueN = new list<KeyValueWrp>();
		return s;
    }


    /*********************************************************************************************************************************
    @ Method:               initExistingKeyValueSetList  
    @ Migrated From:        Advertising Instance (Legacy Code)
    @ Purpose:              set key value wrapper
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/
    // Bunhor @18-July-18: Overload method (Use DARTEvaluator.convertToCritSet(KeyValueString__c) ) to support BIGOR that use the same key. 
    // Example: (((kw=eye) OR (kw=renovation)) AND ((model=128) OR (model=125))) - OR - ((kw=painting) AND (model<>128))
    public static List<KeyValueSetWrp> initExistingKeyValueSetList(String targetId) {
    	List<KeyValueSetWrp> returner = new List<KeyValueSetWrp>();
    	String kvString;
    	for(Targeting__c t : [select KeyValueString__c from Targeting__c where id=:targetId]) kvString = t.KeyValueString__c;
    	
    	if(String.isBlank(kvString)) {
    		returner.add(getEmptyKvSet(0));
	    	return returner;
    	}
    	Map<String, TargetingKeyValueAssociation__c> mKeyAss = new Map<String, TargetingKeyValueAssociation__c>();
    	Map<String, TargetingKeyValueAssociation__c> mValAss = new Map<String, TargetingKeyValueAssociation__c>();
		initMapsKvAsso(targetId, mKeyAss, mValAss);
		//system.debug('>>mKeyAss: '+mKeyAss);
		//system.debug('>>mValAss: '+mValAss);
    	//system.debug('>>kvString: '+kvString);
    	Integer setIndex = 0;
    	for(List<DARTEvaluator.CustomCriteriaSet> listKv : DARTEvaluator.convertToCritSet( kvString )) {
    		KeyValueSetWrp aSet = getEmptyKvSet(setIndex++);
    		returner.add(aSet);
			//system.debug('>>Set');
			Integer keyIndex = 0;
    		for(DARTEvaluator.CustomCriteriaSet kvCcs : listKv) {
				//system.debug('>>kvCcs: '+kvCcs);
    			if(kvCcs.getCriterion() == null || kvCcs.getCriterion().isEmpty()) continue;
    			if(mKeyAss.containskey(kvCcs.getCriterion()[0].getParameter())) {
    				TargetingKeyValueAssociation__c assK = mKeyAss.get(kvCcs.getCriterion()[0].getParameter());
    				if(assK == null) continue;
    				
	    			KeyValueWrp  kvw = new KeyValueWrp();
	    			kvw.index = aSet.keyValueN.size();
					aSet.keyValueN.add(kvw);
					if(assK.GAM_Key_Value__c <> null)
					{
						kvw.keyone = new KeyWrp(assK.GAM_Key_Value__c, assK.GAM_Key_Value__r.Name, assK.GAM_Key_Value__r.Disaplay_Name__c, assK.GAM_Key_Value__r.Type__c==DART6_KeyValueController.KEY_TYPE_FREEFORM, assK.GAM_Key_Value__r.Site__r.Name);
					}
					
	    			//kvw.operator_is = kvCcs.getCriterion()[0].getOperator();
					aSet.operator_is = kvCcs.getOperator();
	    			aSet.operator1 = kvCcs.getOperatorSET();					 

					kvw.operator2 = keyIndex+1 < listKv.size() ? listKv[keyIndex+1].getOperatorKey() : kvCcs.getOperatorKey();	 

	    			ValueWrp[] vals = new List<ValueWrp>();
	    			kvw.valueN = vals;
					Integer valIndex = 0;
					for(DARTEvaluator.Condition con : kvCcs.getCriterion()) {
						if(mValAss.containskey(con.getValue())) {
							TargetingKeyValueAssociation__c assV = mValAss.get(con.getValue());
							//vals.add(new ValueWrp(assV.DART_KeyValue__c, assV.DART_KeyValue__r.Key_Value_Name__c, assV.DART_KeyValue__r.Key_Value_Name__c, assV.DART_KeyValue__r.Value_Display_Name__c));
							//system.debug('>>assK: '+assK +'  >>assV: '+assV);
							ValueWrp v;
							if(assK.GAM_Key_Value__c <> null)
							{
								v = new ValueWrp(assV.GAM_Key_Value__c, assV.GAM_Key_Value__r.Name, assV.GAM_Key_Value__r.Disaplay_Name__c, assV.GAM_Key_Value__r.Disaplay_Name__c);								 
							}
							vals.add(v);
							v.index = valIndex;
							kvw.operator3 = con.getOperatorVal();
						}
						valIndex++;
					}
    			}
				keyIndex++;
    		}
			setIndex++;
    	}
    	return returner;
    }
	
    public static String getKeyValuesSetSummary(String targetingId){
    	return buildKeyValueString( initExistingKeyValueSetList(targetingId) );
    }

	/**
     * Build KeyValue String from defined list
     * @param keyValueSetLst, KeyValueSetWrp List
     * @return String
     */
	private static String buildKeyValueString(List<KeyValueSetWrp> keyValueSetLst) {
		String keyValueSetString = '';
		Integer indexSet = 0;
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			String keyValueString = '';
			if (kvSetWrp.keyValueN == null) continue;
			Integer nextIndexSet = (indexSet+1 >=keyValueSetLst.size()?indexSet:indexSet+1);
			KeyValueSetWrp nextSet = keyValueSetLst[nextIndexSet];
			Integer indexKey = 0;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				if(kvWrp.valueN==null)continue;
				String valuesString = '';
				Integer indexVal = 0;
				for (ValueWrp vWrp : kvWrp.valueN) {
					valuesString += '(' + kvWrp.keyone.keyName + getOperatorSign(kvSetWrp.operator_is) + vWrp.valueName + ')' + (indexVal<(kvWrp.valueN.size()-1)?' '+kvWrp.operator3+' ':'');//DEFAULT_CONJUN_IN_VALUE;
					indexVal++;
				}
				if (kvWrp.valueN.size() > 0 ) {
					//valuesString = valuesString.removeEnd(DEFAULT_CONJUN_IN_VALUE);
					if (kvWrp.valueN.size() > 1) {
						valuesString = '(' + valuesString + ')';
					}
				}
				keyValueString += valuesString + (indexKey<(kvSetWrp.keyValueN.size()-1)?' '+kvWrp.operator2+' ':'');//DEFAULT_CONJUN_IN_SET;
				indexKey++;
			}
			if (kvSetWrp.keyValueN.size() > 0 ) {
				//keyValueString = keyvalueString.removeEnd(DEFAULT_CONJUN_IN_SET);
				if (kvSetWrp.keyValueN.size() > 1) {
					keyValueString = '(' + keyValueString + ')';
				}
				keyValueSetString += keyValueString + ((indexSet <= keyValueSetLst.size()-1)?' - '+kvSetWrp.operator1+' - ':'');//DEFAULT_CONJUN_OUT_SET;				
			}
			indexSet++;
		}

		//check if the next Set is empty, then no operator Set added!
		if(String.isNotBlank(keyValueSetString) && (keyValueSetString.endsWith(BIG_OR) || keyValueSetString.endsWith(BIG_AND) ))
		{			 
			keyValueSetString = keyValueSetString.removeEnd(BIG_OR).removeEnd(BIG_AND);
		}
		
		

		// if (keyValueSetLst.size() > 0 ) {
		// 	keyValueSetString = keyValueSetString.removeEnd(DEFAULT_CONJUN_OUT_SET);
		// }
		return keyValueSetString;
	}
	/*****************************************************************************************************************************
	@ Method:   apexBuildKeyValueString
	@ Version:  1.0
	@ Author:	Vadhanak Voun(vadhanak.voun@gaea-sys.com)          
	@ Purpose:  US-0009123 - [Ads 2020] Optimize the Targetings Screen - KeyValues section
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 26/02/2021 / Vadhanak Voun  / centralize the method from js and apex
	*****************************************************************************************************************************/
	@AuraEnabled
	public static RemoteResponse apexBuildKeyValueString(String keyValueSetLstJSON)
	{
		try {
			System.debug('>>keyValueSetLstJSON: '+keyValueSetLstJSON);
			
			List<KeyValueSetWrp> keyValueSetLst = (List<KeyValueSetWrp>) JSON.deserialize(keyValueSetLstJSON, List<KeyValueSetWrp>.class);			
			String kvString = buildKeyValueString(keyValueSetLst);
			Map<String,Object> mapResult = new Map<String,Object>();
			mapResult.put('kvString',kvString);
			//mapResult.put('keyValueSetLst',keyValueSetLst); 
			RemoteResponse response = new RemoteResponse();
            response.content = mapResult;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            System.debug(e);return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }

	}

	/**
     * Get Operator Sign
     * @param operator, Operator String
     * @return String
     */
	private static String getOperatorSign(String operator) {
		return ('is'.equalsIgnoreCase(operator) || operator == '=') ? '=' : '<>';
	}

	/**
     * Save KeyValue Data
     * @param lineItemId, QuoteLineItem Id
     * @param keyValueSetList, Json List
     * @return String
     */
	@AuraEnabled
	public static RemoteResponse saveKeyValue(String lineItemId, String keyValueSetList,String finalKVString) {
		//system.debug('>>keyValueSetList: '+keyValueSetList);
		//system.debug('>>finalKVString: '+finalKVString);
		try {
			QuoteLineItem quoteLine = [Select Product2Id,AdKeyWords__c, Product2.Name, Targeting__c, Quote.IO__c  From QuoteLineItem Where Id =: lineItemId];
			String targetingId = quoteLine.Targeting__c;
			Targeting__c tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');	 
			if (targetingId == null) 
			{			
				insert tg;		
				targetingId = tg.Id;	
				
				quoteLine.Targeting__c =  targetingId;
				 
			}else {
				tg.Id = targetingId;
			}
			
			List<KeyValueSetWrp> keyValueSetLst = saveKeyValueTargeting(targetingId, keyValueSetList);
			String kvString = buildKeyValueString(keyValueSetLst);	
			
			tg.KeyValueString__c=kvString;							
			update tg;		 

			quoteLine.AdKeyWords__c = quoteLine.AdKeyWords__c <> finalKVString ? finalKVString : quoteLine.AdKeyWords__c ;//kvString + (String.isBlank(finalKVString)?'': BIG_AND + finalKVString ); //NK:03/03/2021:US-0009123: save final key value
			update quoteLine;

			RemoteResponse response = new RemoteResponse();
            response.content = keyValueSetLst;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            System.debug(e);return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Save KeyValue Template
     * @param targetId, Targeting__c Id
     * @param keyValueSetList, Json List
     * @return List<KeyValueSetWrp>
     */
	@AuraEnabled
	public static RemoteResponse saveKeyValueTemplate(String targetId, String keyValueSetList) {
		try {
			List<KeyValueSetWrp> keyValueSetLst = saveKeyValueTargeting(targetId, keyValueSetList);
			update new Targeting__c(Id = targetId, KeyValueString__c = buildKeyValueString(keyValueSetLst));

			RemoteResponse response = new RemoteResponse();
            response.content = keyValueSetLst;
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
		} catch(Exception e) {
            return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR);
        }
	}

	/**
     * Save KeyValue Targeting
     * @param targetId, Targeting__c Id
     * @param keyValueSetList, Json List
     * @return List<KeyValueSetWrp>
	 * ----------------------------------------------------------------------------------------------------------------------------------
     * @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
     */
	public static List<KeyValueSetWrp> saveKeyValueTargeting(String targetId, String keyValueSetList){
		//System.debug('>>keyValueSetList: '+keyValueSetList);
		List<KeyValueSetWrp> keyValueSetLst = (List<KeyValueSetWrp>) JSON.deserialize(keyValueSetList, List<KeyValueSetWrp>.class);		
		Map<String, TargetingKeyValueAssociation__c> mapTarKeyValueAss = new Map<String, TargetingKeyValueAssociation__c>();
		Set<String> toKeepAss = new Set<String>();		
		//Map<String, String> mapOperator = new Map<String, String>();
		Map<String,GAM_Key_Value__c> mapkvTobeCreated = new Map<String,GAM_Key_Value__c>(); //value free-form
		String rec_kv_val = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Value').Id;		

		Integer keysetOrder = 0;
		//create new free-form value
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			if (kvSetWrp.keyValueN == null) continue;
			Integer keyOrder = 0;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				Integer valOrder = 0;
				for (ValueWrp vWrp : kvWrp.valueN) {
					if(vWrp.valueId == ''){
						//GAM_Key_Value__c kv = new GAM_Key_Value__c(Active__c = true, Name = vWrp.valueLabel, Key_Value_Name__c = vWrp.valueLabel, Key_Value__c = DART6_KeyValueController.fetchInvalidChars(vWrp.valueLabel), Node_ID__c = kvWrp.keyone.keyId, Site__c = kvWrp.keyone.siteId);
						AdServer_Login__c siteServer = DARTUtil.getCredential(DARTUtil.DART6,kvWrp.keyone.siteId);
						String pureName = DART6_KeyValueController.fetchInvalidChars(vWrp.valueLabel);
						GAM_Key_Value__c kv = new GAM_Key_Value__c(RecordTypeId=rec_kv_val,Active__c = true, Disaplay_Name__c = vWrp.valueLabel, Name = pureName, Parent__c = kvWrp.keyone.keyId, Site__c = siteServer.Id,Match_Type__c = DART6_KeyValueController.findMatchType(pureName));
						mapkvTobeCreated.put(keysetOrder+'_'+keyOrder+'_'+valOrder,kv);
						//mapOperator.put(kvWrp.keyone.keyId+'_'+vWrp.valueLabel, kvSetWrp.operator_is);
						 
					}
					valOrder++;
				}
				keyOrder++;
			}
			keysetOrder++;
		}
		if(!mapkvTobeCreated.isEmpty()) insert mapkvTobeCreated.values();
		//create association for new value
		// for(GAM_Key_Value__c kv : lstkvTobeCreated){
		// 	String valAssField = targetId + kv.Id;
		// 	toKeepAss.add(valAssField);
		// 	mapTarKeyValueAss.put(valAssField, new TargetingKeyValueAssociation__c(Targeting__c = targetId ,GAM_Key_Value__c = kv.Id , Operator__c = mapOperator.get(kv.Parent__c+'_'+kv.Name), targetkeyvalue__c = valAssField));
		// }

		Set<String> setKeyVal = new Set<String>();
		keysetOrder = 0;
		for (KeyValueSetWrp kvSetWrp : keyValueSetLst) {
			if (kvSetWrp.keyValueN == null) continue;
			Integer keyOrder = 0;
			for (KeyValueWrp kvWrp : kvSetWrp.keyValueN) {
				String keyAssField = targetId + kvWrp.keyone.keyId + kvSetWrp.operator_is;
				if(!setKeyVal.contains(keyAssField) && kvWrp.keyone.keyId <> KV_TYPE_AS){ //no AS as key anymore after cleanup
					setKeyVal.add(keyAssField);
					toKeepAss.add(keyAssField);
					//System.debug('>>kvWrp.keyone.keyId: '+kvWrp.keyone.keyId);
					//New Key Association
					mapTarKeyValueAss.put(keyAssField,
						new TargetingKeyValueAssociation__c (
							Targeting__c = targetId,
							GAM_Key_Value__c = kvWrp.keyone.keyId,
							Operator__c = kvSetWrp.operator1,	//set-set
							Operator_Set__c = kvSetWrp.operator_is, // is, is not
							TargetKeyValue__c = keyAssField,
							KeysetOrder__c =  keysetOrder,
							Key_Order__c = keyOrder
					));
				}
				//New Value Association
				Integer valOrder = 0;
				for (ValueWrp vWrp : kvWrp.valueN) {
					if(String.isBlank(vWrp.valueId) )
					{
						vWrp.valueId = mapkvTobeCreated.get(keysetOrder+'_'+keyOrder+'_'+valOrder).Id; //get id of new Value
					}
					String valAssField = targetId + vWrp.valueId + kvSetWrp.operator_is;
					toKeepAss.add(valAssField);
					TargetingKeyValueAssociation__c tkva = new TargetingKeyValueAssociation__c(KeysetOrder__c=keysetOrder,Key_Order__c=keyOrder,Value_Order__c=valOrder,Targeting__c = targetId , Operator__c = kvSetWrp.operator_is, targetkeyvalue__c = valAssField);
					//System.debug('>>vWrp: '+vWrp);
					tkva.GAM_Key_Value__c = vWrp.valueId;					
					mapTarKeyValueAss.put(valAssField, tkva);
					valOrder++;
					 
				}
				keyOrder++;
			}
			keysetOrder++;
		}
		//System.debug('>>mapTarKeyValueAss: '+mapTarKeyValueAss);

		upsert mapTarKeyValueAss.values() targetkeyvalue__c;

		delete [Select Id From TargetingKeyValueAssociation__c Where Targeting__c= :targetId And targetkeyvalue__c Not In :toKeepAss ];
		 
		

		return keyValueSetLst;
	}

	/**
     * KeyValueSet Wrapper Class
     */
    public class KeyValueSetWrp {
    	//DEFAULT_CONJUN_IN_SET
    	@AuraEnabled
    	public Integer index; //keySetOrder

		@AuraEnabled
    	public String operator_is = '='; //default IS (IS, ISNOT)

		@AuraEnabled
    	public String operator1 = 'OR'; //default  1: Set-Set

    	//List checked Values of a selected key
    	@AuraEnabled
    	public ValueWrp[] valueListSel;
    	//Selected Key
    	@AuraEnabled
    	public KeyWrp keyOneSel;
    	@AuraEnabled
    	public KeyValueWrp[] keyValueN;
    }

    /**
     * KeyValue Wrapper Class
     */
    public class KeyValueWrp {
    	@AuraEnabled
    	public Integer index; //keyOrder
    	@AuraEnabled
    	public KeyWrp keyone;		

		@AuraEnabled
    	public String operator2 = 'AND'; //default 2: Key-Key

		@AuraEnabled
    	public String operator3 = 'OR'; //default 3: Key-Value(s)


    	//DEFAULT_CONJUN_IN_VALUE
    	@AuraEnabled
    	public ValueWrp[] valueN;

    }

	/*********************************************************************************************************************************
    @ Method:               ValueWrp  
    @ Migrated From:        Advertising Instance (Legacy Code)
    @ Purpose:              wrapper class for GAM_Key_Value__c Value
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/
    /**
     * Value Wrapper Class
     */
    public class ValueWrp {
    	@AuraEnabled
    	public Integer index; //valueOrder
    	@AuraEnabled
    	public String valueId;
    	@AuraEnabled
    	public String valueName; 
    	@AuraEnabled
    	public String valueLabel;
    	@AuraEnabled
        public String valueDisplayLabel;
    	@AuraEnabled
    	public Boolean isChecked = false;
    	@AuraEnabled
    	public Boolean isVisible = true;

		@AuraEnabled
		public Boolean isAS = false; //Audience Segment ?

    	public ValueWrp(String idSobj, String name, String label) {
    		valueId = idSobj;
    		valueName = name;
    		valueLabel = label;
    	}
    	
    	public ValueWrp(String idSobj, String name, String label, String DisplayLabel) {
            valueId = idSobj;
            valueName = name;
            valueLabel = label;
            valueDisplayLabel = String.isBlank(DisplayLabel) ? label : DisplayLabel + ' ( ' + label + ' )';
		}
    }

    /**
     * Key Wrapper Class
     */
    public class KeyWrp {
    	@AuraEnabled
    	public String keyId;
    	@AuraEnabled
    	public String keyName;
    	@AuraEnabled
    	public String keyLabel;
    	@AuraEnabled
    	public boolean isFreeForm;
    	@AuraEnabled
    	public String siteId;

		// @AuraEnabled
    	// public String operator3 = 'OR'; //default 3: Key-Value(s)

    	public KeyWrp(String idSobj, String name, String label) {
    		keyName = name;
    		keyLabel = label;
    		keyId = idSobj;
    	}

    	public KeyWrp(String idSobj, String name, String label, boolean isFf, String sid) {
    		keyName = name;
    		keyLabel = label;
    		keyId = idSobj;
    		isFreeForm = isFf;
    		siteId = sid;
    	}
    }
}