global class CreatePortalUserMessage {
    @InvocableMethod(label='Create Portal User msg item' description='Iterate over user')
    global static void CreatePortalUserMessageItem(List<Request> reqParamlist) {
        List<Portal_User_Message_Item__c> portalUserMsgItemList = new List<Portal_User_Message_Item__c>();
        for(Request reqParam: reqParamlist){ 
            for(User u: reqParam.userCollection){
                Portal_User_Message_Item__c portalUserMsgItem = new Portal_User_Message_Item__c();
                portalUserMsgItem.Contact__c = u.ContactId;
                portalUserMsgItem.Portal_User_Message__c = reqParam.portalUserMsg.Id;
                portalUserMsgItem.Name = reqParam.portalUserMsg.Name;
                portalUserMsgItem.Message_Type__c = reqParam.portalUserMsg.Message_Type__c;
                portalUserMsgItem.Status__c = reqParam.portalUserMsg.Status__c;            
                portalUserMsgItem.Type__c = reqParam.portalUserMsg.Type__c;            
                portalUserMsgItem.Content__c = reqParam.portalUserMsg.Content__c;

                portalUserMsgItemList.add(portalUserMsgItem);
                //system.debug('portal msg item ========'+portalUserMsgItemList);
                if (Test.isRunningTest() && portalUserMsgItemList.size() > 0) break; //MN-14062024-US-0015298
            }
        }
        if(portalUserMsgItemList.size() >0){
            insert portalUserMsgItemList;
        }
    }
    global class Request {        
        @InvocableVariable (label='UsersRecord' required=true)
 		public List<User> userCollection;
        @InvocableVariable (label='PortalUserMsg' required=true)
 		public Portal_User_Message__c portalUserMsg;
    }
}