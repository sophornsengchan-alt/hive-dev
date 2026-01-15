/**
 * Task #9389: CD-123 - AdSales 2.0 incl. Lightning Product Configurator Enhancements
 * @author: GIS-DevTeam
 * @createdDate: 07/Sep/2016
 * @description:
 * @references:
 *  - LPC_TargetingTreeSelector lightning component
 * @changeLog:
 * //NK:03/03/2021:US-0009123 - [Ads 2020] Optimize the Targetings Screen - KeyValues section
 * //MN:08/06/2021:US-0009634 - [Ads 2020] Change to displaying targeting based on product flags
 * 
 */
public without sharing class LPC_TargetingTreeSelectorController {

    public static final String VAL_SEPARATOR = ', ';
    public static final String DEVICE_TREE_TYPE = 'Device';
    public static final String GEO_TREE_TYPE = 'Geography';
    public static final String BROWSER_TREE_TYPE = 'Browser';
    public static final String CONNECTION_TREE_TYPE = 'Connection';
    public static final String BANDWIDTH_TREE_TYPE = 'Bandwidth';
    public static final String OS_TREE_TYPE = 'OperatingSystem';
    public static final String ADUNIT_TREE_TYPE = 'Ad_Unit';

    @testVisible
    private static Map<String, String> mRelationChildren = new Map<String, String> {
        DEVICE_TREE_TYPE => Util.NS+'Devices__r',
        GEO_TREE_TYPE => Util.NS+'Geographies__r',
        BROWSER_TREE_TYPE => Util.NS+'Devices__r',
        CONNECTION_TREE_TYPE => Util.NS+'Connections__r',
        BANDWIDTH_TREE_TYPE => Util.NS+'Connections__r',
        OS_TREE_TYPE => Util.NS+'Devices__r',
        ADUNIT_TREE_TYPE => Util.NS+'Contents1__r'
    };

    private static Map<String, String> mTypeToSObj = new Map<String, String> {
        DEVICE_TREE_TYPE => Util.NS+'Devices__c',
        GEO_TREE_TYPE => Util.NS+'Geography__c',
        BROWSER_TREE_TYPE => Util.NS+'Devices__c',
        CONNECTION_TREE_TYPE => Util.NS+'Connection__c',
        BANDWIDTH_TREE_TYPE => Util.NS+'Connection__c',
        OS_TREE_TYPE => Util.NS+'Devices__c',
        ADUNIT_TREE_TYPE => Util.NS+'Content__c'
    };
    @testVisible
    private static Set<String> treeTypes = new Set<String>{
        DEVICE_TREE_TYPE, 
        GEO_TREE_TYPE, 
        BROWSER_TREE_TYPE, 
        CONNECTION_TREE_TYPE ,
        BANDWIDTH_TREE_TYPE, 
        OS_TREE_TYPE,
        ADUNIT_TREE_TYPE 
    };

    //Define checked node
    private static Map<Id, String> mapSelectedMode = new Map<Id, String>();
    private static Map<Id, List<DTOTreeItem>> mapParentChildNodes = new Map<Id, List<DTOTreeItem>>();
    private static Map<String, List<DTOTreeItem>> mapSelectedTreeName = new Map<String, List<DTOTreeItem>>();

    //  error message for csv upload
    private static String csvUploadMsg = '';

    private static List<QuoteLineItem> predefineId ;

    @AuraEnabled
    public List<DTOTreeItem> lsts { get; set; }

    /**
     * Check Existing Associate Nodes
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @return Set<Id>
     */
    private static Set<Id> checkExistingAssociateNodes (String treeType, String targetId, String predefindedId) {

        if (treeType == DEVICE_TREE_TYPE || treeType == BROWSER_TREE_TYPE || treeType == OS_TREE_TYPE) {
            for( TargetingDeviceAssociation__c targeting:  [Select Device__r.Node_ID__r.DFP_API_Name__c, Device__r.Node_ID__c, Device__c, Device__r.Name, Device__r.DFP_API_Name__c, Device__r.MajorVersion__c, Device__r.MinorVersion__c  From TargetingDeviceAssociation__c Where Targeting__c=:targetId]){
                mapSelectedMode.put(targeting.Device__c, 'checked');
                String keyApiName =  targeting.Device__r.Node_ID__r.DFP_API_Name__c;
                if(keyApiName == OS_TREE_TYPE) keyApiName = OS_TREE_TYPE;
                else if(targeting.Device__r.DFP_API_Name__c == BROWSER_TREE_TYPE) keyApiName = BROWSER_TREE_TYPE;
                else keyApiName = DEVICE_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = targeting.Device__c;
                dto.treeName = targeting.Device__r.Name;
                dto.typeLabel = '';
                dto.isContainsChilds = true;
                if (BROWSER_TREE_TYPE == treeType) dto.typeLabel = ' (' + (targeting.Device__r.MajorVersion__c == 'Any'?'x':targeting.Device__r.MajorVersion__c) + '.' + (targeting.Device__r.MinorVersion__c=='Any'?'x':targeting.Device__r.MinorVersion__c) +')';
                if(!mapSelectedTreeName.containsKey(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }
        }
        if (treeType == CONNECTION_TREE_TYPE || treeType == BANDWIDTH_TREE_TYPE) {
            for( TargetingConnectionAssociation__c targeting:  [Select Connection__c, Connection__r.DFP_API_Name__c, Connection__r.Name From TargetingConnectionAssociation__c Where Targeting__c=:targetId]){
                mapSelectedMode.put(targeting.Connection__c, 'checked');
                String keyApiName =  targeting.Connection__r.DFP_API_Name__c;
                if(keyApiName != 'BandwidthGroup') keyApiName = CONNECTION_TREE_TYPE;
                else keyApiName = BANDWIDTH_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = targeting.Connection__c;
                dto.treeName = targeting.Connection__r.Name;
                dto.typeLabel = '';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }
        }
        if (treeType == GEO_TREE_TYPE) {
            for( TargetingGeographyAssociation__c targeting:  [Select Geography__c, Geography__r.Name, Geography__r.Type__c From TargetingGeographyAssociation__c Where Targeting__c=:targetId]){
                mapSelectedMode.put(targeting.Geography__c, 'checked');
                String keyApiName = GEO_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = targeting.Geography__c;
                dto.treeName = targeting.Geography__r.Name;
                dto.typeLabel = ' (' + targeting.Geography__r.Type__c + ' )';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }
        }
        if (treeType == ADUNIT_TREE_TYPE) {
            for( TargetingContentAssociation__c targeting:  [Select TargetingContent__c, TargetingContent__r.DartName__c, TargetingContent__r.Type__c From TargetingContentAssociation__c Where Targeting__c=:targetId ]){ //And TargetingContent__c <>:predefindedId
                mapSelectedMode.put(targeting.TargetingContent__c, 'checked');
                String keyApiName = ADUNIT_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = targeting.TargetingContent__c;
                String strType = String.isEmpty(targeting.TargetingContent__r.Type__c) ? '' : targeting.TargetingContent__r.Type__c.substringAfter('-');
                dto.treeName = targeting.TargetingContent__r.DartName__c;
                dto.typeLabel = ' (' + strType.trim() + ')';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }

            for( PlacementTargetingAssociation__c placetargeting:  [Select Placement__r.Content_Category_Site__c, Placement__r.Content_Category_Site__r.DartName__c, Placement__r.Content_Category_Site__r.Type__c From PlacementTargetingAssociation__c Where Targeting__c=:targetId]){
                if(placetargeting.Placement__r.Content_Category_Site__c == null) continue;
                mapSelectedMode.put(placetargeting.Placement__r.Content_Category_Site__c, 'checked');
                String keyApiName = ADUNIT_TREE_TYPE;
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = placetargeting.Placement__r.Content_Category_Site__c;
                dto.treeName = placetargeting.Placement__r.Content_Category_Site__r.DartName__c;
                String strType = placetargeting.Placement__r.Content_Category_Site__r.Type__c.substringAfter('-');
                dto.typeLabel = ' (' + strType.trim() + ')';
                dto.isContainsChilds = true;
                if(!mapSelectedTreeName.keySet().contains(keyApiName)) mapSelectedTreeName.put(keyApiName, new List<DTOTreeItem>());
                mapSelectedTreeName.get(keyApiName).add(dto);
            }
        }
        return mapSelectedMode.keySet();
    }

    /**
     * Define h-checked nodes
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param treeType, type name
     * @param setCheckedIds, Set<Id> checked Ids
     */
    private static void checkParentAssociateNodes(String treeType, Set<Id> setCheckedIds, Set<Id> renderedIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        Set<Id> parentIds = new Set<Id>();
        String selectFields = '';
        if(treeType == BROWSER_TREE_TYPE){
            selectFields = ', '+Util.NS+'MajorVersion__c, '+Util.NS+'MinorVersion__c ';
        }else if(treeType == GEO_TREE_TYPE || treeType == ADUNIT_TREE_TYPE){
            selectFields = ', '+Util.NS+'Type__c ';
        }

        String queryStr = 'Select Name, Id, '+Util.NS+'Node_ID__c' + selectFields + ' From ' + mTypeToSObj.get(treeType) + ' Where Id IN: setCheckedIds';
        String parentFieldName = Util.NS+'Node_ID__c';
        String nodeFieldName = 'Name';
        if (isContentTree) {
            queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Content__c' + selectFields + ', (Select Id  From ' + mRelationChildren.get(treeType) + ' Where '+Util.NS+'Active__c = true limit 1) From ' + mTypeToSObj.get(treeType) + ' Where Id IN: setCheckedIds';
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
        }
        
        //system.debug('>>>queryStr: '+parentFieldName+' >>: '+queryStr);
        
        for(SObject sobj : database.query(queryStr)) {
            if (sobj.get(parentFieldName) != null) {
                String parentId = String.valueOf(sobj.get(parentFieldName));
                parentIds.add(parentId);
                if (mapSelectedMode.get(parentId) != 'checked') {
                    mapSelectedMode.put(parentId, 'hchecked');
                }

                //load parent to its children for first load
                if (!mapParentChildNodes.containsKey(parentId)) {
                    mapParentChildNodes.put(parentId, new List<DTOTreeItem>());
                }
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = sobj.id;
                dto.treeName = String.valueOf(sobj.get(nodeFieldName));
                dto.isContainsChilds = true;
                if(isContentTree) dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
                dto.typeLabel = '';
                if(treeType == BROWSER_TREE_TYPE){
                    dto.typeLabel = ' ('+ (sobj.get(Util.NS+'MajorVersion__c') == 'Any'?'x': sobj.get(Util.NS+'MajorVersion__c')) + '.' + (sobj.get(Util.NS+'MinorVersion__c')=='Any'?'x':sobj.get(Util.NS+'MinorVersion__c')) +')';
                }else if(treeType == GEO_TREE_TYPE){
                    dto.typeLabel = ' ('+ sobj.get(Util.NS+'Type__c') +')';
                }else if(treeType == ADUNIT_TREE_TYPE){
                    String typ = String.valueOf(sobj.get(Util.NS+'Type__c')) + '';
                    String strType = typ.substringAfter('-');
                    dto.typeLabel = ' ('+ strType.trim() +')';
                }

                if (!renderedIds.contains(sobj.id)) {
                   renderedIds.add(sobj.id);
                   mapParentChildNodes.get(parentId).add(dto);
                }
            }
        }
        if (!parentIds.isEmpty()) {
            checkParentAssociateNodes(treeType, parentIds, renderedIds);
        }
    }

    /**
     * Get Tree Data Source By Type at level 1
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @param contentId, contentId for AdUnit Treee
     * @return List<SObject>
     */
    private static List<SObject> getTreeSourceByType(String treeType, String contentId) {
        String queryStr = '';

        if (treeType == DEVICE_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, (Select id From '+Util.NS+'Devices__r limit 1) From '+Util.NS+'Devices__c ' +
            'Where '+Util.NS+'DFP_API_Name__c <> \'OperatingSystem\' And '+Util.NS+'DFP_API_Name__c <> \'Browser\' And '+Util.NS+'Node_ID__c = null order by Name';

        } else if (treeType == GEO_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, '+Util.NS+'Type__c, (Select id From '+Util.NS+'Geographies__r limit 1) From '+Util.NS+'Geography__c ' +
            'Where '+Util.NS+'Node_ID__c = null order by Name';

        } else if (treeType == BROWSER_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, '+Util.NS+'MajorVersion__c, '+Util.NS+'MinorVersion__c,  (Select id From '+Util.NS+'Devices__r limit 1) From '+Util.NS+'Devices__c ' +
            'Where '+Util.NS+'Node_ID__r.'+Util.NS+'DFP_API_Name__c = \'Browser\' order by Name';

        } else if (treeType == CONNECTION_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, (Select id From '+Util.NS+'Connections__r limit 1) From '+Util.NS+'Connection__c ' +
            'Where '+Util.NS+'DFP_API_Name__c <> \'BandwidthGroup\' And '+Util.NS+'Node_ID__c = null order by Name';

        } else if (treeType == BANDWIDTH_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, (Select id From '+Util.NS+'Connections__r limit 1) From '+Util.NS+'Connection__c ' +
            'Where '+Util.NS+'Node_ID__r.'+Util.NS+'DFP_API_Name__c = \'BandwidthGroup\' order by Name';

        } else if (treeType == OS_TREE_TYPE) {

            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, (Select id From '+Util.NS+'Devices__r limit 1) From '+Util.NS+'Devices__c ' +
            'Where '+Util.NS+'Node_ID__r.'+Util.NS+'DFP_API_Name__c = \'OperatingSystem\' And '+Util.NS+'Node_ID__r.'+Util.NS+'Node_ID__c = null order by Name';

        } else if (treeType == ADUNIT_TREE_TYPE) {

            queryStr = 'Select Id, '+Util.NS+'DartName__c, '+Util.NS+'Content__c, '+Util.NS+'Type__c, '+Util.NS+'Site_Content_Category__c, (Select Id From ' + mRelationChildren.get(treeType) + ' Where '+Util.NS+'Active__c = true limit 1) From '+Util.NS+'Content__c  ' +
            'Where (Id =: contentId) and '+Util.NS+'Active__c = true order by '+Util.NS+'DartName__c';

        }
        return database.query(queryStr);
    }



    @AuraEnabled
    public static RemoteResponse loadSummary (String lineItemId, String contentFile){
        RemoteResponse response = new RemoteResponse();
        try {
        
            Targeting__c tg = new Targeting__c();
            Map<String, Object> mapTargetingSummary = new Map<String, Object>();
            QuoteLineItem quoteLine = [Select Product2.Name, 
                                        Targeting__c,
                                        Targeting__r.DFP_Time_Monday__c, Targeting__r.DFP_Time_Tuesday__c, 
                                        Targeting__r.DFP_Time_Wednesday__c, Targeting__r.DFP_Time_Thursday__c, 
                                        Targeting__r.DFP_Time_Friday__c, Targeting__r.DFP_Time_Saturday__c, 
                                        Targeting__r.DFP_Time_Sunday__c, 
                                        Product2.Content__c, 
                                        Product2Id, 
                                        Product2.Advertising_Medium__r.AdServer_Keywords_Key_Values__c, //NK:03/03/2021:US-0009123
                                        AdKeyWords__c,

                                        Product2.Keywords__c,
                                        Product2.available_Key_Values__c, //MN-08062021-US-0009634
                                        Predefined_DeviceCategory__c, 
                                        Predefined_Adunit__r.DartName__c, 
                                        Predefined_Adunit__c,Predefined_Placement__r.Name,
                                        Predefined_Placement__r.Id From QuoteLineItem Where Id =: lineItemId];
            String targetId = quoteLine.Targeting__c;
            if (quoteLine.Targeting__c == null) {
                tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');
                insert tg;
                targetId = tg.Id;
                quoteLine.Targeting__c =  tg.Id;
                update quoteLine;
            } else {
                tg = new Targeting__c(Id=quoteLine.Targeting__c, 
                                    DFP_Time_Monday__c = quoteLine.Targeting__r.DFP_Time_Monday__c,
                                                        DFP_Time_Tuesday__c = quoteLine.Targeting__r.DFP_Time_Tuesday__c,
                                                        DFP_Time_Wednesday__c = quoteLine.Targeting__r.DFP_Time_Wednesday__c,
                                                        DFP_Time_Thursday__c = quoteLine.Targeting__r.DFP_Time_Thursday__c,
                                                        DFP_Time_Friday__c = quoteLine.Targeting__r.DFP_Time_Friday__c,
                                                        DFP_Time_Saturday__c = quoteLine.Targeting__r.DFP_Time_Saturday__c,
                                                        DFP_Time_Sunday__c = quoteLine.Targeting__r.DFP_Time_Sunday__c  );
              
            }
            String predefinedId = quoteLine.Predefined_Adunit__c!=null?quoteLine.Predefined_Adunit__c+'':'';
            for( String treeType: LPC_TargetingTreeSelectorController.treeTypes ){
                List<Object> objs = getTargetingTree(treeType, targetId, quoteLine.Product2.Content__c, predefinedId, contentFile) ;
                // hard-coded index: the selected tree is in 3rd index depends on getTargetingTree method
                mapTargetingSummary.put(treeType, objs.get(3));
            }

            //// key value
            String keyValuesSetSummary = LPC_KeyValuesSelectorController.getKeyValuesSetSummary(targetId);
            mapTargetingSummary.put('KeyValue', keyValuesSetSummary);
            mapTargetingSummary.put('KeyValuePredefined', quoteLine.Product2.Advertising_Medium__r.AdServer_Keywords_Key_Values__c);
            mapTargetingSummary.put('FinalKeyValue', quoteLine.AdKeyWords__c);

            mapTargetingSummary.put('EnableKeyWords', quoteLine.Product2.Keywords__c);


            //// FC
            List<TargetingFrequencyAssociation__c> lstTarFre = LPC_FrequencyCappingController.getTargetingFrequencyAssociation(targetId);
            mapTargetingSummary.put('FC', lstTarFre);

            //// Time
            mapTargetingSummary.put('TargetingTime', tg);
            


            response.content = mapTargetingSummary;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
        } catch(Exception e) { return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
        return response;
    }

    /**
     * Get Tree Nodes By Type at level 1
     * @param treeType, type name
     * @param lineItemId, QuoteLineItem Id
     * @return List<SObject>
     */
    @AuraEnabled
    public static RemoteResponse getTree(String treeType, String lineItemId, String contentFile) {
        try{
            QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, Product2.Content__c, Product2Id, Predefined_DeviceCategory__c, Predefined_Adunit__r.DartName__c, Predefined_Adunit__c,Predefined_Placement__r.Name,Predefined_Placement__r.Id From QuoteLineItem Where Id =: lineItemId];
            String targetId = quoteLine.Targeting__c;
            if (quoteLine.Targeting__c == null) {
                Targeting__c tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');
                insert tg;
                targetId = tg.Id;
                quoteLine.Targeting__c =  tg.Id;
                update quoteLine;
            }
            String predefinedId = quoteLine.Predefined_Adunit__c!=null?quoteLine.Predefined_Adunit__c+'':'';

            RemoteResponse response = new RemoteResponse();
            List<Object> objs = getTargetingTree(treeType, targetId, quoteLine.Product2.Content__c, predefinedId, contentFile) ;

            Map<String, String> predefined = new Map<String, String>();
            Map<String,String> placement = new Map<String,String>();

            String predefinedAdunit = quoteLine.Predefined_Adunit__r.DartName__c!=null?quoteLine.Predefined_Adunit__r.DartName__c+'':'';
            String predefinedDevice = quoteLine.Predefined_DeviceCategory__c!=null?quoteLine.Predefined_DeviceCategory__c+'':'';

            String placementAdunit = quoteLine.Predefined_Placement__r.Name!=null?quoteLine.Predefined_Placement__r.Name +'':'';

            predefined.put('predefinedAdunit', predefinedAdunit);
            predefined.put('predefinedDevice', predefinedDevice);
            predefined.put('placementAdunit',placementAdunit);
            objs.add(predefined);

            //response.content = objs;

            // for new upload template
            response.content = new Map<String,Object>{
                'objs' => objs,
                'csvUploadMsg' => csvUploadMsg
            };


            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){ return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
        
    }

    /**
     * Get Tree Template Nodes By Type at level 1
     * @param treeType, type name
     * @param lineItemId, QuoteLineItem Id
     * @return List<SObject>
     */
    @AuraEnabled
    public static RemoteResponse getTreeTemplate(String treeType, String targetId, String lineItemId) {
        try{
            QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, Product2.Content__c, Product2Id From QuoteLineItem Where Id =: lineItemId];
            RemoteResponse response = new RemoteResponse();
            List<Object> objs = getTargetingTree(treeType, targetId, quoteLine.Product2.Content__c, '');
            response.content = objs;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){ return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
        
    }

    /**
     * Get TargetingTree Template Nodes By Type at level 1
     * @param treeType, type name
     * @param targetId, Targeting__c Id
     * @return List<Object>
     */
    private static List<Object> getTargetingTree(String treeType, String targetId, String contentId, String predefindedId){
        return getTargetingTree( treeType, targetId, contentId, predefindedId, null);
    }
    private static List<Object> getTargetingTree(String treeType, String targetId, String contentId, String predefindedId, String uploadedCSV){
        mapSelectedTreeName = new Map<String, List<DTOTreeItem>>{
            treeType => new List<DTOTreeItem>()
        };
        mapParentChildNodes = new Map<Id, List<DTOTreeItem>>();
        mapSelectedMode = new Map<Id, String>();

        Set<Id> exIds = checkExistingAssociateNodes(treeType, targetId, predefindedId);

        // currently only geo able to get tree from csv
        if(String.isNotBlank(uploadedCSV) && treeType==GEO_TREE_TYPE){
           addTargettingFromCSVContent(uploadedCSV);
        }

        Set<Id> renderedIds = new Set<Id>();
        checkParentAssociateNodes(treeType, exIds, renderedIds);

        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String nodeFieldName = 'Name';
        if (isContentTree) {
            nodeFieldName = Util.NS+'DartName__c';
        }
        List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
        List<SObject> lSobject = getTreeSourceByType(treeType, contentId);
        //system.debug('targetingList'+lSobject);
        for(SObject sobj : lSobject){
            DTOTreeItem dto =new DTOTreeItem();
            dto.treeId = sobj.id;

            dto.treeName = String.valueOf(sobj.get(nodeFieldName));
            if(treeType == BROWSER_TREE_TYPE){
                dto.treeName = dto.treeName;
                dto.typeLabel = ' ('+ (sobj.get(Util.NS+'MajorVersion__c') == 'Any'?'x': sobj.get(Util.NS+'MajorVersion__c')) + '.' + (sobj.get(Util.NS+'MinorVersion__c')=='Any'?'x':sobj.get(Util.NS+'MinorVersion__c')) +')';
            }else if(treeType == GEO_TREE_TYPE){
                dto.treeName = dto.treeName;
                dto.typeLabel = ' ('+ sobj.get(Util.NS+'Type__c') +')';
            }else if(treeType == ADUNIT_TREE_TYPE){
                String typ = String.valueOf(sobj.get(Util.NS+'Type__c'))+'';
                String strType = typ.substringAfter('-');
                dto.treeName = dto.treeName;
                dto.typeLabel = ' ('+ strType.trim() +')';
            }

            dto.level = 1;
            dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
            dto.selectMode = mapSelectedMode.containsKey(sobj.id) ? mapSelectedMode.get(sobj.id) : 'unchecked';
            dto.isSecretNode = false;
            lstTree.add(dto);
            //Add children on load
            addChildrenNode(dto, lstTree, isContentTree && true);
        }

        repareIndexList(lstTree);

        List<Object> objs = new List<Object>();
        objs.add(lstTree);
        objs.add(mapSelectedMode);
        objs.add(exIds);
        objs.add(mapSelectedTreeName);
        return objs;
    }

    /**
     * Repare Index of List
     * @param lstTree, List<DTOTreeItem>
     */
    private static void repareIndexList(List<DTOTreeItem> lstTree) {
        Integer posIndex = 0;
        for (DTOTreeItem dto : lstTree) {
            dto.pos = posIndex;
            posIndex++;
        }
    }

    /**
     * Add Children Nodes to parent on retrieval
     * @param pnode, parent node
     * @param lstTree, children nodes
     * @param increaseLevel, fake level for adUnit Tree Nodes
     */
    private static void addChildrenNode(DTOTreeItem pnode, List<DTOTreeItem> lstTree, Boolean increaseLevel) {
        if (!mapParentChildNodes.containsKey(pnode.treeId)) return;
        List<DTOTreeItem> lstChildren = mapParentChildNodes.get(pnode.treeId);
        for (DTOTreeItem dto : lstChildren) {
            dto.level = pnode.level + 1;
            if (increaseLevel) dto.level = dto.level + 1;
            dto.selectMode = mapSelectedMode.containsKey(dto.treeId) ? mapSelectedMode.get(dto.treeId) : 'unchecked';
            dto.isSecretNode = true;
            lstTree.add(dto);
            addChildrenNode(dto, lstTree, false);
        }
    }
    
    static Set<String> getDupNames(Geography__c[] geos) {
        Set<String> dupNames = new Set<String>();
        Set<String> sigleNames = new Set<String>();
        for(Geography__c g : geos) {
            if(sigleNames.contains(g.Name)) {
                dupNames.add(g.Name);
            } else {
                sigleNames.add(g.Name);
            }
        }
        return dupNames;
    }
    private static void addTargettingFromCSVContent(String csvContent){
        csvUploadMsg = '';
        // This used for search GEO by upload CSV
        List<DTOTreeItem> geosTree= new List<DTOTreeItem>();
        Set<String> postals = new Set<String>(mergeCSV(csvContent));
        Geography__c[] geos = (List<Geography__c>) QueryUtil.queryRecords(Util.NS+'Geography__c','Name IN:value1 AND Type__c =:value2', new Map<String,Object>{'value1'=>postals, 'value2'=>'POSTAL_CODE'});
        Set<String> dupNames = getDupNames(geos);
        if(!dupNames.isEmpty()) csvUploadMsg = 'Some postal codes are found more than 1: ' +dupNames +'\n';
        
        for(Geography__c geo: geos) {
            postals.remove(geo.Name);
            if(!dupNames.contains(geo.Name) && !mapSelectedMode.containsKey(geo.ID)){

                mapSelectedMode.put(geo.ID, 'checked');
    
                DTOTreeItem dto = new DTOTreeItem();
                dto.treeId = geo.Id;
                dto.treeName = geo.Name;
                dto.typeLabel = '(' + geo.Type__c + ')';
                dto.isContainsChilds = true;
    
                geosTree.add(dto);
            }
        }
        for(String p : postals) {
            if( !(p.isNumeric()) ) postals.remove(p);
        }
        if(!postals.isEmpty()) csvUploadMsg +='Some postal codes are not found: ' + postals ;

        if(!mapSelectedTreeName.containsKey(GEO_TREE_TYPE)){
            mapSelectedTreeName.put(GEO_TREE_TYPE, geosTree);
        }else{
            mapSelectedTreeName.get(GEO_TREE_TYPE).addAll(geosTree);
        }
    }

    /**
     * Get Children Nodes to add to parent on retrieval
     * @param treeType, type of tree
     * @param parentId, parent Id
     * @param level, parent level
     * @param mapDevSelectedMode, Selected Mode List
     * @return List<Object>
     */
    @AuraEnabled
    public static RemoteResponse getChildren(String treeType, String parentId, Integer level, Map<String, String> mapDevSelectedMode){
        List<DTOTreeItem> lstTree = new List<DTOTreeItem>();

        String selectFields = '';
        if(treeType == BROWSER_TREE_TYPE){
            selectFields = ', '+Util.NS+'MajorVersion__c, '+Util.NS+'MinorVersion__c ';
        }else if(treeType == GEO_TREE_TYPE || treeType == ADUNIT_TREE_TYPE){
            selectFields = ', '+Util.NS+'Type__c ';
        }

        String queryStr = 'Select Id, Name '+ selectFields +', (Select Id  From ' + mRelationChildren.get(treeType) + ' limit 1) From ' + mTypeToSObj.get(treeType) + ' Where '+Util.NS+'Node_ID__c =: parentId order by Name';
        String parentFieldName = 'Node_ID__c';
        String nodeFieldName = 'Name';
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        if (isContentTree) {
            String strWhere = Util.NS+'Active__c = true';
            String parentIdFolder = parentId.substringAfter('-');
            if(level == 2 && parentIdFolder == 'placement'){
                parentId = parentId.substringBefore('-');
                strWhere += ' And '+Util.NS+'Site_Content_Category__c =: parentId';
            }else if(level == 2 && parentIdFolder == 'adunit'){
                parentId = parentId.substringBefore('-');
                strWhere += ' And '+Util.NS+'Content__c =: parentId';
            }else{
                strWhere += ' And '+Util.NS+'Content__c =: parentId';
            }
            queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Content__c '+ selectFields +', (Select Id  From ' + mRelationChildren.get(treeType) + ' Where '+Util.NS+'Active__c = true limit 1) From ' + mTypeToSObj.get(treeType) + ' Where ' + strWhere + ' order by '+Util.NS+'DartName__c';
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
        }
        try{
            //add new placement tree
            if(level == 1 && treeType == ADUNIT_TREE_TYPE){
                fetchContentTreeWithPlacement(treeType, parentId, level, lstTree, true);
            }else{
                //system.debug('>>>queryStr: '+queryStr);
                for(SObject sobj: database.query(queryStr)){
                    DTOTreeItem dto =new DTOTreeItem();
                    dto.treeId = sobj.id;

                    dto.treeName = String.valueOf(sobj.get(nodeFieldName));
                    dto.typeLabel = '';
                    if(treeType == BROWSER_TREE_TYPE){
                        dto.treeName = dto.treeName;
                        dto.typeLabel = ' ('+ (sobj.get(Util.NS+'MajorVersion__c') == 'Any'?'x': sobj.get(Util.NS+'MajorVersion__c')) + '.' + (sobj.get(Util.NS+'MinorVersion__c')=='Any'?'x':sobj.get(Util.NS+'MinorVersion__c')) +')';
                    }else if(treeType == GEO_TREE_TYPE){
                        dto.treeName = dto.treeName;
                        dto.typeLabel = ' ('+ sobj.get(Util.NS+'Type__c') +')';
                    }
                    else if(treeType == ADUNIT_TREE_TYPE){
                        String typ = String.valueOf(sobj.get(Util.NS+'Type__c'))+'';
                        String strType = typ.substringAfter('-');
                        dto.treeName = dto.treeName;
                        dto.typeLabel = ' ('+ strType.trim() +')';
                    }

                    dto.parentId = parentId;
                    dto.level = level + 1;
                    dto.isContainsChilds = sobj.getSObjects(mRelationChildren.get(treeType)) != null;
                   
                    dto.selectMode = mapDevSelectedMode.containsKey(sobj.id) ? mapDevSelectedMode.get(sobj.id) : 'unchecked';
                    dto.isSecretNode = false;
                    lstTree.add(dto);
                    //Add children on load
                    addChildrenNode(dto, lstTree, false);
                }
            }

            repareIndexList(lstTree);

            List<Object> objs = new List<Object>();
            objs.add(lstTree);

            RemoteResponse response = new RemoteResponse();
            response.content = objs;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(Exception e){ return new RemoteResponse(e.getStackTraceString() + '  ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
    }

    /**
     * Create Tree From Node Ids
     * @param treeType, Tree Type
     * @param parentId, Node parent Id
     * @param level, parent level
     * @param lstTree, tree to return
     * @param isGetChild, invoked from getChild method
     */
    private static void fetchContentTreeWithPlacement(String treeType, String parentId, Integer level, List<DTOTreeItem> lstTree, Boolean isGetChild) {
        //search result need an insertion to the tree
        Integer i = -1;
        for (DTOTreeItem nodeTree : lstTree) {
            if (!isGetChild) nodeTree.level = nodeTree.level + 1;
            if (!nodeTree.isPlacement) i++;
        }

        //adunit
        DTOTreeItem dto =new DTOTreeItem();
        dto.treeId = parentId + '-adunit';
        dto.treeName = 'Ad Units';
        dto.level = 2;
        dto.isContainsChilds = true;
        dto.selectMode = '';
        dto.isSecretNode = false;
        dto.isPlacement = false;

        //placement
        DTOTreeItem dto1 =new DTOTreeItem();
        dto1.treeId = parentId + '-placement';
        dto1.treeName = 'Placements';
        dto1.level = 2;
        dto1.isContainsChilds = true;
        dto1.selectMode = '';
        dto1.isSecretNode = false;
        dto1.isPlacement = false;
        if (isGetChild) {
            lstTree.add(dto);
            lstTree.add(dto1);
        } else {
            lstTree.add(i, dto1);
            lstTree.add(1, dto);
        }
    }

    /**
     * Create Tree From Node Ids
     * @param treeType, Tree Type
     * @param treeNodeIds, Nodes to create a tree
     * @param nodesToDisplay, Nodes to show based on filter
     * @param contentId, AdUnit Id
     * @return List<DTOTreeItem>
     */
    private static List<DTOTreeItem> createTreeFromNodeIds(String treeType, Set<String> treeNodeIds, Set<String> nodesToDisplay, String contentId) {
        String queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
        String parentFieldName = Util.NS+'Node_ID__c';
        String nodeFieldName = 'Name';
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        if (isContentTree) {
            queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Content__c, '+Util.NS+'Site_Content_Category__c, '+Util.NS+'Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
        }
        if(treeType==GEO_TREE_TYPE){
            queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, '+Util.NS+'Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: treeNodeIds';
        }

        List<SObject> lTreeIncluded = database.query(queryStr);
        //Prepare Children
        Map<String, List<SObject>> mChildren = new Map<String, List<SObject>>();
        for (SObject sobj : lTreeIncluded) {
            if( isContentTree && sobj.get(Util.NS+'Type__c') + '' == 'Dart - ContentCategory') {
                parentFieldName = Util.NS+'Site_Content_Category__c';
            }
            if (sobj.get(parentFieldName) == null) continue;
            String parentId = String.valueOf(sobj.get(parentFieldName));
            if (!mChildren.containsKey(parentId)) {
                mChildren.put(parentId, new List<SObject>());
            }
            mChildren.get(parentId).add(sobj);
        }

        //Create Tree Structure
        List<SObject> lTreeSource = getTreeSourceByType(treeType, contentId);
        List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
        for (SObject sobjRoot : lTreeSource) {
            if (!treeNodeIds.contains(sobjRoot.Id)) {
                continue;
            }
            createTreeFromSObject(treeType, isContentTree, lstTree, sobjRoot, 1, mChildren, nodesToDisplay);
        }
        return lstTree;
    }

    /**
     * Create Tree From SObject
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param isContentTree, AdUnit Tree
     * @param lstTree, Tree Result
     * @param sobjNode, Node of tree
     * @param level, current level
     * @param nodesToDisplay, Nodes to show based on filter
     * @param mChildren, children belonging to sobjNode
     */
    private static void createTreeFromSObject(String treeType, Boolean isContentTree, List<DTOTreeItem> lstTree, SObject sobjNode, Integer level, Map<String, List<SObject>> mChildren, Set<String> nodesToDisplay) {
        String parentFieldName = Util.NS+'Node_ID__c';
        String nodeFieldName = 'Name';
        DTOTreeItem dto =new DTOTreeItem();
        if (isContentTree) {
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
            dto.isPlacement = sobjNode.get(Util.NS+'Type__c') == 'Dart - ContentCategory';
            dto.treeName = String.valueOf(sobjNode.get(nodeFieldName));
        }
        dto.typeLabel = '';
        if(treeType == BROWSER_TREE_TYPE){
            dto.typeLabel = ' ('+ (sobjNode.get(Util.NS+'MajorVersion__c') == 'Any'?'x': sobjNode.get(Util.NS+'MajorVersion__c')) + '.' + (sobjNode.get(Util.NS+'MinorVersion__c')=='Any'?'x':sobjNode.get(Util.NS+'MinorVersion__c')) +')';
        }else if(treeType == GEO_TREE_TYPE){
            dto.typeLabel = ' ('+ sobjNode.get(Util.NS+'Type__c') +')';
        }else if(treeType == ADUNIT_TREE_TYPE){
            String typ = String.valueOf(sobjNode.get(Util.NS+'Type__c'))+'';
            String strType = typ.substringAfter('-');
            dto.typeLabel = ' ('+ strType.trim() +')';
        }

        dto.treeId = sobjNode.id;
        dto.treeName = String.valueOf(sobjNode.get(nodeFieldName));
        dto.parentId = sobjNode.get(parentFieldName) == null ? (isContentTree ? (sobjNode.get(Util.NS+'Site_Content_Category__c')== null ? null : sobjNode.get(Util.NS+'Site_Content_Category__c')+'') : null )  : String.valueOf(sobjNode.get(parentFieldName));
        dto.level = level;
        dto.isContainsChilds = mChildren.containsKey(sobjNode.id);
        dto.selectMode = 'unchecked';
        dto.isSecretNode = !nodesToDisplay.contains(sobjNode.id);
        lstTree.add(dto);
        if (dto.isContainsChilds) {
            List<SObject> lchildren = mChildren.get(sobjNode.id);
            for (SObject sobjChild : lchildren) {
                createTreeFromSObject(treeType, isContentTree, lstTree, sobjChild, level + 1, mChildren, nodesToDisplay);
            }
        }
    }

    /**
     * Find matching parent to nodes
     * Since Data Struture is a tree, we have to do recursive method. But it would be maximum 6 depths, so maximum 6 SQL queries only
     * @param treeType, Tree Type
     * @param includedNodeIds, Nodes to create a tree
     * @param matchingNodeIds, children nodes
     */
    private static void findMatchingParentNodes(String treeType, Set<String> includedNodeIds, Set<String> matchingNodeIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: matchingNodeIds';
        String parentFieldName = Util.NS+'Node_ID__c';
        String nodeFieldName = 'Name';
        if (isContentTree) {
            queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Content__c, '+Util.NS+'Site_Content_Category__c, '+Util.NS+'Type__c From ' + mTypeToSObj.get(treeType) + ' Where Id IN: matchingNodeIds';
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
        }

        for (String nodeId : matchingNodeIds) {
           includedNodeIds.add(nodeId);
        }
        Set<String> parentIds = new Set<String>();
        for(SObject sobj: database.query(queryStr)){
            if(isContentTree && sobj.get('Type__c')+''== 'Dart - ContentCategory') {
                parentFieldName = Util.NS+'Site_Content_Category__c';
            }
            if (sobj.get(parentFieldName) == null) {
                includedNodeIds.add(sobj.id);
                continue;
            }
            String parentId = String.valueOf(sobj.get(parentFieldName));
            parentIds.add(parentId);
        }
        if (!parentIds.isEmpty()) {
            findMatchingParentNodes(treeType, includedNodeIds, parentIds);
        }
    }

    /**
     * To maintain the selection behaviour in tree, we have to include other nodes in same level to result
     * @param treeType, Tree Type
     * @param includedNodeIds, more nodes to create a tree
     */
    private static void includeNodesInSameLvl(String treeType, Set<String> includedNodeIds) {
        Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;
        String queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where '+Util.NS+'Node_ID__c IN: includedNodeIds';
        String parentFieldName = Util.NS+'Node_ID__c';
        String nodeFieldName = 'Name';
        if (isContentTree) {
            queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Content__c From ' + mTypeToSObj.get(treeType) + ' Where '+Util.NS+'Content__c IN: includedNodeIds';
            parentFieldName = Util.NS+'Content__c';
            nodeFieldName = Util.NS+'DartName__c';
        }
        Set<String> parentIds = new Set<String>();
        for(SObject sobj: database.query(queryStr)){
          includedNodeIds.add(sobj.id);
        }
    }

    /**
     * Do Save Tree to SObject Records
     * @param treeType, Tree Type
     * @param textSearch, Keyword to find
     * @param lineItemId, quoteLine Id
     * @return List<DTOTreeItem>
     */
    @AuraEnabled
    public static RemoteResponse doSearchTree (String treeType, String textSearch, String lineItemId) {
        try{
            QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, Product2.Content__c, Product2Id From QuoteLineItem Where Id =: lineItemId];
            Set<String> matchingNodeIds = new Set<String>();
            Boolean isContentTree = treeType == ADUNIT_TREE_TYPE;

            String lmt = '';
            String queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c From ' + mTypeToSObj.get(treeType) + ' Where Name like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by Name' + lmt;
            if (isContentTree) {
                queryStr = 'Select '+Util.NS+'DartName__c, Id, '+Util.NS+'Type__c, '+Util.NS+'Content__c From ' + mTypeToSObj.get(treeType) + ' Where '+Util.NS+'DartName__c like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by '+Util.NS+'DartName__c' + lmt;
            }
            if(treeType == GEO_TREE_TYPE){
                queryStr = 'Select Id, Name, '+Util.NS+'Node_ID__c, '+Util.NS+'Type__c From ' + mTypeToSObj.get(treeType) + ' Where Name like \'%' + String.escapeSingleQuotes(textSearch) + '%\' order by Name' + lmt;
            }
            for(SObject sobj: database.query(queryStr)){
                matchingNodeIds.add(sobj.id);
            }
            Set<String> treeNodeIds = new Set<String>();
            List<DTOTreeItem> lstTree = new List<DTOTreeItem>();
            Set<String> nodesToDisplay = new Set<String>();
            if (!matchingNodeIds.isEmpty()) {
                findMatchingParentNodes(treeType, treeNodeIds, matchingNodeIds);
                nodesToDisplay.addAll(treeNodeIds);
                includeNodesInSameLvl(treeType, treeNodeIds);
                lstTree = createTreeFromNodeIds(treeType, treeNodeIds, nodesToDisplay, quoteLine.Product2.Content__c);
            }
            if (isContentTree && !lstTree.isEmpty()) {
               fetchContentTreeWithPlacement(treeType, lstTree[0].treeId, 1, lstTree, false);
            }
            List<Object> objs = new List<Object>();
            objs.add(lstTree);
            RemoteResponse response = new RemoteResponse();
            response.content = objs;
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            return response;
        }catch(exception e){ return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
    }

    

    
    /**
     * Do Save Tree to SObject Records
     * @param treeType, Tree Type
     * @param lineItemId, QuoteLineItem Id
     * @param lstTobeSaved, String to save
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse doSaveRecords(String treeType, String lineItemId, String lstTobeSaved){
        try{
            QuoteLineItem quoteLine = [Select Product2.Name, Targeting__c, quote.IO__c, Product2Id From QuoteLineItem Where Id =: lineItemId];

            String targetId = quoteLine.Targeting__c;
            //system.debug('xxxxxxxxxSavingTargeting:'+targetId);
            if (quoteLine.Targeting__c == null) {
                Targeting__c tg = new Targeting__c(Description__c = quoteLine.Product2.Name + ' Targeting');
                insert tg;
                targetId = tg.Id;
                quoteLine.Targeting__c =  tg.Id;
            }
            String nodeDes = doSaveRecordsTargetingTree(treeType, targetId, lstTobeSaved);
            
            RemoteResponse response = new RemoteResponse();
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.message = nodeDes;

            return response;
        }catch(exception e){ return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
    }


    @AuraEnabled
    public static RemoteResponse saveTemplate(String targetId, String assoToSave){
        try{

            Map<String,String> result = new Map<String, String>();
            Map<String,Object> mapAssoToSave = (Map<String,Object>) JSON.deserializeUntyped(assoToSave);
            for(String treeType:  mapAssoToSave.keySet() ) {
                String nodeDes = '';
                String assoString = (String) mapAssoToSave.get(treeType);
                if( LPC_TargetingTreeSelectorController.treeTypes.contains(treeType) ){
                    nodeDes = LPC_TargetingTreeSelectorController.doSaveRecordsTargetingTree(treeType, targetId, assoString );
                } else if( treeType =='FC' ) {
                    List<TargetingFrequencyAssociation__c> lstTarFre = (List<TargetingFrequencyAssociation__c>) JSON.deserialize(assoString, List<TargetingFrequencyAssociation__c>.class);
                    LPC_FrequencyCappingController.saveFrequencyCappingTemplate( targetId, lstTarFre);
                } else if ( 'TargetingTime' == treeType) {
                    List<Object> timesSelected = (List<Object>) JSON.deserializeUntyped(assoString);
                    Map<String, String> mTimeSelected = new Map<String, String>();
                    for( Object  t :  timesSelected){
                        Map<String, Object> timeSelected = (Map<String, Object>) t;
                        mTimeSelected.put( (String) timeSelected.get('day'), (String) timeSelected.get('daySelected') );
                    }
                    update new Targeting__c(Id=targetId, 
                                    DFP_Time_Monday__c = mTimeSelected.get('Monday'),
                                                        DFP_Time_Tuesday__c = mTimeSelected.get('Tuesday'),
                                                        DFP_Time_Wednesday__c = mTimeSelected.get('Wednesday'),
                                                        DFP_Time_Thursday__c = mTimeSelected.get('Thursday'),
                                                        DFP_Time_Friday__c = mTimeSelected.get('Friday'),
                                                        DFP_Time_Saturday__c = mTimeSelected.get('Saturday'),
                                                        DFP_Time_Sunday__c = mTimeSelected.get('Sunday'));
                }
                
                result.put(treeType, nodeDes);
            }

            RemoteResponse response = new RemoteResponse();
            response.statusCode = RemoteResponse.STATUSCODE_OK;
            response.content = result;

            return response;
        }catch(exception e){ return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
    }
    

    /**
     * Do Save Tree Template to SObject Records
     * @param treeType, Tree Type
     * @param lineItemId, QuoteLineItem Id
     * @param lstTobeSaved, String to save
     * @return RemoteResponse
     */
    @AuraEnabled
    public static RemoteResponse doSaveRecordsTempleate(String treeType, String targetId, String lstTobeSaved){
        try{

            String nodeDes = doSaveRecordsTargetingTree(treeType, targetId, lstTobeSaved);

            RemoteResponse response = new RemoteResponse();
            response.statusCode = RemoteResponse.STATUSCODE_OK;

            return response;
        }catch(exception e){ return new RemoteResponse(e.getStackTraceString() + ' ' + e.getMessage(), RemoteResponse.STATUSCODE_ERROR); }
    }

    /**
     * Do Save Records of Targeting Tree
     * @param treeType, Tree Type
     * @param targetId, Targeting__c Id
     * @param lstTobeSaved, String to save
     * @return String
     */
    public static String doSaveRecordsTargetingTree(String treeType, String targetId, String lstTobeSaved){
        try{
            List<DTOTreeItem> lstDto = (List<DTOTreeItem>) JSON.deserialize(lstTobeSaved, List<DTOTreeItem>.class);

            List<String> nodeDes = new List<String>();
            Set<String> assoNotToDelete = new Set<String>();

            if (treeType == DEVICE_TREE_TYPE || treeType == BROWSER_TREE_TYPE || treeType == OS_TREE_TYPE) {
                List<TargetingDeviceAssociation__c> lstTargs = new List<TargetingDeviceAssociation__c>();
                for(DTOTreeItem dto : lstDto){
                    String conId = dto.treeId;
                    TargetingDeviceAssociation__c tca = new TargetingDeviceAssociation__c(Targeting__c = targetId ,Device__c  = conId , TargetDevice__c  = targetId + conId);
                    lstTargs.add(tca);
                    assoNotToDelete.add(tca.TargetDevice__c);
                    nodeDes.add(dto.treeName);
                }
                if(!lstTargs.isEmpty())  upsert lstTargs TargetDevice__c ;
                if(treeType == DEVICE_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c <>: OS_TREE_TYPE And Device__r.DFP_API_Name__c <>: BROWSER_TREE_TYPE];
                else if(treeType == BROWSER_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c =: BROWSER_TREE_TYPE];
                else if(treeType == OS_TREE_TYPE) delete [Select Id From TargetingDeviceAssociation__c Where Targeting__c= :targetId And (TargetDevice__c Not In :assoNotToDelete) AND Device__r.DFP_API_Name__c =: OS_TREE_TYPE];

            }
            if (treeType == CONNECTION_TREE_TYPE || treeType == BANDWIDTH_TREE_TYPE) {
                List<TargetingConnectionAssociation__c> lstTargs = new List<TargetingConnectionAssociation__c>();
                for(DTOTreeItem dto : lstDto){
                    String conId = dto.treeId;
                    TargetingConnectionAssociation__c tca = new TargetingConnectionAssociation__c(Targeting__c = targetId ,Connection__c  = conId , TargetConnection__c  = targetId + conId);
                    lstTargs.add(tca);
                    assoNotToDelete.add(tca.TargetConnection__c);
                    nodeDes.add(dto.treeName);
                }
                if(!lstTargs.isEmpty())  upsert lstTargs TargetConnection__c ;
                if (treeType == CONNECTION_TREE_TYPE) delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c =: targetId And (TargetConnection__c Not In :assoNotToDelete) AND Connection__r.DFP_API_Name__c <> 'BandwidthGroup' ];
                else if(treeType == BANDWIDTH_TREE_TYPE) delete [Select Id From TargetingConnectionAssociation__c Where Targeting__c =: targetId And (TargetConnection__c Not In :assoNotToDelete) AND Connection__r.DFP_API_Name__c = 'BandwidthGroup' ];

            }
            if (treeType == GEO_TREE_TYPE) {
                List<TargetingGeographyAssociation__c> lstTargs = new List<TargetingGeographyAssociation__c>();
                for(DTOTreeItem dto : lstDto){
                    String conId = dto.treeId;
                    TargetingGeographyAssociation__c tca = new TargetingGeographyAssociation__c(Targeting__c = targetId ,Geography__c  = conId , TargetGeography__c  = targetId + conId);
                    lstTargs.add(tca);
                    assoNotToDelete.add(tca.TargetGeography__c);
                    nodeDes.add(dto.treeName);
                }
                if(!lstTargs.isEmpty())  upsert lstTargs TargetGeography__c ;
                delete [Select Id From TargetingGeographyAssociation__c Where Targeting__c =: targetId And (TargetGeography__c Not In :assoNotToDelete) ];

            }
            if (treeType == ADUNIT_TREE_TYPE) {
                List<TargetingContentAssociation__c> lstTargs = new List<TargetingContentAssociation__c>();
                List<PlacementTargetingAssociation__c> lstPlacesTarget = new List<PlacementTargetingAssociation__c>();
                Map<Id,String> mapDTOTree = new  Map<Id,String>();

                for(DTOTreeItem dto : lstDto){
                    String conId = dto.treeId;
                    String arrTreeType = dto.typeLabel.substringBetween('(',')');
                    String paymentName = dto.treeName.substringBeforeLast('(');
                    if(arrTreeType.contains('ContentCategory')){
                        mapDTOTree.put(dto.treeId,paymentName);
                    }else{

                        TargetingContentAssociation__c tca = new TargetingContentAssociation__c(Targeting__c = targetId ,TargetingContent__c  = conId , Target_Content_Key__c  = targetId + conId);
                        lstTargs.add(tca);
                        assoNotToDelete.add(tca.Target_Content_Key__c);
                    }
                    nodeDes.add(dto.treeName);
                }
                List<Content__c> newLstContent = new List<Content__c>();
                predefineId = [SELECT Predefined_Adunit__r.Id,Predefined_Placement__r.Id FROM QuoteLineItem WHERE Targeting__c =: targetId limit 1];

                if(!mapDTOTree.isEmpty()){
                    List<Content__c> lstContent = [SELECT Id,Name,(SELECT Id,Name, Content_Category_Site__c FROM Placement__r) FROM Content__c WHERE Id In: mapDTOTree.keySet()];
                    //Placement Predefine  Id and Adunit Predefine Id
                    for(content__c con :lstContent){
                        if(con.Placement__r.isEmpty()){
                            newLstContent.add(con);
                        }else{
                                PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = targetId,Placement__c = con.Placement__r[0].Id);
                                lstPlacesTarget.add(pta);
                        }
                    }
                }

                if(!newLstContent.isEmpty()){
                    List<Placement__c> lstPlacement = createPlacement(newLstContent,mapDTOTree);
                    for(Placement__c place : lstPlacement){
                        PlacementTargetingAssociation__c pta = new PlacementTargetingAssociation__c(Targeting__c = targetId,Placement__c = place.Id );
                        lstPlacesTarget.add(pta);
                    }
                }

                if(!lstPlacesTarget.isEmpty())  upsert lstPlacesTarget ;

                QuoteLineItem quoteLine;
                if(!predefineId.isEmpty()){
                    if(checkPredefinePlacementOppLine(lstPlacesTarget,predefineId[0]) == false){
                         quoteLine = [SELECT Id FROM QuoteLineItem WHERE Targeting__c =: targetId limit 1];
                         quoteLine.Predefined_Placement__c = null;
                    }
                }
                delete [Select Id From PlacementTargetingAssociation__c Where Targeting__c =: targetId And Id Not In :lstPlacesTarget ]; //And Placement__c <>: predefineId[0].Predefined_Placement__r.Id

                if(!lstTargs.isEmpty())  upsert lstTargs Target_Content_Key__c ;
                if(checkPredefineAdunitQuoteLine(lstTargs,predefineId[0]) == false){
                     if(quoteLine == null) quoteLine = [SELECT Id FROM QuoteLineItem WHERE Targeting__c =: targetId limit 1];
                     quoteLine.Predefined_Adunit__c = null;
                }
                if(quoteLine != null) update quoteLine;
                //MN-10032021 - We are now disable edit configuration for Placement/Ad Unit on Targeting screen => no need to deleting any records cos we will always using existing records that created from US-0009114
                //delete [Select Id From TargetingContentAssociation__c Where Targeting__c =: targetId And (Target_Content_Key__c Not In :assoNotToDelete)]; //And TargetingContent__c <>: predefineId[0].Predefined_Adunit__r.Id
                
                // -------
                List<String> plcNames = new List<String>();
                for(Placement__c p : DartUtil.getPlacementTargeting(targetId)) plcNames.add(p.Name);
                String joinPlacements = plcNames.isEmpty() ? '' : String.join(plcNames, ', ');
                update new Targeting__c(Id=targetId, Placements__c=joinPlacements);
            }
            return String.join(nodeDes, VAL_SEPARATOR);
        }catch(exception e){ system.debug(e.getStackTraceString() + ' ' + e.getMessage()); return ''; }
    }

    private static Boolean checkPredefinePlacementOppLine(List<PlacementTargetingAssociation__c> lstPlaceTargeting,QuoteLineItem quoteLine){
        if(!lstPlaceTargeting.isEmpty()){
            for(PlacementTargetingAssociation__c obj : lstPlaceTargeting){
                if(obj.Placement__c == quoteLine.Predefined_Placement__c){
                    return true;
                }
            }
        }
        return false;
    }

    private static Boolean checkPredefineAdunitQuoteLine(List<TargetingContentAssociation__c> lstAdunitTargeting,QuoteLineItem quoteLine){
        if(!lstAdunitTargeting.isEmpty()){
            for(TargetingContentAssociation__c obj : lstAdunitTargeting){
                if(obj.TargetingContent__c == quoteLine.Predefined_Adunit__c){
                    return true;
                }
            }
        }
        return false;
    }

   /**
    * Create New Placement__c If Content__c don't have
    */
    private static List<Placement__c> createPlacement(List<Content__c> lstContent,Map<Id,String> mapDTOTree){
        List<Placement__c> lstPlacement = new List<Placement__c>();
        for(Content__c con : lstContent){
            Placement__c newPlacement = new Placement__c();
            newPlacement.Name = mapDTOTree.get(con.Id);
            newPlacement.Content_Category_Site__c = con.Id;
            newPlacement.Dart_ID__c = Decimal.valueOf(con.Name);
            //newPlacement.CurrencyIsoCode = userInfo.getDefaultCurrency();
            lstPlacement.add(newPlacement);
        }

        try {
            insert lstPlacement;
        } catch(Exception ex) {}

        return lstPlacement;
    }

    /**
     * parse CSV content 
     */
    private static List<List<String>> CSVParser(String csvContent){
        List<List<String>> csv = new List<List<String>>();
        for(String row:csvContent.split('[\r\n]')){
            csv.add(row.split(','));
        }
        
        return csv;
    }

    private static List<String> mergeCSV(String csvContent){
        List<String> csvCell = new List<String>();
        for(List<String> row :CSVParser(csvContent)){
            csvCell.addAll(row);
        }
        return csvCell;
    }

    /**
     * TreeItem Wrapper Class
     */
    public class DTOTreeItem {
        @AuraEnabled
        public Integer pos{get;set;}
        @AuraEnabled
        public String treeId{get;set;}
        @AuraEnabled
        public String treeName{get;set;}
        @AuraEnabled
        public String parentId{get;set;}
        @AuraEnabled
        public Integer level{get;set;}
        @AuraEnabled
        public String selectMode{get;set;}
        @AuraEnabled
        public Boolean isContainsChilds{get;set;}
        @AuraEnabled
        public Boolean isSecretNode{get;set;}
        @AuraEnabled
        public String typeLabel{get;set;}

        public Boolean isPlacement {get;set;}
    }
}