/**
 Manage Key id and value Id by the keyvalue association.
 - Seach the value in dfp if exist then return with id
 - Create new free-form value in dfp if not exist
 - Save the newly created value id(s) to GAM_Key_Value__c
 
 NK: 31/1/2013
    DFP format:
     (
        (key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)
        )
        OR <---- SET,first level. must be 'OR'
        (
        (key1=val1) AND (key2=val1) AND (key3=val1 OR val2)
    )----------------^ --------------^  Second level. Must be AND
        
    ((key1=val1 OR val2) AND (key2=val1 OR val2 OR val3)) OR ((key1=val1) AND (key2=val1) AND (key3=val1 OR val2))
    
    -log: 
     + 08/03/2017:NK: handle prefix/suffix  
    
*/ 
/*********************************************************************************************************************************
@ Class:          DART6_KeyValueController
@ Version:        1.0
@ Author:         
@ Purpose:         
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 01.02.2021 /Vadhanak Voun/ Continue from legacy class
@                                          / US-0008913 - [NA Ads] Cleanup of Dart_KeyValue_2 object in Hive
@               : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
*********************************************************************************************************************************/

public without sharing class DART6_KeyValueController extends DARTObject.AbstractDARTController{  
    //free-form values to be created (predefined-key id provied)
    String token,networkId;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapTobeCreatedValues;
    Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue> mapAllKeyValues;
    
    //predefined fields fo SOQL
    public final static List<String> listKV_Fields = new List<String>{
        'Id','Name','Active__c','GAM_ID__c','Unique_Id__c','Type__c','Site__c','Site__r.Name','Disaplay_Name__c','Match_Type__c'
    };
    public final static List<String> listAS_Fields = new List<String>{
        'Id','Name','Full_Name__c','Site__c','Site__r.Name','GAM_Id__c','Active__c'
    };

    public final static String KEY_TYPE_FREEFORM = 'FREEFORM';
    final String KEY_TYPE_PREDEFINED = 'PREDEFINED';

    String countryName;
    
    List<List<DARTEvaluator.CustomCriteriaSet>> listEvalCrit;
    
    //store the object that does not have dart6 valueId; so after created freeform value in dfp, save the dartid back to this object for future use
    Map<String,GAM_Key_Value__c> mapValueObject2BeUpdated = new Map<String,GAM_Key_Value__c>();
    Map<String,GAM_Key_Value__c> mapValueObject2BeCreated = new Map<String,GAM_Key_Value__c>();
    
    Map<String,String> mapDfpId_Key = new Map<String,String>();//dfpkeyId to keyname
    Set<String> setV = new Set<String>(); //all value names
    
    set<String> setAllValueNotFreeform = new set<String>();
    
    //NK:21/03/2013
    public static final String KV_TYPE_AudienceSegment = 'Audience Segment'; //Audience Segment
    
    private DART6_KeyValueController(String token,String networkId)
    {
        this.token = token;
        this.networkId = networkId;
        
        mapTobeCreatedValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
        mapAllKeyValues = new Map<String,DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue>();
    }
    
    /** Constructor:
    @param: targetingId : DartKeyValue2 will be selected from targeting association via this id
    @param: countryName    : to make this search deliver only one result we need another identifier (KeyValue only in this product)
    @param: dart5Form   : old dart keyvalue form to be converted to dart6
    @param: token       : google token after login
    @param: networkId   : network id to be processed
    ----------------------------------------------------------------------------------------------------------------------------------                                / US-0008913 - [NA Ads] Cleanup of Dart_KeyValue_2 object in Hive
    @ Change history: 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    */
    public DART6_KeyValueController(String siteId, String dart5Form,String token,String networkId)
    {
        this(token,networkId);
        Site__c site = [Select Id,Name,Country__c from Site__c Where Id=:siteId];
        countryName = site.Name;

        try{
            if(String.isEmpty(dart5Form) || dart5Form == 'null')
            {
              listEvalCrit = new List<List<DARTEvaluator.CustomCriteriaSet>>();
              return;
            }
            listEvalCrit =  DARTEvaluator.convertToCritSet( dart5Form ); 
        }catch(Exception ex){throw new ExceptionGroup.DARTKeyValueException('Unsupported or Invalid Keyvalue String format: '+dart5Form);}
        
         // for pure oldform string without targeting Id
        Set<String> setK = new Set<String>();
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            for (DARTEvaluator.CustomCriteriaSet cs : cslist) 
            {
                for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                setK.add(con.getParameter());
	                setV.add(fetchInvalidChars(con.getValue()));
	            }
            }
            
        }

        Map<String,GAM_Key_Value__c> mapK = new Map<String,GAM_Key_Value__c>(); //for Key only,key: car 
        Map<String,GAM_Key_Value__c> mapV = new Map<String,GAM_Key_Value__c>(); //for Value only,key: car_bmw
        Map<String,GAM_Key_Value__c> mapKeyNotFreeform = new Map<String,GAM_Key_Value__c>();
        Map<String,GAM_Key_Value__c> mapKeyFreeform = new Map<String,GAM_Key_Value__c>();
        // Commented by Acmatac SEING 20/Sep/2022, US-0011994
        // setK.add(KV_TYPE_AudienceSegment);

        // String soql='Select '+Util.NS+'Key__c, '+Util.NS+'Dart6_KeyId__c, '+Util.NS+'Dart6_ValueId__c, '+Util.NS+'Key_ValueType_FreeForm__c, '+Util.NS+'Key_Value__c, '+
        //             	'(Select '+Util.NS+'Key__c, '+Util.NS+'Key_Value_Name__c, '+Util.NS+'Dart6_KeyId__c, '+Util.NS+'Key_Value__c ,'+Util.NS+'Site__c, '+Util.NS+'Dart6_ValueId__c, ' +
        //             		Util.NS+'Node_ID__r.'+Util.NS+'Key_ValueType_FreeForm__c From '+Util.NS+'DART_KeyValues_2__r '+
        //             ' Where '+Util.NS+'Key_Value__c IN:setV) '+
        //             ' From '+Util.NS+'GAM_Key_Value__c Where '+Util.NS+'Key_Value__c IN:setK AND '+Util.NS+'Key_Value__c <>: KV_TYPE_AudienceSegment ';
        String rec_kv_key = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Key').Id;
        String soqlInner = '(Select '+String.join(listKV_Fields,',') +' From Values__r WHERE NAME IN :setV)' ;
        // String soql_AS = 'Select '+String.join(listAS_Fields,',') +' From GAM_Audience_Segment__c WHERE Site__r.Name =:countryName AND Active__c=TRUE AND Full_Name__c IN :setV ' ; // 13.06.2025 /Sophal Noch/ US-0012504 : disable to delete object GAM_Audience_Segment__c
        // Add condition Active__c=TRUE, Acmatac SEING 20/Sep/2022, US-0011994
        String soqlMain = 'Select '+String.join(listKV_Fields,',') +', ' + soqlInner + ' From GAM_Key_Value__c WHERE Site__r.Name =:countryName AND NAME IN :setK And RecordTypeId=:rec_kv_key AND Active__c=TRUE' ;
        //System.debug('>>>>soqlMain: '+soqlMain);
        //System.debug('>>>>countryName: '+countryName);
        //storing Audience Segments

        for(GAM_Key_Value__c kvff : Database.query(soqlMain))
        {
            // //storing Audience Segments
            // if(KV_TYPE_AudienceSegment.equals(kvff.Name))
            // {
            //     if(!kvff.Audience_Segments__r.isEmpty())
            //     {
            //         for(GAM_Audience_Segment__c seg : kvff.Audience_Segments__r)
            //         {
            //             mapAllKeyAudSegs.put(kvff.Name+'_'+seg.Name ,seg);
            //         }
            //     }
            //     continue;
            // }
            
           // Mapping all child of each parent
           for(GAM_Key_Value__c kvChild : kvff.Values__r)
           {
                //simple kv
                String strKeyVal = (kvff.Name+'_'+kvChild.Name);           
                mapV.put(strKeyVal,kvChild);  //k: key_value, value to indentify the which value belong to which key. in case same name value in the different key
                
                if(kvff.Type__c <> KEY_TYPE_FREEFORM){
                    mapKeyNotFreeform.put(kvff.Name, kvff);
                    setAllValueNotFreeform.add(kvChild.Name);
                }
                else{
                    mapKeyFreeform.put(kvff.Name, kvff);
                }               
            }

            mapK.put(kvff.Name,kvff); 
            mapDfpId_Key.put(kvff.GAM_ID__c+'',kvff.Name); //dfpId -> Keyname
        }
        
         //the the sfid and existing dart Id
        // for(GAM_Key_Value__c kv2 : [Select d.Key__c, d.Dart6_KeyId__c, d.Dart6_ValueId__c, d.Key_ValueType_FreeForm__c, d.Key_Value__c,
        //                         (Select Key__c, Key_Value_Name__c, Dart6_KeyId__c, Key_Value__c, Dart6_ValueId__c, Node_ID__r.Key_ValueType_FreeForm__c From DART_KeyValues_2__r
        //                          Where Key_Value__c IN:setV)
        //                          From GAM_Key_Value__c d Where Key_Value__c IN:setK])
        //     //WHERE Node_ID__r.Key__c IN:setK AND Key_Value__c IN: setV
        //     //WHERE Id in (SELECT DARTKeyValue__c From TargetingKeyValueAssociation__c where Targeting__c=:targetingId) //need this?
        // {
        //     //TODO: AudienceSegment ?
        //     //AudiencdSegment => Node_ID__r.Name
        //     //Mapping all child of each parent (AudienceSegment)
        //     for(GAM_Key_Value__c kvChild : kv2.DART_KeyValues_2__r){
        //         //TODO: AudienceSegment ?
        //         //AudiencdSegment => Node_ID__r.Name
        //         String strKeyVal = (kv2.Key__c+'_'+kvChild.Key_Value__c).trim();
        //         if(KV_TYPE_AudienceSegment.equals(kv2.Key_Value__c))
        //         {
        //             mapAllKeyAudSegs.put(strKeyVal ,kvChild);
        //         }
        //         mapV.put(strKeyVal, kvChild);
        //     }  
        // }
        DARTObject.IValidator kvValidator = new KVValidator(mapK,mapV,mapKeyNotFreeform,setAllValueNotFreeform);  // 13.06.2025 /Sophal Noch/ US-0012504 : remove paramter mapAllKeyAudSegs to delete object GAM_Audience_Segment__c
        String rec_kv_val = ApexUtil.getRecordTypeByName('GAM_Key_Value__c','Value').Id;
        
        //find if value has dart6 id yet - then add to list to create in dfp
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            for(DARTEvaluator.CustomCriteriaSet cs: cslist)
            {
	            for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                //for error: may not Possible - just in case
	                kvValidator.checkError(con);
	                String fetchedValue = fetchInvalidChars(con.getValue());
	                if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
	                {
	                    //error(s) occure NO NEED to process next step, because this will be thrown after finishing loop
	                    if(kvValidator.isError())continue;
	                    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue tmp = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue();
	                    tmp.customTargetingKeyId = ApexUtil.toLong(mapK.get(con.getParameter()).GAM_ID__c) ;
	                    tmp.matchType = findMatchType(con.getValue());
	                    tmp.name = fetchedValue;
	                    tmp.displayName = con.getValue();
	                    
	                    String keyToV = con.getParameter() + '_' + fetchedValue;
	                    //no dart6value Id yet, need to create this in dfp
	                    if(mapV.get(keyToV) != null){ 
	                        if(mapV.get(keyToV).GAM_ID__c==null){
	                            setV.add(tmp.name); //for first query
	                            mapTobeCreatedValues.put(tmp.customTargetingKeyId+'_'+tmp.name,tmp); //this will be seding to dfp
	                            
	                            //will save dart6 id back after created in dfp.
	                            //key: GAM_Key_Value__c.Id, value: GAM_Key_Value__c
	                            String key = mapDfpId_Key.get(tmp.customTargetingKeyId+'');
	                            mapValueObject2BeUpdated.put(key+'_'+tmp.name, mapV.get(keyToV)); 
	                            
	                        }
	                        else//dart6value id already existed, no need to create in dfp. so keep it in a map for next step use
	                        {
	                            tmp.id = ApexUtil.toLong(mapV.get(keyToV).GAM_ID__c);
	                            //key = dart6Id_value: 12345665_v11230
	                            mapAllKeyValues.put(mapK.get(con.getParameter()).Name + '_' + fetchedValue,tmp); 
	                        }
	                    }
	                    else  // else create new value in dfp & sf
	                    {
	                        if((mapK.get(con.getParameter())).Type__c == KEY_TYPE_FREEFORM && !mapKeyFreeform.containsKey(fetchedValue))
	                        {
	                            setV.add(tmp.name); //for first query
	                            mapTobeCreatedValues.put(tmp.customTargetingKeyId+'_'+tmp.name,tmp); //this will be seding to dfp
	                            // Create new Value
	                            GAM_Key_Value__c kv2 = new GAM_Key_Value__c(
                                    RecordTypeId = rec_kv_val,
	                                Parent__c = mapK.get(con.getParameter()).Id,
                                    Name = con.getValue(),
                                    Disaplay_Name__c = fetchedValue,
	                               // Key_Value__c = fetchedValue,
	                               // Key_Value_Name__c = con.getValue(),
	                                Active__c = true,
                                    Match_Type__c = findMatchType(con.getValue())
	                            );
                                //system.debug('>>>new: '+kv2);
	                            mapValueObject2BeCreated.put(fetchedValue, kv2);
	                            mapAllKeyValues.put(mapK.get(con.getParameter()).Name + '_' + fetchedValue,tmp); 
	                        }
	                    }   
	                }
	            }
            }
        }
        
        if(kvValidator.isError()){throw new ExceptionGroup.DARTKeyValueException('ERROR: '+kvValidator.getListError());}
    }
    
    public static String fetchInvalidChars(String valueSrc) {
		if(String.isBlank(valueSrc)) return '';
        valueSrc = valueSrc.replaceAll('\\~','').replaceAll('\\*','');
        String originVal = valueSrc;
        String dollarSign = '\\$';
        valueSrc = valueSrc.replaceAll(dollarSign, '').replaceAll(' ', '');
        //Price Key
        if (valueSrc.startsWith('<')) {
            valueSrc = valueSrc.replaceFirst('<', '0-');
        } else if (valueSrc.startsWith('>')) {
            valueSrc = valueSrc.replaceFirst('>','') + '-999999999';
        } else {
            valueSrc = originVal; 
        }
        return valueSrc;
    }
    
    public Boolean isNeedToCreate()
    {
        return !mapTobeCreatedValues.isEmpty();
    }
    /** send values to create free form value at dart6 */
    public void searchCreateDFPFreeFormValues()
    {
        
        DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader header = new DART6_CUSTOMTARGETINGSERVICE.SoapRequestHeader();
          
        header.applicationName='CustomTargetingService';
        header.networkCode= networkId;
        
        Map<String,String> inputHttpHeaders_x = new Map<String, String>();
        inputHttpHeaders_x.put('Authorization', 'Bearer '+ token); 
        
        DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort customTagetingService = new DART6_CUSTOMTARGETINGSERVICE.CustomTargetingServiceInterfacePort();
        customTagetingService.RequestHeader = header;
        customTagetingService.inputHttpHeaders_x = inputHttpHeaders_x;
        
        try
        {
            //1)- search in dfp, if values already exist in dfp then get those Ids
            DART6_CUSTOMTARGETINGSERVICE.Statement filterStatement = new DART6_CUSTOMTARGETINGSERVICE.Statement();
            filterStatement.query = 'WHERE customTargetingKeyId IN'+DARTUtil.generateIds(mapDfpId_Key.keySet())+
                                    ' AND name IN'+DARTUtil.generateIds(setV);
            
            DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValuePage pageResult = customTagetingService.getCustomTargetingValuesByStatement(filterStatement);
            invokedMethod = 'getCustomTargetingValuesByStatement, ';
            if(pageResult.totalResultSetSize>0){
                //in case value already existed in dfp, but no dfp id in sf
                assignDFPIdsToSF(pageResult.results);  
            }

            //2)- create free form value if not yet existed in dfp
            if(!mapTobeCreatedValues.isEmpty())
            {
                DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values = customTagetingService.createCustomTargetingValues(mapTobeCreatedValues.values());
                invokedMethod += 'createCustomTargetingValues';
                //put all new created value into the main map for KeyValueTargeting construction
                assignDFPIdsToSF(values);
            }
            //mapTobeCreatedValues is obsoleted from here
        }
        catch(System.CalloutException cex){
            throw new ExceptionGroup.DARTException(DARTUtil.extractMessage(cex.getMessage()));
        }catch(Exception ex)
        {throw new ExceptionGroup.DARTException('' + ex.getMessage());}
    }
    
    private void assignDFPIdsToSF(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue[] values)
    {
        for(DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue valRes: values)
        {
            //assign the newly created dfp id of free form value to GAM_Key_Value__c for future use
            String key = mapDfpId_Key.get(valRes.customTargetingKeyId+'');
            mapAllKeyValues.put(key+'_'+valRes.name, valRes); 
             
            //if same value found in dfp after query, remove them from the list tobecreated to avoid duplicate
            //when calling createCustomTargetingValues
            mapTobeCreatedValues.remove(valRes.customTargetingKeyId+'_'+valRes.name); 
            
            if(mapValueObject2BeCreated.containsKey(valRes.name)){
                mapValueObject2BeCreated.get(valRes.name).GAM_ID__c = valRes.id+'';
            }
            
            //assign dpf value id to SF if available
            if(!mapValueObject2BeUpdated.containsKey(key+'_'+valRes.name))continue;
            mapValueObject2BeUpdated.get(key+'_'+valRes.name).GAM_ID__c = valRes.id+''; 
        }
    }
    
    //NK:13/01/2015
    final Map<String,String> MAP_OPERATOR =  new Map<String,String>{'='=>'IS','<>'=>'IS_NOT'};
    
    /*********************************************************************************************************************************
    @ Method:               getListDart  
    @ Migrated From:        Advertising Instance (Legacy Code)
    @ Purpose:              prepare KeyValue to Send to GAM
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
    *********************************************************************************************************************************/
    /**@return a list of CustomCriteriaSet */
    public override List<DARTObject.IDARTGenericObject> getListDart()
    { 
        DART6_FORECASTSERVICE.CustomCriteriaSet[] childrenNBig = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet = new DART6_FORECASTSERVICE.CustomCriteriaSet();
        customCriteriaSet.logicalOperator = 'OR';// Big - OR - level is always OR
        customCriteriaSet.type_x = 'CustomCriteriaSet';
        customCriteriaSet.children = childrenNBig;
            
        for(DARTEvaluator.CustomCriteriaSet[] cslist: listEvalCrit)
        {
            DART6_FORECASTSERVICE.CustomCriteriaSet[] childrenNSet1 = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
            DART6_FORECASTSERVICE.CustomCriteriaSet customCriteriaSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
            customCriteriaSet1.logicalOperator = 'AND';// Top level is always AND. dartObjForecast.getKeyWKV();
            customCriteriaSet1.children = childrenNSet1;  //list crit set
            customCriteriaSet1.type_x = 'CustomCriteriaSet';
            
            for (DARTEvaluator.CustomCriteriaSet cs : cslist) {
            
                DART6_FORECASTSERVICE.CustomCriteriaNode[] childrenN = new List<DART6_FORECASTSERVICE.CustomCriteriaNode>();
	            DART6_FORECASTSERVICE.CustomCriteriaSet critSet1 = new DART6_FORECASTSERVICE.CustomCriteriaSet();
	            critSet1.logicalOperator = 'OR';   //Second level is always OR
	            critSet1.type_x = 'CustomCriteriaSet';  //set 1
	            critSet1.children = childrenN; //add to set 1
	            
	            String oper;
	            for(DARTEvaluator.Condition con: cs.getCriterion())
	            {
	                String fetchedValue = fetchInvalidChars(con.getValue());
	                if(!KV_TYPE_AudienceSegment.equals(con.getParameter()))
	                {
	                    DART6_FORECASTSERVICE.CustomCriteria crit1a = new DART6_FORECASTSERVICE.CustomCriteria();
	                    DART6_CUSTOMTARGETINGSERVICE.CustomTargetingValue val = mapAllKeyValues.get(con.getParameter() + '_' + fetchedValue); 
	                    crit1a.keyId = val.customTargetingKeyId; //70630;
	                    crit1a.valueIds = new Long[]{val.Id}; //new Long[]{Long.ValueOf('43594068070'),Long.valueOf('43594069630')};
	                    //NK:13/01/2015
	                    crit1a.operator = MAP_OPERATOR.get(con.getOperator()); //Enumerations: IS, IS_NOT
	                    
	                    oper = crit1a.operator;
	                    crit1a.type_x = 'CustomCriteria';   //crit 1 of set1
	                    childrenN.add(crit1a);
	                }
	            }
	            // Bunhor @31-July-18: Fix ServerError.SERVER_ERROR on example key-values: ((cat=293) AND ((kw<>settee) OR (kw<>tire deal)))
	            if(critSet1.children.size() > 1 && oper == 'IS_NOT' ) critSet1.logicalOperator = 'AND';
	            childrenNSet1.add(critSet1);
            }
            childrenNBig.add(customCriteriaSet1);
        }  
        // Document doc = new Document();
        // doc.FolderId = UserInfo.getUserId();
        // doc.Body = Blob.valueOf(JSON.serialize(customCriteriaSet));
        // doc.ContentType = 'text/plain';
        // doc.Type = 'txt';
        // doc.Name = 'Debug CustomCriteriaSet';
        //insert doc;
        listDartObjects = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>();
        if (!childrenNBig.isEmpty()) {
            listDartObjects  = new List<DART6_FORECASTSERVICE.CustomCriteriaSet>{customCriteriaSet};
        }
        
        return listDartObjects;
    } 
    
    public void createObjectKeyVal()
    {
        insert mapValueObject2BeCreated.values();
    }
    
    public Boolean isCreateNewKv()
    {
        return !mapValueObject2BeCreated.isEmpty();
    }
    
    public void updateDart6ValueIds()
    {
        update mapValueObject2BeUpdated.values();
    }
    
    //mapMT_Head.get(MT_BROAD)
    public static final String MT_BROAD = 'BROAD';     //~myvalue
    public static final String MT_PREFIX = 'PREFIX';    //myvalue*
    public static final String MT_EXACT = 'EXACT';    //myvalue
    public static final String MT_BROAD_PREFIX = 'BROAD_PREFIX';    ////~myvalue*
    
    //NK:09/02/2021:US-0008913. more in new version: SUFFIX, CONTAINS, UNKNOWN (but no doc about symbol)
    public static final String MT_SUFFIX = 'SUFFIX';
    public static final String MT_CONTAINS = 'CONTAINS';
    public static final String MT_UNKNOWN = 'UNKNOWN';
        
    final static Map<String,String> mapMT_Head0 = new Map<String,String>{MT_BROAD=>'~',MT_PREFIX=>'',MT_EXACT=>'',MT_BROAD_PREFIX=>'~',MT_SUFFIX=>'',MT_CONTAINS=>'',MT_UNKNOWN=>''};
    final static Map<String,String> mapMT_Tail0 = new Map<String,String>{MT_BROAD=>'',MT_PREFIX=>'*',MT_EXACT=>'',MT_BROAD_PREFIX=>'*',MT_SUFFIX=>'',MT_CONTAINS=>'',MT_UNKNOWN=>''};
    
    /** UI Name value with special char ~ or * 
        DFP doese not store that char
        enum matchtype BROAD BROAD_PREFIX PREFIX EXACT        
    */  
    public static String toUIName(String valName,String matchType)
    {
        return  (mapMT_Head0.get(matchType) +valName+ mapMT_Tail0.get(matchType)); //the rest, use old logic        
    }
    
    /* Idnentify the MatchType by the value name */    
    public static String findMatchType(String valName)
    {
        return (valName.startsWith('~') && valName.endsWith('*'))?MT_BROAD_PREFIX:(valName.startsWith('~')?MT_BROAD:valName.endsWith('*')?MT_PREFIX:MT_EXACT);  
    }
    
    public class KVValidator implements DARTObject.IValidator{
        List<String> listErr;
        
        Set<String> listMissingKeys = new Set<String>();  
        Set<String> listMissingValues = new Set<String>();  
        Set<String> listMissingKeyDart6Id = new Set<String>();  
        set<String> listKeyNotFreeform = new Set<String>();
        set<String> listMissingValIdAdtSeg = new set<String>();
        
        Map<String,GAM_Key_Value__c> mapK;
        Map<String,GAM_Key_Value__c> mapV;
        Map<String,GAM_Key_Value__c> mapKeyNotFreeform;
        Set<String>setAllValueNotFreeform;

        /*********************************************************************************************************************************
        @ Constructor:          KVValidator  
        @ Migrated From:        Advertising Instance (Legacy Code)
        @ Purpose:              Validate Key and Value with GAM_Key_Value__c
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
        *********************************************************************************************************************************/
        public KVValidator(Map<String,GAM_Key_Value__c> mapK,Map<String,GAM_Key_Value__c> mapV, Map<String,GAM_Key_Value__c> mapKeyNotFreeform, Set<String>setAllValueNotFreeform) // 13.06.2025 /Sophal Noch/ US-0012504 : remove arg mapAllKeyAudSegs to delete GAM_Audience_Segment__c
        {
            this.mapK = mapK;
            this.mapV = mapV;
            this.mapKeyNotFreeform = mapKeyNotFreeform;
            this.setAllValueNotFreeform = setAllValueNotFreeform;
  
            listErr = new List<String>();

            //System.debug('>>>mapK: '+JSON.serialize(mapK));
            //System.debug('>>>mapV: '+JSON.serialize(mapV));
            //System.debug('>>>setAllValueNotFreeform: '+JSON.serialize(setAllValueNotFreeform));
        }

        /*********************************************************************************************************************************
        @ Method:              checkError  
        @ Migrated From:       Advertising Instance (Legacy Code)
        @ Purpose:             Check error for Key and Value with GAM_Key_Value__c
        ----------------------------------------------------------------------------------------------------------------------------------
        @ Change history : 13.06.2025 /Sophal Noch/ US-0012504 - 2. Deletion of custom objects
        *********************************************************************************************************************************/
        public void checkError(Object o)
        {
            DARTEvaluator.Condition con = (DARTEvaluator.Condition)o;
            String fetchedValue = fetchInvalidChars(con.getValue());
            String k_n_v = con.getParameter() + '_' + fetchedValue;
            //System.debug('>>>checkError:k: '+con.getParameter() +' v: '+fetchedValue);
            if(mapK.get(con.getParameter()) !=null)
            {
                //if(!(setAllValueNotFreeform).contains(fetchedValue) && (mapK.get(con.getParameter())).Type__c==DART6_KeyValueController.KEY_TYPE_FREEFORM) // 
                if(!mapV.containsKey(k_n_v) &&  mapKeyNotFreeform.containsKey(con.getParameter()) ) //value string but not found record itself and Key is not Free-form
                {
                    listMissingValues.add(fetchedValue);
                    listKeyNotFreeform.add(con.getParameter());
                }
                
                if(mapK.containsKey(con.getParameter()) && mapK.get(con.getParameter()).GAM_ID__c==null && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
                {
                    listMissingKeyDart6Id.add(con.getParameter());
                }
            }
            
            if(!mapK.containsKey(con.getParameter()) && (!DART6_KeyValueController.KV_TYPE_AudienceSegment.equals(con.getParameter())))
            { 
                listMissingKeys.add(con.getParameter());
            }
        }

        public List<String> getListError()
        {
            if(!listMissingKeys.isEmpty())
            {
                listErr.add('\n\rKey(s) not found in the Key Value:'+listMissingKeys);
            }
            if(!listMissingValues.isEmpty())
            {
                listErr.add('\n\rValue(s) not found in Key Value:'+listMissingValues+' \n\r And not a free-form value for Key(s):'+listKeyNotFreeform);
            }
            if(!listMissingKeyDart6Id.isEmpty())
            {
                listErr.add('\n\rPredefined GAM ID not found:'+listMissingKeyDart6Id);
            }
            if(!listMissingValIdAdtSeg.isEmpty())
            {
                listErr.add('\n\rPredefined GAM ID not found in Audience Segment:'+listMissingValIdAdtSeg);
            }
            
            return listErr;
        }
        public Boolean isError()
        {
            return (!listMissingKeys.isEmpty() || !listMissingValues.isEmpty() || !listMissingKeyDart6Id.isEmpty() || !listMissingValIdAdtSeg.isEmpty());
        }
    
    }
}