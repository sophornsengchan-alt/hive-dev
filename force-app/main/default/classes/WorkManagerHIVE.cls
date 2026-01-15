/*********************************************************************************************************************************
@ Class:          WorkManagerHIVE
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Controller for lwc: lwcWorkManager

                https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_methods_system_fields_describe.htm#apex_methods_system_fields_describe
                https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_enum_Schema_DisplayType.htm
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.10.2023 / Vadhanak Voun / Created the class.   
                            / Vadhanak Voun / US-0014270 - HoneyComb Work Manager
                : 07.11.2023 / Vadhanak Voun / US-0014370 - HoneyComb Work Manager - part2
                : 22.11.2023 / Vadhanak Voun / US-0014446 - Honeycomb work manager is showing wrong next sprint
                : 08.03.2024 / Vadhanak Voun / US-0014902 - HoneyComb Work Manager - part3
*********************************************************************************************************************************/
public with sharing class WorkManagerHIVE {
    final static String SOBJ_US  = 'copado__User_Story__c';
    final static String STATUS_APPROVED  = 'Approved';
    final static Integer LIMIT_ROW = 200;

    final static Map<Schema.DisplayType,String> MAP_SF_TYPE_TO_TABLE_TYPE = new Map<Schema.DisplayType,String>{
        Schema.DisplayType.String =>'text',
        Schema.DisplayType.Boolean =>'boolean',
        Schema.DisplayType.Integer =>'number',
        Schema.DisplayType.Long =>'number',
        Schema.DisplayType.Picklist =>'text',
        Schema.DisplayType.TextArea =>'text',
        Schema.DisplayType.Double =>'number',
        Schema.DisplayType.DateTime  =>'date',
        Schema.DisplayType.Date =>'date',
        Schema.DisplayType.Currency =>'currency',
        Schema.DisplayType.Combobox =>'text',
        Schema.DisplayType.Email=>'email',
        Schema.DisplayType.REFERENCE=>'url'
    };  

    /*****************************************************************************************************************************
    @ Method:   workManagerInit
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.10.2023 / Vadhanak Voun /US-0014270- HoneyComb Work Manager- Spike
    @               : 10.11.2023 / Vadhanak Voun / US-0014370 - HoneyComb Work Manager - part2
    @               : 22.11.2023 / Vadhanak Voun / US-0014446 - Honeycomb work manager is showing wrong next sprint
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> workManagerInit() 
    {
        Map<String,Object> mapResult = new Map<String,Object>();

        List<Object> listFieldPage =  ApexUtil.getFieldSet('copado__User_Story__c', 'copado__Work_Manager_Columns',true) ;
        List<Object> listFieldPanel =  ApexUtil.getFieldSet('copado__User_Story__c', 'copado__Work_Manager_Relations',true) ;
        
        Map<String,Object> mapFieldPanelMeta = new Map<String,Object>();
        for( Object obj: listFieldPanel)
        {
            Map<String,Object> objField = (Map<String,Object>)obj;
            //here trick recordtype as picklist
           if(objField.get('type')==Schema.DisplayType.REFERENCE+'' && objField.get('referenceto')=='RecordType')
           {
                List<Map<String,String>> recordTypes = new List<Map<String,String>>();
                for(RecordTypeInfo info: copado__User_Story__c.SObjectType.getDescribe().getRecordTypeInfos()) {
                    if(info.isAvailable()) {
                        //recordTypes.add(new SelectOption(info.getRecordTypeId(), info.getName()));
                        recordTypes.add(new Map<String,String>{'value'=>info.getRecordTypeId(), 'label'=>info.getName()});
                    }
                }
                mapFieldPanelMeta.put(objField.get('value')+'',recordTypes);

           }
           else if(objField.get('type')==Schema.DisplayType.PICKLIST+'')
           {
                Map<String, Schema.SObjectField> mapField = copado__User_Story__c.getSObjectType().getDescribe().fields.getMap();
                Schema.SObjectField pklField = mapField.get(objField.get('value')+'');
                List<Map<String,String>> pkVals = ApexUtil.getPicklistValues(pklField);

                mapFieldPanelMeta.put(objField.get('value')+'',pkVals);

           }
        //    else if(objField.get('type')==Schema.DisplayType.REFERENCE+'') //simple lookup
        //    {
        //    }
        
        }
 
        mapResult.put('pklComponentsFilter',ApexUtil.getPicklistValues(copado__User_Story__c.Component__c));

        //system.debug(mapFieldPanelMeta);
        //String excludeActiveSprint = 'Approved - Hive Force';
        //NK:10/11/2023:US-0014370
        List<String> excludeActiveSprint = System.Label.excludeActiveSprint.split(';'); //'Approved - Hive Force;Sprint Break - End of Year'
        List<copado__Sprint__c> curSprints = [Select Id,Name,copado__Start_Date__c,copado__end_Date__c From copado__Sprint__c Where Active_Sprint__c =true AND Name NOT IN:excludeActiveSprint limit 1];
        
        //NK:22/11/2023:US-0014446: added asc and checked empty cur sprint
        List<copado__Sprint__c> nextSprints = !curSprints.isEmpty()?[Select Id,Name,copado__Start_Date__c,copado__end_Date__c From copado__Sprint__c Where copado__Status__c ='Planned' and copado__Start_Date__c >=:curSprints[0].copado__end_Date__c AND Name NOT IN:excludeActiveSprint order by copado__start_Date__c asc limit 1]:new List<copado__Sprint__c>();

        User me = [Select Id,Work_Manager_Setting__c from User Where Id=:UserInfo.getUserId()];
        WorkManager__mdt wmMdt = [Select Label,DeveloperName,JSON_Data__c From WorkManager__mdt Where DeveloperName ='System_Default'];

        mapResult.put('listFieldPage',listFieldPage);
        mapResult.put('listFieldPanel',listFieldPanel);

        mapResult.put('wmSetting',me.Work_Manager_Setting__c); //json
        
        mapResult.put('mapFieldPanelMeta',mapFieldPanelMeta);
        mapResult.put('wmData',wmMdt.JSON_Data__c);
        mapResult.put('curSprint',curSprints.isEmpty()?null:curSprints[0]);
        mapResult.put('nextSprint',nextSprints.isEmpty()?null:nextSprints[0]);

        return mapResult;
    }

    

    /*****************************************************************************************************************************
    @ Method:   getRecordsPanel
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.10.2023 / Vadhanak Voun / US-0014270 - HoneyComb Work Manager
    @               : 06.11.2023 / Vadhanak Voun / US-0014370 - HoneyComb Work Manager - part2
    @               : 08.03.2024 / Vadhanak Voun / US-0014902 - HoneyComb Work Manager - part3
    *****************************************************************************************************************************/
    @AuraEnabled    
    public static Map<String,Object> getRecordsPanel(String jsonPageInfo,String jsonPanel,String sprintId)  
    {        
        OnePageInfo onePage = (OnePageInfo)Json.deserialize(jsonPageInfo, OnePageInfo.class);
        OnePanel panel = (OnePanel)Json.deserialize(jsonPanel, OnePanel.class);

        Map<String,Object> mapResult = new Map<String,Object>();
        List<Object> listFieldCol = new List<Object>();
        Set<String> setClean  = new Set<String>();

        //Schema.DisplayType fType = Schema.SObjectType.Account.fields.getMap().get('fieldName').getDescribe().getType();
        
        Map<String, Schema.SObjectField> fieldsMap = copado__User_Story__c.getSObjectType().getDescribe().fields.getMap();         
        // Set<String> setFields = new Set<String>(panel.columns);
        if(onePage.hiddenFields <> NULL && !onePage.hiddenFields.isEmpty())
        {
            setClean.addAll(onePage.hiddenFields);
        }
        for(String fName : panel.columns)
        // for(String fName : setFields)
        {
            SObjectField sf = fieldsMap.get(fName);
            Schema.DescribeFieldResult f1 = sf.getDescribe();
            Schema.DisplayType fType = f1.getType();

            Map<String,Object> mapObj = new Map<String,Object>{
                'label'=>f1.getLabel(),
                'fieldName'=>fName,
                'type'=>MAP_SF_TYPE_TO_TABLE_TYPE.containsKey(fType)?MAP_SF_TYPE_TO_TABLE_TYPE.get(fType):'text'
                //{ label: 'Opportunity name', fieldName: 'OpportunityName', type: 'text' }
            };
            if(Schema.DisplayType.REFERENCE == fType)
            {
                Map<String,Object> mapAttr = new Map<String,Object>{'label'=>new Map<String,Object>{'fieldName'=>fName+'__ref'},'tooltip'=>new Map<String,Object>{'fieldName'=>fName+'__tooltip'},'target'=>'_blank'};
                mapObj.put('typeAttributes',mapAttr);
                mapObj.put('relationshipName',f1.getRelationshipName());
                if(f1.isCustom())
                {
                    setClean.add( String.escapeSingleQuotes(fName.removeEnd('__c')+'__r.Name'));
                }else 
                {
                    setClean.add( String.escapeSingleQuotes(fName.removeEnd('Id')+'.Name'));
                }
                
            }else if(Schema.DisplayType.PICKLIST == fType)
            {
                setClean.add('toLabel('+ String.escapeSingleQuotes(fName)+')'+String.escapeSingleQuotes(fName)+'__label');
                mapObj.put('isPkl',true);
            }

            listFieldCol.add(
                mapObj
            );
            setClean.add( String.escapeSingleQuotes(fName));
        }
        // String whereCon = ' Where ' + fieldNameCond + ' = :fieldValCon';
        String whereCon = ' Where ' +(String.isBlank(onePage.mainFilter1)?'':onePage.mainFilter1);
        whereCon = whereCon +(String.isBlank(onePage.mainFilter2)?'':' AND '+onePage.mainFilter2);
        whereCon = whereCon +(String.isBlank(onePage.mainFilter3)?'':' AND '+onePage.mainFilter3);
        whereCon = (panel.panelFilter<>null&& !panel.panelFilter.isEmpty())? whereCon +' AND ': whereCon;
        for(String cond : panel.panelFilter)
        {
            whereCon += cond;
        }

        String sOrder = String.isNotBlank(panel.sortOrder)?' ORDER BY '+panel.sortOrder +' '+panel.sortOrderDir+' NULLS LAST':'' ;        
        String soql = 'Select Id,'+String.join(new List<String>(setClean), ',') + ' From ' + SOBJ_US + whereCon + sOrder;// +' LIMIT :LIMIT_ROW ';
        
        System.debug(soql);
        List<SObject> listRecords = Database.query(soql);

        //NK:08/03/2024:US-0014902
        AggregateResult[] result= Database.query('Select count(Id)TotalStory,sum(Total_Story_Points__c)TotalPoint,sum(Story_Points_Dev__c)TotalDev,sum(Story_Points_Test__c)TotalQA  from '+  SOBJ_US + whereCon);

        mapResult.put('listFieldCol',listFieldCol);
        mapResult.put('listRecords',listRecords);
        mapResult.put('totalStory',result[0].get('TotalStory'));
        mapResult.put('totalPoint',result[0].get('TotalPoint'));

        //NK:08/03/2024:US-0014902
        mapResult.put('totalPointDev',result[0].get('TotalDev'));
        mapResult.put('totalPointQA',result[0].get('TotalQA'));

        return mapResult;
    }

    /*****************************************************************************************************************************
    @ Method:   wmMoveStory
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  action, recordId,toSprintId
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 17.10.2023 / Vadhanak Voun / US-0014270 - HoneyComb Work Manager
    @               : 07.11.2023 / Vadhanak Voun / US-0014370 - HoneyComb Work Manager - part2
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> wmMoveStory(String action,String toSprintId,List<String> listIds) 
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        Savepoint sp = Database.setSavepoint();

        try
        {
            if(action=='to_sprint')
            {
                // copado__User_Story__c story = new copado__User_Story__c(Id=recordId,copado__Sprint__c=toSprintId);
                // update story;
                List<copado__User_Story__c> listToUpdate = new List<copado__User_Story__c>();
                for(Integer i=0;i<listIds.size();i++)
                {
                    listToUpdate.add(new copado__User_Story__c(Id=listIds[i],copado__Sprint__c=toSprintId,copado__Backburner_Rank__c=(i+1)));   //NK:06/111/2023:US-0014370
                }
                update listToUpdate;

            }
            // else if(action=='to_bburner')
            // {
            //     copado__User_Story__c story = new copado__User_Story__c(Id=recordId,copado__Sprint__c=null,copado__Status__c=STATUS_APPROVED);
            //     update story;
                
            // }
            else if(action=='update_bburner')
            {
                // Map<Id,copado__User_Story__c>  mapUS = new Map<Id,copado__User_Story__c>([Select Id,copado__Backburner_Rank__c From copado__User_Story__c WHERE Id IN :listIds]);
                List<copado__User_Story__c> toUpdate = new List<copado__User_Story__c>();
                for(Integer i=0;i<listIds.size();i++)
                {
                    //toUpdate.add(new copado__User_Story__c(Id=listIds[i],copado__Backburner_Rank__c=(i+1)));
                    toUpdate.add(new copado__User_Story__c(Id=listIds[i],copado__Backburner_Rank__c=(i+1),copado__Sprint__c=null,copado__Status__c=STATUS_APPROVED));
                }
                update toUpdate;
            }
            
        }catch(DMLException dex)
        {
            mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());Database.rollback(sp);
        }
        catch(Exception ex)
        {
            mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());Database.rollback(sp);
        }

        return mapResult;
    }
    
    /*****************************************************************************************************************************
    @ Method:   wmSaveSetting
    @ Version:  1.0
    @ Author:   Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:  jsonString
    @ Content  : {"lastVisitPage":"Honeycomb_Work_Manager"}
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 21.10.2023 / Vadhanak Voun / US-0014270 - HoneyComb Work Manager
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> wmSaveSetting(String jsonString) 
    {
        Map<String,Object> mapResult = new Map<String,Object>{'status'=>'ok'};
        try
        {       
            update new User(Id=UserInfo.getUserId(),Work_Manager_Setting__c=jsonString);        

        }catch(DMLException dex)
        {
            mapResult.put('status','ko');mapResult.put('error',dex.getDmlMessage(0));mapResult.put('errorDetail',dex.getStackTraceString());
        }
        catch(Exception ex)
        {
            mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }
        
        return mapResult;
    }

    

    class PanelData{
        public OnePageInfo pageInfo;
        List<OnePanel> pWrappers;
    }
    class OnePanel{
        public String panelName;
		public String panelLabel;		
		public String sortOrder;
		public String sortOrderDir;	
        public List<String> panelFilter;//:["copado__Status__c='Approved'"," AND ","copado__Sprint__c=null"],			
		public List<String>	columns;
    }
    class OnePageInfo{
        public String mainFilter1;
		public String mainFilter2;
		public String mainFilter3;
		public String pName;
		public String pLabel;
		public Integer panelRowCount;
        public Set<String> hiddenFields;   //NK:08/03/2024:US-0014902
 
    }
}