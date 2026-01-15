/*********************************************************************************************************************************
@ Class:          SEPToDoListController
@ Author:         Patrick Duncan | patrick@triggdigital.com
@ Purpose:        US-0011799 - Refactor to-do list within Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13/06/22 Patrick Duncan / Created controller for use by lwcSEPToDoList
@                   22/07/22 Sovantheany Dim / US-0011674 - Display To-do List for NA Coupons tab
@                   02/09/2022/ Mony Nou / US-0012342 - Coupon records showing in to-do when permission set not assigned
@                   06/09/2022/ vadhanak voun / US-0012132 - Counter in the to-do should be dynamic
@                                           / only removed cache anotation from getToDoListItems()
*********************************************************************************************************************************/
public with sharing class SEPToDoListController {

    @AuraEnabled
    public static List<ToDoListItemDTO> getToDoListItems(Boolean isAggregate, String itemsToShow){
        List<ToDoListItemDTO> toDoListItems = new List<ToDoListItemDTO>();
        List<Seller_Portal_To_Do_List_Item__mdt> toDoListItemMetadataRecords;
        Map<String,Schema.SObjectType> gmap = Schema.getGlobalDescribe(); //MN-02092022-US-0012342
        
        try {
            if(isAggregate){
                List<String> toDoListItemMetadataRecordNames = itemsToShow.split(',');
                //MN-02092022-US-0012342-Add SObject_API__c into below query
                toDoListItemMetadataRecords = [SELECT Id, DeveloperName, Item_Plural_Label__c, Item_Singular_Label__c, Parent_Item__c, Query__c, Target_URL__c, Order__c, Required_Access_Level__c, SObject_API__c FROM Seller_Portal_To_Do_List_Item__mdt WHERE DeveloperName IN :toDoListItemMetadataRecordNames AND Parent_Item__c = NULL Order By Order__c ASC];
            }
            else{
                //MN-02092022-US-0012342-Add SObject_API__c into below query
                toDoListItemMetadataRecords = [SELECT Id, DeveloperName, Item_Plural_Label__c, Item_Singular_Label__c, Parent_Item__c, Query__c, Target_URL__c, Order__c, Required_Access_Level__c, SObject_API__c FROM Seller_Portal_To_Do_List_Item__mdt WHERE Parent_Item__c = :itemsToShow Order By Order__c ASC];

            }
            Map<String,Boolean> accessLevelRequiredToDisplay = getAccessLevelRequiredToDisplay(toDoListItemMetadataRecords);

            for(Seller_Portal_To_Do_List_Item__mdt toDoListItem:toDoListItemMetadataRecords){

                //MN-02092022-US-0012342-Enforced sObject Access => if user has no access to sObject => skip it
                if (String.isNotBlank(toDoListItem.SObject_API__c) && gmap.containsKey(toDoListItem.SObject_API__c) && !gmap.get(toDoListItem.SObject_API__c).getDescribe().isAccessible()) continue;
                //----- MN-02092022-US-0012342


                toDoListItems.add(new ToDoListItemDTO(isAggregate, toDoListItem, accessLevelRequiredToDisplay));

                
            }

        } 
        catch (Exception e) {
            throw new AuraHandledException(e.getMessage()+' line: '+e.getLineNumber());
        }

        return toDoListItems;
    }

    public static Map<String,Boolean> getAccessLevelRequiredToDisplay(List<Seller_Portal_To_Do_List_Item__mdt> toDoListItemMetadataRecords){
        Map<String,Boolean> accessLevelRequiredToDisplay = new Map<String,Boolean>();
        Id parentAccountId = [SELECT Contact.AccountId FROM User WHERE Id = :UserInfo.getUserId()].Contact.AccountId;
        for(Seller_Portal_To_Do_List_Item__mdt toDoListItem:toDoListItemMetadataRecords){
            if(!accessLevelRequiredToDisplay.containsKey(toDoListItem.Required_Access_Level__c) && !String.isBlank(toDoListItem.Required_Access_Level__c)){
                Seller_Portal_Setting__mdt sellerPortalSetting = [SELECT Filter_Values__c FROM Seller_Portal_Setting__mdt WHERE DeveloperName = :toDoListItem.Required_Access_Level__c];  
                String query = 'SELECT Id FROM Account WHERE Id = :parentAccountId AND ' + sellerPortalSetting.Filter_Values__c;
                List<sObject> accountList = Database.query(query);
                accessLevelRequiredToDisplay.put(toDoListItem.Required_Access_Level__c, !accountList.isEmpty());
            }
        }
        return accessLevelRequiredToDisplay;
    }
    
    public class ToDoListItemDTO {
        @AuraEnabled public Seller_Portal_To_Do_List_Item__mdt toDoListItemMetadataRecord;
        @AuraEnabled public List<Seller_Portal_To_Do_List_Item__mdt> childToDoListItemMetadataRecords;
        @AuraEnabled public Integer count;
        @AuraEnabled public String label;
        @AuraEnabled public Boolean display;


        public ToDoListItemDTO(Boolean isAggregate, Seller_Portal_To_Do_List_Item__mdt toDoListItemMetadataRecord, Map<String,Boolean> accessLevelRequiredToDisplay){
            this.toDoListItemMetadataRecord = toDoListItemMetadataRecord;
            if(isAggregate){
                this.getChildToDoListItemMetadataRecords();
            }
            setCount();
            setLabel();
            setDisplay(accessLevelRequiredToDisplay);
        }

        public void getChildToDoListItemMetadataRecords(){
            //MN-02092022-US-0012342-Add SObject_API__c into below query
            this.childToDoListItemMetadataRecords = [SELECT Id, DeveloperName, Item_Plural_Label__c, Item_Singular_Label__c, Parent_Item__c, Query__c, Target_URL__c, SObject_API__c FROM Seller_Portal_To_Do_List_Item__mdt WHERE Parent_Item__c = :this.toDoListItemMetadataRecord.DeveloperName];
        }


        public void setCount(){
            this.count = 0;
            if(toDoListItemMetadataRecord.Parent_Item__c == null){
                for(Seller_Portal_To_Do_List_Item__mdt toDoListItem:this.childToDoListItemMetadataRecords){
                    this.count += Database.countQuery(toDoListItem.Query__c);
                }

            }
            else{
                this.count += Database.countQuery(this.toDoListItemMetadataRecord.Query__c);

            }
        }

        public void setLabel(){
            if(this.count > 1){
                this.label = this.toDoListItemMetadataRecord.Item_Plural_Label__c;
            }
            else{
                this.label = this.toDoListItemMetadataRecord.Item_Singular_Label__c;
            }
        }

        public void setDisplay(Map<String,Boolean> accessLevelRequiredToDisplay){
            this.display = true;
            if(accessLevelRequiredToDisplay.containsKey(this.toDoListItemMetadataRecord.Required_Access_Level__c)){
                this.display = accessLevelRequiredToDisplay.get(this.toDoListItemMetadataRecord.Required_Access_Level__c) && this.count > 0;//TH:22/07/2022:US-0011674-AC3
            }
        }
    }
}