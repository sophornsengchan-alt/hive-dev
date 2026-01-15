/*********************************************************************************************************************************
@ Class:        Batch_DisconnectS_SEP_Users
@ Version:      1.0
@ Author:       vadhanak voun(vadhanak.voun@gaea-sys.com)
@ Purpose:      US-0010902 - Allow Sellers to unlink Accounts
@               Nightly job to clean the disconected user by Unlink Account
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.05.2022 /  vadhanak voun : created the class
*********************************************************************************************************************************/
global with sharing class Batch_Disconnect_SEP_Users implements Database.Batchable<SObject>,Database.AllowsCallouts, Schedulable{

    Id recSellerId = ApexUtil.getRecordTypeByName('Account', 'EBH_Seller').Id;
    
    String soqlSeller = 'Select Id,Name,User_Disconnected__c,eBay_API_User_Id__c From Account ';
    String soqlWhere = ' WHERE RecordTypeId=:recSellerId AND eBay_API_User_Id__c <> NULL AND User_Disconnected__c=TRUE';
    Set<String> setIds = null; //test
    
    public Batch_Disconnect_SEP_Users(){}

    public Batch_Disconnect_SEP_Users(Set<String> setIds)
    {
        this.setIds = setIds;
        soqlWhere = ' WHERE Id IN :setIds';
    }
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
       return Database.getQueryLocator(soqlSeller+soqlWhere);
       //return Database.getQueryLocator([select id from user limit 1]);
    }

    global void execute(Database.BatchableContext bc, List<Account> scope)
    {
        List<Account> listSeller = new List<Account>();
        for(Account seller: scope)
        {
            //revoke first avoid uncommit pending
            Boolean revokeResult = Test.isRunningTest()?true:ApexUtil.revokeUserAccess3PLink('',seller.eBay_API_User_Id__c);
            if(revokeResult)
            {
                seller.User_Disconnected__c = false;
                listSeller.add(seller);
            }
        }
        
        if(!listSeller.isEmpty())
        {
            update listSeller;
        }
    }

    global void finish(Database.BatchableContext bc){
        
    }

    global void execute(SchedulableContext sc) {
        Database.executeBatch(new Batch_Disconnect_SEP_Users(),10);
    }
}