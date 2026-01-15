/*********************************************************************************************************************************
@ Class:          CustomApprovalActionController
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        Shared Controller for LC: CustomApprovalDetailVeiw, CustomApprovalRequest, CustomItemToApprove
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 26.02.2018 / Vadhanak Voun / Created the class.
*********************************************************************************************************************************/
public without sharing class CustomApprovalActionController {
    
    /***********************************************************************************************************************************
    @ Method:       getCurrentUserInfo 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Method to get current userid or is current user is admin
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of ProcessInstances
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 15.03.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> getCurrentUserInfo()
    {
        Map<String,String> mapUser = new Map<String,String>();
        mapUser.put('isAdmin',(Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID)+'');
        mapUser.put('currentUserId',Userinfo.getUserId()); 
         
         
         return mapUser;
    }
    
    /***********************************************************************************************************************************
    @ Method:       getApprovalHistory2 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Method to get all realated Approval hostories by TargetObjectId
    @               With more fields as needed
    @ Parameter:    parentId: TargetObjectId
    @               limitClause: limit clause when showing in recordhome or view all
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of ProcessInstances
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static List<ItemData> getApprovalHistory2(String parentId, String limitClause,Boolean pendIngOnly)
    {
        String soqlStepAndItemNew = EBH_ConstantsUtility.soqlStepAndItem.replace('%where1%',pendIngOnly?' WHERE IsPending=true ':'');
        //home page component, not id reference
        String additionalCondition = String.isBlank(parentId)?' WHERE Status=\'Pending\'':' where TargetObjectId=:parentId order by CreatedDate desc, Id DESC '+limitClause;
        List<ProcessInstance> listInst = doGetApprovalHistory(soqlStepAndItemNew,parentId,additionalCondition);
        List<ItemData> listItem = new List<ItemData>();
        
        User recentUser = null; 
        String additionalConditionRecent = ' WHERE TargetObjectId=:parentId AND Status=\'Approved\' Order by LastModifiedDate desc limit 1';
        List<ProcessInstance> listInstRecent = doGetApprovalHistory(soqlStepAndItemNew,parentId,additionalConditionRecent);
        for(ProcessInstance ints : listInstRecent)
        {
            recentUser = ints.LastActor;
             
        }
        Set<ID> records= new Set<ID>();
        
        //system.debug('>>>listInst: '+listInst);
        for(ProcessInstance ints : listInst)
        {
            if(ints.StepsAndWorkitems!=null && !ints.StepsAndWorkitems.isEmpty())
            {
                //pendingOnly: list at home component (ItemToApprove) only show their own item to approve
                //NK:18/10/2018: fixed for multiple requests- cause the item to approve missing some items
                Boolean ownPendingApproval =  false;
                for(ProcessInstanceHistory  h: ints.StepsAndWorkitems)
                {
                    //system.debug('>>>ints.StepsAndWorkitems: '+ints.StepsAndWorkitems);
                    if(pendIngOnly && h.ActorId == UserInfo.getUserId()) //pendIngOnly = requested from Home Item for Approve
                    {
                    	ownPendingApproval = true;
                    }
                }
                ItemData iData = new ItemData();
                iData.proInstance = ints;
                iData.sobjectType = ints.TargetObjectId.getSObjectType().getDescribe().getName();
                iData.sobjectTypeLabel =  ints.TargetObjectId.getSObjectType().getDescribe().getLabel();
                iData.recentApprover = recentUser;
                iData.rec = ints.TargetObjectId;
                records.add(ints.TargetObjectId);
                
                if(pendIngOnly && ownPendingApproval)
                {
                	listItem.add(iData);
                }else if(!pendIngOnly)
                {
                	listItem.add(iData);
                }
            }
            
        }
        Map<ID, ID> ownerIDMap = new Map<ID, ID>();
        for(Contract con: [SELECT Id,ownerId from Contract where Id IN :records]){
            
            ownerIdMap.put(con.Id, con.OwnerId);
            
        }
        
        for(ItemData itm: listItem){
            
            itm.owner = ownerIdMap.get(itm.rec);
        }
        //to get Owner from different objects
        //Approval can have multiple objects
        Map<String,Set<String>> mapSobject = new Map<String,Set<String>>(); 
        for(ItemData iData : listItem)
        {
             if(!mapSobject.containsKey(iData.sobjectType))
             {
                mapSobject.put(iData.sobjectType,new Set<String>());
             }
             mapSobject.get(iData.sobjectType).add(iData.proInstance.TargetObjectId);
        }
        
        //in case, multiple object approval, query from each type
        Map<String,Sobject> mapTargetObject = new Map<String,Sobject>();
        for(String sobjectType : mapSobject.keySet())
        {
            Set<String> setId = mapSobject.get(sobjectType);
            for(Sobject obj: Database.query('Select Id,Name,Owner.Id,Owner.Name From '+sobjectType+' Where Id IN:setId'))
            {
                mapTargetObject.put(obj.get('Id')+'',obj);
            }
        } 
        for(ItemData iData : listItem)
        {
             iData.targetObject = mapTargetObject.get(iData.proInstance.TargetObjectId);
               System.debug('&&&&&&&'+iData.targetObject ); 
        }
         
        return listItem;
         
    }
    
  
    
    /***********************************************************************************************************************************
    @ Method:       doGetApprovalHistory 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      shared method to get ProcessInstances
    @ Parameter:    soql: soql to be executed
    @               parentId: targetObjectId
    @               whereClauseAndlimitClause: additional where and limit clause
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:        List of ProcessInstances
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    private static List<ProcessInstance> doGetApprovalHistory(String soql,String parentId,String whereClauseAndlimitClause)
    {
        //system.debug('>>>: '+soql+ whereClauseAndlimitClause);
        return Database.query(soql+ whereClauseAndlimitClause);
    }
    
    /***********************************************************************************************************************************
    @ Method:       doAction 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Generic action to process action: Approve, Reject, or Removed.
    @ Parameter:    targetObjectId: record id of the object to be approved/rejected/recalled
    @               comments:  comments for the action
    @               actionType:   Approve, Reject, or Removed.
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      Map of result
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    private static Map<String,String> doAction(String targetObjectId,String comments,String actionType)
    {
        Map<String,String> mapResult = new Map<String,String>();
        mapResult.put('action',actionType);
        Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
        String newWere = generateSubWhere(actionType);//isAdmin?' WHERE IsPending=true ':' WHERE IsPending=true AND ActorId=\''+Userinfo.getUserId()+'\' ';
        String soqlStepAndItemNew = EBH_ConstantsUtility.soqlStepAndItem.replace('%where1%',newWere);
        String whereClasue = ' where TargetObjectId=:parentId AND Status=\'Pending\' ';
        //System.debug('>>>targetObjectId: '+targetObjectId);
        //System.debug('>>>:'+soqlStepAndItemNew+'--'+whereClasue);
        List<ProcessInstance> listInst =  doGetApprovalHistory(soqlStepAndItemNew,targetObjectId,whereClasue);
        //System.debug('>>>listInst[0].StepsAndWorkitems: '+listInst[0].StepsAndWorkitems); if(true)return null;
        String itemIdToAction = listInst[0].StepsAndWorkitems[0].Id ;
        
        
        Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
        pwr.setComments(comments);
        pwr.setAction(actionType);
        
        // Use the ID from the newly created item to specify the item to be worked
        pwr.setWorkitemId(itemIdToAction);
        
        // Submit the request for approval
        try
        {
            Approval.ProcessResult result2 =  Approval.process(pwr);
            mapResult.put('status','ok');
        }catch(Exception ex)
        {
            mapResult.put('status','ko');
            mapResult.put('error',ex.getMessage());
        }
        
        return mapResult;
    }
    
    /***********************************************************************************************************************************
    @ Method:       generateSubWhere 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      generate where clause for sub query (item) for admin and user
    @				Recall	: admin + submitter
    @				Else	: admin + Actor 
    @ Parameter:    actionType:  Approve, Reject, Removed
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      String of where clause for sub query
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 13.08.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    private static String generateSubWhere(String actionType)
    {
    	Boolean isAdmin = (Userinfo.getprofileId()==EBH_ConstantsUtility.ADMIN_PROFILE_ID);
    	String newWere = '';
    	if('Removed' == actionType) //Recall
    	{
    		newWere = ' WHERE IsPending=true ';
    	}else
    	{
    		//Approve, Reject
    		newWere = isAdmin?' WHERE IsPending=true ':' WHERE IsPending=true AND ActorId=\''+Userinfo.getUserId()+'\' ';
    	}
        
        return newWere;
    }
    
    /***********************************************************************************************************************************
    @ Method:       doApprove 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Approve the request
    @ Parameter:    targetObjectId: record id of the object to be approved
    @               comments:  comments for the action
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      Map of result
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> doApprove(String targetObjectId,String comments)
    {
        return doAction(targetObjectId,comments,'Approve');
    }
    
    /***********************************************************************************************************************************
    @ Method:       doReject 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Reject the request
    @ Parameter:    targetObjectId: record id of the object to be rejected
    @               comments:  comments for the action
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      Map of result
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> doReject(String targetObjectId,String comments)
    {
        return doAction(targetObjectId,comments,'Reject');
    }
    
    /***********************************************************************************************************************************
    @ Method:       doRecall 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Recall (remove) the request
    @ Parameter:    targetObjectId: record id of the object to be recalled
    @               comments:  comments for the action
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      Map of result
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,String> doRecall(String targetObjectId,String comments)
    {
        return doAction(targetObjectId,comments,'Removed');
    }
    
    /***********************************************************************************************************************************
    @ Method:       getItemDetail 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      get the detail record for a request fro viewing
    @ Parameter:    instId: instance id
    @               itemId: workitem id
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns:      ItemData
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static ItemData getItemDetail(String instId,String itemId)
    {
        String soqlStepAndItemNew = EBH_ConstantsUtility.soqlStepAndItem.replace('%where1%',' where Id=:itemId');
        List<ProcessInstance>   listInstance = Database.query(soqlStepAndItemNew+'   where Id=:instId');
        
        ItemData iData = new ItemData();
        iData.proInstance = listInstance[0];
        String recordId =  iData.proInstance.TargetObjectId;
        iData.sobjectType = listInstance[0].TargetObjectId.getSObjectType().getDescribe().getName();
        iData.sobjectTypeLabel =  listInstance[0].TargetObjectId.getSObjectType().getDescribe().getLabel();
//      Contract c = Database.query(EBH_ConstantsUtility.soqlContract + ' Where Id=:recordId');
        Sobject c = Database.query('Select Id,Name,ownerId, Owner.Id,Owner.Name From '+iData.sobjectType+' Where Id=:recordId'); 
        iData.targetObject = c;
        //iData.owner = String.valueOf(c.get('owner'));  // Modified 2018-04-25 by DHE
        iData.owner = String.valueOf(c.get('ownerID'));
        
        //System.debug('>>>iData:'+iData);
        
        return iData;
        
    }
    
    /***********************************************************************************************************************************
    @ Class:       ItemData (innternal) 
    @ Version:      1.0
    @ Author:       Vadhanak Voun (vadhanak.voun@gaea-sys.com)
    @ Purpose:      Wrapper
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 27.02.2018 / Vadhanak Voun / Created the Method.
    ***********************************************************************************************************************************/ 
    public class ItemData{
        @AuraEnabled
        public ProcessInstance proInstance {get;set;}
        @AuraEnabled
        //public Contract targetObject {get;set;}
        public Sobject targetObject {get;set;} // generic
        
         @AuraEnabled
        public String owner{get;set;}
        
         @AuraEnabled
        public String rec{get;set;}
        
        @AuraEnabled
        public String sobjectType {get;set;}
        @AuraEnabled
        public String sobjectTypeLabel {get;set;}
        
        @AuraEnabled
        public User recentApprover {get;set;}
        
        @AuraEnabled
        public Integer num {get;set;} 
        
        public ItemData(){}
    }
     
}