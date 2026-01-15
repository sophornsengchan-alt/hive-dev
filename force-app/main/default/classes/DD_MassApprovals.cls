/*********************************************************************************************************************************
@ Class:          DD_MassApprovals
@ Version:        1.0
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  10.08.2023 / Loumang SENG / US-0013318 - New US Deals Contract Approver Queue 
@               :  11.08.2023 / SRONG TIN / US-0012998 - Rev Rollup filter on the Mass Deal Statement Approvals page
@               :  25.09.2023 / Loumang SENG / US-0014109 - Record type filter on Deals Mass Approvals page
*********************************************************************************************************************************/
public without sharing class DD_MassApprovals {

    // list of fields to displayed as Link
    // ensure all field listed are reference (ID)
    // Will move to Fieldset
    //LA-25-09-2023-US-0014109: mapping 'RecordTypeId' => 'RecordType.Name'
    public static Map<String,String> referencesfields = new Map<String,String> {'EBH_BusinessName__c' => 'EBH_BusinessName__r.Name', 'eBay_Seller__c' => 'eBay_Seller__r.Name','RecordTypeId' => 'RecordType.Name'};
  
    public String objectName {get;set;}
    public String recordType {get;set;}

    //private static String DAILY_DEALS_FINANCE_API = 'Daily_Deals_Finance';//LA-10-08-2023-US-0013318
    private static String US_DEALS_CONTRACT_APPROVER_API = 'US_Deals_Contract_Approvers';//LA-10-08-2023-US-0013318
    private static String CA_DEALS_FINANCE_API = 'CA_Deals_Financial_Approvers';//LA-10-08-2023-US-0013318
    private final static String DEAL_SITE_CA_API_NAME = '2';

    private final static Set<String> SET_STATUS_MASSAPPROVAL = new Set<String>{'Internally Approved','Internally Rejected'};
    //loumang:01-11-2021: US-0010649
    private final static Set<String> SELLER_PRIMARY_SITE = new Set<String>{'Canada','Canada (French)'};

    private final static Set<String> SET_RECORDTYPE_DS = new set<String>{'Promotion_Manager_Deals','Subsidised_Deals'};//LA-25-09-2023-US-0014109

  
    public DD_MassApprovals() {
      objectName = apexpages.currentpage().getparameters().get('object');
      recordType = apexpages.currentpage().getparameters().get('recordtype');
  
    //   System.debug('objectName ========= ' + objectName);
    //   System.debug('recordType ==========' + recordType);
    }
    // SRONG TIN 11/08/2023 US-0012998 
    @AuraEnabled
    public static Map<String, Object> initData(String objectName,String recordType, String fieldSetName, String sortField, Boolean isAsc, String search) {
  
          Map<String, Object> mpRes = new Map<String, Object>();
          Set<Id> allRecordIds = new Set<Id> ();
          try {
              // SRONG TIN 11/08/2023 US-0012998 
              mpRes.put('ListDealWrapper', loadData(objectName, recordType,  fieldSetName,sortField,  isAsc, allRecordIds, search));
              mpRes.put('Mass_Approval_Table_Columns', ApexUtil.getFieldSet(objectName,fieldSetName));
              mpRes.put('chunkSize', Integer.valueOf(Label.DEAL_INTERNALLYAPPROVED_CHUNK_SIZE_LIMIT)); // Sophal / 27.08.2021 / US-0010194
  
          }catch(Exception e){
              //System.debug(LoggingLevel.Error, 'ERROR ' + e);
              AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());
              auraError.setMessage(e.getMessage() + e.getStackTraceString());
              throw auraError;
          }
  
          return mpRes;
       }
  
  
       /**
       *
       */
       public static List<ItemWrapper> loadData(String objectName,String recordType,  String fieldSetName, String sortField, Boolean isAsc, Set<Id> allRecordIds, String search) {
          List<ItemWrapper> res = new List<ItemWrapper>();
  
          SObjectType objToken = Schema.getGlobalDescribe().get(objectName);
          //System.debug('objToken>>>'+objToken);
          Schema.DescribeSObjectResult d = objToken.getDescribe();
          //System.debug('d>>>'+d);
          //System.debug('d>>>'+d.fieldSets);
          Map<String, Schema.FieldSet> FsMap = d.fieldSets.getMap();
          //System.debug('FsMap>>>'+FsMap);
  
          String query = 'SELECT ';
          for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) {
              String fieldname = f.getFieldPath();
  
              query += fieldname + ', ';
              if(referencesfields.containsKey(fieldname)) query += referencesfields.get(fieldname) + ', ';
          }
  
          // load reference if any
          /*for (String fr : referencesfields.values()) {
              query += fr + ', ';
          }*/
  
          // load all items to be approved for the connected user
          Set<Id> targets = new Set<Id>();
  
          // key : ActorId,
          Map<Id,Set<Id>> targetsqueues = new Map<Id,Set<Id>>();
  
          List<ProcessInstanceWorkItem> workItems = [
              SELECT ActorId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkItem
              WHERE ProcessInstance.Status in ('Pending','In Approval')];
  
  
          for (ProcessInstanceWorkItem workItem: workItems) {
  
              String actorid = '' + workItem.ActorId;
              
              //System.debug('>>>UserInfo ' +UserInfo.getUserId());
              //System.debug('>>>actorid ' +actorid);
  
              if (workItem.ActorId==UserInfo.getUserId()) {
                  targets.add(workItem.ProcessInstance.TargetObjectId);
              }
              else if (actorid.startsWith('00G')) { // actor is a queue
                  Set<Id> objs = targetsqueues.get(workItem.ActorId);
                  if (objs==null) {
                      objs = new Set<Id>();
                  }
                  objs.add(workItem.ProcessInstance.TargetObjectId);
                  targetsqueues.put(workItem.ActorId, objs);
              }
  
          }
            //System.debug('>>>targetsqueues ' +targetsqueues);
          // check if the current user belong to the queue
          if (!targetsqueues.keyset().isEmpty()) {
  
              for (Group g :  [Select g.Type, g.Id, (Select UserOrGroupId From GroupMembers where UserOrGroupId=:UserInfo.getUserId())
                              From Group g
                              where Type='Queue' and
                                  Id in : targetsqueues.keyset()]) {
  
                      // the user belong to this group
                      if (g.GroupMembers.size()>0) {
                          targets.addAll(targetsqueues.get(g.Id));
                      }
              }
  
  
          }
          //System.Debug('### recordtype'+recordType);
          query += 'Id From ' + objectName + ' where ';
          
          // Acmatac SEING, 17/03/2022 US-0011204 - Use binding variable instead of dynamic
          //if(recordType != null && recordType != '')query += 'RecordType.DeveloperName =\'' + recordType + '\' and ';
          if(recordType != null && recordType != '')query += ' RecordType.DeveloperName =:recordType and ';
          // SRONG TIN 11/08/2023 US-0012998 
          if(String.isNotBlank(search))query += search;
           
          //System.debug('>>>query ' +targets.isEmpty());
          if (targets.isEmpty()) return  res;
  
  
          String queryin='';
          for(Id i : targets) {
              queryin += '\'' + i + '\',';
          }
          queryin = queryin.removeEnd(',');
          queryin = '(' + queryin + ')';
          query = query + ' id in ' + queryin;
  
          
  
          // add the column sorting
          if (!String.isEmpty(sortField)) {
              query = query + ' order by ' +  sortField;
  
              if (isAsc) {
                  query = query + ' ASC';
              }
              else {
                  query = query + ' DESC';
              }
          }
  
          //System.debug('>>> DD_MassApprovals' + query);
  
          for(SObject so: Database.query(query)){
                  ItemWrapper dw = new ItemWrapper();
                  dw.comment =  '';
                  dw.recordId = (String)so.get('Id');
                  dw.checked = false;
  
                  //public List<CellValue> cells {get;set;}
                  dw.cells = new List<CellValue>();
                  for(Schema.FieldSetMember f : FsMap.get(fieldSetName).getFields()) {
  
                      CellValue c = new CellValue();
                      c.celltype = f.getType() + '';
                      // todo format here based on the type
                      //System.debug('>>> f.getFieldPath() ' +f.getFieldPath());
                      String fieldname = f.getFieldPath();
                      c.name = f.getFieldPath();
  
  
                      Object o = so.get(fieldname);
                      if (o!=null) {
                          //System.debug('>>> loadData type ' + f.getType() + ' value ' + o);
                          
                          if (f.getType()==Schema.DisplayType.DateTime) {
                             
                              Datetime dvalue = (DateTime)o;
                              c.value = dvalue.format('MM/dd/yyyy') ;
                          }else if(f.getType()==Schema.DisplayType.Date){
                              Date dvalue = (Date)o;
                              c.value = dvalue.format() ;
                              
                          } else {
                              c.value = '' + o;
                          }
  
                          String reffield = referencesfields.get(fieldname);
                          if (reffield!=null) {
                              String[] refs = reffield.split('[.]');
                              c.value = String.valueOf(so.getSObject(refs[0]).get(refs[1]));
                              c.recordid = '' + o;
                          }
                      }
                      else {
                          c.value = '';
                      }
  
  
                      dw.cells.add(c);
  
                   }
  
                  res.add(dw);
                  allRecordIds.add(dw.recordId);
          }
          return res;
        }

        /*********************************************************************************************************************************************************************
        @ Method:         getDealApprover
        @ Version:        1.0
        @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
        @ Purpose:        US-0008618
        ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
        @ Parameter:	list of ItemWrapper which is the wrapper of Deal records
        ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        @ Change history:  18.11.2020 / Sophal Noch / Created the method.
        ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
        @ Change history:  01.11.2021 / Loumang SENG / US-0010649-[NA Deals] Deals for CA Sellers need to go through CA Approval Process for US Site
        ***********************************************************************************************************************************************************************/
        private static List<User> getDealApprover(List<ItemWrapper> items) {

            Set<Id> setDealId = new Set<Id>();
            Set<Id> setUserId = new Set<Id>();

            for (ItemWrapper dw : items) {
                if (dw.checked) {
                    setDealId.add(dw.recordId);
                }
            }

            Set<String> setApproverQueue = new Set<String>();//LA-10-08-2023-US-0013318
            for(EBH_Deal__c deal : [Select Id,EBH_BusinessName__r.EBH_PrimarySite__c, EBH_DealSiteId__c, Merchant_Approver__c,Director__c From EBH_Deal__c Where Id IN: setDealId]){
                //Loumang:01-11-2021: US-0010649
                if(deal.EBH_DealSiteId__c != DEAL_SITE_CA_API_NAME && !SELLER_PRIMARY_SITE.contains(deal.EBH_BusinessName__r.EBH_PrimarySite__c)){ // 04.06.2021 / Sophal Noch / US-0009606 Ignore CA Deal because CA deals don't need Director__c in second step
                    setApproverQueue.add(US_DEALS_CONTRACT_APPROVER_API);//LA-10-08-2023-US-0013318: add queue for site US
                    if(deal.Director__c != null){
                        setUserId.add(deal.Director__c);
                    }
                }else if(deal.EBH_DealSiteId__c == DEAL_SITE_CA_API_NAME || SELLER_PRIMARY_SITE.contains(deal.EBH_BusinessName__r.EBH_PrimarySite__c)){
                    setApproverQueue.add(CA_DEALS_FINANCE_API);//LA-10-08-2023-US-0013318: add queue for site CA
                }

            }

            if(!setApproverQueue.isEmpty()){
                //LA-10-08-2023-US-0013318: Replace DAILY_DEALS_FINANCE_API with setApproverQueue
                for (GroupMember gm : [Select UserOrGroupId, GroupId FROM GroupMember WHERE Group.Type='Queue' AND Group.DeveloperName IN: setApproverQueue]) {
                    setUserId.add(gm.UserOrGroupId);
                }
            }
            

            List<User> listUser = new List<User> ();
            if(!setUserId.isEmpty()){
                listUser = [Select Id,UserPreferencesReceiveNoNotificationsAsApprover,UserPreferencesReceiveNotificationsAsDelegatedApprover From User WHERE Id IN : setUserId];
            }

            return listUser;
            

        }
  
       @AuraEnabled
       public static String approveRecords(String jsonitems, String objectName) {

            List<ItemWrapper> items;
            List<User> listUser = new List<User>();

            try {
                items =  (List<ItemWrapper>)System.JSON.deserialize(jsonitems,List<ItemWrapper>.class);
                if(objectName == 'EBH_Deal__c') listUser = getDealApprover(items); // US-0008618
            }
            catch(Exception e) {AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());auraError.setMessage(e.getMessage() + e.getStackTraceString());throw auraError;}

    
            try {

                if(items != null){
                    //System.debug('>>> deals' + jsonitems);
                
                    //System.debug('>>> dw.so.get ' + items);
                    SubmitForApprovalController.updateUserNotification(listUser,true);
                    processApproval(items,true,objectName);
                    SubmitForApprovalController.updateUserNotification(listUser,false);
                }

    
            } catch(Exception e) {SubmitForApprovalController.updateUserNotification(listUser,false);AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());auraError.setMessage(e.getMessage() + e.getStackTraceString());throw auraError;}
            return 'Approve';
        }
  
        @AuraEnabled
        public static String rejectRecords(String jsonitems, String objectName) {
            List<ItemWrapper> items;
            List<User> listUser = new List<User>();
            try {
                items =  (List<ItemWrapper>)System.JSON.deserialize(jsonitems,List<ItemWrapper>.class);
                if(objectName == 'EBH_Deal__c') listUser = getDealApprover(items); // US-0008618
            }catch(Exception e) {AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());auraError.setMessage(e.getMessage() + e.getStackTraceString());throw auraError;}

           try {
                if(items != null){

                    SubmitForApprovalController.updateUserNotification(listUser,true);
                    processApproval(items,false,objectName);
                    SubmitForApprovalController.updateUserNotification(listUser,false);
                    
               }
           } catch(Exception e) {SubmitForApprovalController.updateUserNotification(listUser,false);AuraHandledException auraError = new AuraHandledException(e.getMessage() + e.getStackTraceString());auraError.setMessage(e.getMessage() + e.getStackTraceString());throw auraError;}
           return 'Reject';
        }
  
  
       public static void processApproval(List<ItemWrapper> items, Boolean isApproved, String objectName) {
  
          // retrieve the items to approve/reject
          //System.debug('>>> dw.so.get ' + items);
          // comment
          Map<Id, String> mapcomment = new Map<Id, String>();
  
          Set<id> targetids = new Set<id>();
          for (ItemWrapper dw : items) {
              if (dw.checked) {
                  //System.debug('>>> dw.so.get ' + dw);
                  targetids.add(dw.recordId);
                  mapcomment.put(dw.recordId,dw.comment);
              }
          }
  
          //System.debug('>>> targetids ' + targetids);
  
          // load all PI
          Set<Id> pIds = new Set<Id>();
          Map<Id,Id> pitargetidmap = new Map<Id,Id>();
          List<ProcessInstance> pis = [SELECT Id,Status,TargetObjectId FROM ProcessInstance where Status='Pending' and TargetObjectId in :targetids];
  
  
          List<Approval.ProcessWorkitemRequest> allReq = new List<Approval.ProcessWorkitemRequest>();
          for (ProcessInstanceWorkitem pInstanceWorkitemsId:[SELECT Id,ProcessInstanceId, ProcessInstance.Status, ProcessInstance.TargetObjectId
                                                                      FROM ProcessInstanceWorkitem WHERE ProcessInstanceId in :pis]){
              //system.debug(pInstanceWorkitemsId);
              Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();
  
              String comment = mapcomment.get(pInstanceWorkitemsId.ProcessInstance.TargetObjectId);
              if (isApproved) {
                  req2.setComments(comment);
                  req2.setAction('Approve');
              } else {
                  req2.setComments(comment);
                  req2.setAction('Reject');
              }
  
              // item to approve
              req2.setWorkitemId(pInstanceWorkitemsId.Id);
  
              // Add the request for approval
              allReq.add(req2);
          }
  
          //System.debug('>>> allReq ' + allReq);
          Approval.ProcessResult[] result2 =  Approval.process(allReq);
  
          //System.debug('>>> result2 ' + result2);
          // now assert the result and display error
          for (Approval.ProcessResult ap : result2) {
               if (isApproved) {
                  // todo
                   if (!ap.isSuccess()) {
                      throw new MassApprovalException(''+ ap.getErrors());
                   }
                   //System.assert(ap.isSuccess(), 'Result Status:'+ap.isSuccess());
  
              } else {
                  // todo
                  //System.assert(ap.isSuccess(), 'Result Status:'+ap.isSuccess());
                  if (!ap.isSuccess()) {
                      throw new MassApprovalException(''+ ap.getErrors());
                  }
              }
          }

          if (isApproved && objectName == 'EBH_Deal__c') {
            sendEmailToNextApprover(targetids);
          }
        //   else if(!isApproved && objectName == 'EBH_Deal__c'){
        //     reTriggerProBuilderToSendEmail(targetids);
        //   }
          

  
      }

    /*********************************************************************************************************************************************************************
    @ Method:         sendEmailToNextApprover
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0008618
    ---------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:	set id of deal
    ----------------------------------------------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  18.11.2020 / Sophal Noch / Created the method.
    ***********************************************************************************************************************************************************************/
      public static void sendEmailToNextApprover(Set<Id> setDealId) {

        List<ProcessInstanceWorkitem> listPiwi = [SELECT OriginalActorId, processInstance.TargetObjectId FROM ProcessInstanceWorkitem 
            WHERE processInstance.TargetObjectId IN:setDealId 
            AND ProcessInstance.Status = 'Pending'
        ];

        if(!listPiwi.isEmpty()){

            Map<Id, EBH_Deal__c> mapDeal = new Map<Id, EBH_Deal__c>([select id,EBH_Status__c,Merchant_Approver__c, Director__c, EBH_Vertical__c,EBH_Category__c, RecordTypeId from EBH_Deal__c 
                where Id IN: setDealId]
            );
    
            Map<Id,SubmitForApprovalController.UserApprovalDetail> mapUserIdToDeal = new map<Id,SubmitForApprovalController.UserApprovalDetail>(); 
            Set<Id> setApproverIds = new Set<Id>();
            
            // Sophal:07/04/2021:US-0009353 change method from SubmitForApprovalController.getUserApprovalDetail to SubmitForApprovalController.initUserApprovalDetail
            SubmitForApprovalController.initUserApprovalDetail(listPiwi, mapDeal, setApproverIds, mapUserIdToDeal); //US-0008618 reuse from other class method
            if(!Test.isRunningTest()){ SubmitForApprovalController.sendEmaiToApprovers(setApproverIds,mapUserIdToDeal);} //US-0008618 reuse from other class method

            

        }
        // else{
        //     reTriggerProBuilderToSendEmail(setDealId);
        // }


      }

    //   @future
    //   public static void reTriggerProBuilderToSendEmail(Set<Id> setDealId) {
    //     // Sophal:31/08/2021: US-0010280 - Email is not sent when deal is internally approved
    //     if(!setDealId.isEmpty()){
    //         List<EBH_Deal__c> listDealToUpdate = [select Id,Internally_Approved_Rejected_Timestamp__c from EBH_Deal__c where Id IN: setDealId AND EBH_Status__c IN: SET_STATUS_MASSAPPROVAL]; 
    //         Datetime currentTime = Datetime.now();
    //         for(EBH_Deal__c deal : listDealToUpdate){
    //             deal.Internally_Approved_Rejected_Timestamp__c = currentTime;
    //         }
    //         update listDealToUpdate;
    //     }
    
    //   }

    
    @InvocableMethod
    public static void processBuilderCriteriaBypass(){} // Sophal:01/09/2021:US-0010285
  
  
  
  
       public class MassApprovalException extends Exception {}
  
  
  
       public class ItemWrapper {
  
          @AuraEnabled
          public Boolean checked { get; set; }
  
          @AuraEnabled
          public String recordId { get; set; }
  
          @AuraEnabled
          public List<CellValue> cells {get;set;}
  
          @AuraEnabled
          public String comment { get; set; }
  
  
      }
  
  
  
      public class CellValue {
  
          @AuraEnabled
          public String celltype { get; set; }
  
          @AuraEnabled
          public String value { get; set; }
  
          @AuraEnabled
          public String recordid { get; set; }
  
          @AuraEnabled
          public String name { get; set; }
  
      }

    /*****************************************************************************************************************************
    @ Method:        fetchRecordType
    @ Version:      1.0
    @ Author:       LoumAng SENG (loumang.seng@gaea-sys.com)
    @ Purpose:      US-0014109 - Record type filter on Deals Mass Approvals page
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 25.09.2023 / LoumAng SENG / Created the method.
    *****************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> fetchRecordType(){
        Map<String,Object> mapResult = new Map<String,Object>();
		try
	 	{
            List<Map<String,String>> recordTypeMap = new List<Map<String,String>>();
            for(RecordTypeInfo info: Deal_Statement__c.SObjectType.getDescribe().getRecordTypeInfos()) {
                
                if(info.isAvailable() && SET_RECORDTYPE_DS.contains(info.getDeveloperName())) {
                    recordTypeMap.add(new Map<String,String>{'label'=>info.getName(),'value'=>info.getDeveloperName()});   
                }
            }    
			mapResult.put('status','ok');
            mapResult.put('lstRecordType',recordTypeMap);
	 	}catch(Exception ex){
    		mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString());
        }
        return mapResult;
    }
  
  }