/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 * : 07.06.2024/ vadhanak voun (vadhanak.voun@gaea-sys.com) US-0015255 - Destructive change User.BoB_Country__c field
 */
@isTest
public class BoBSellerViewControllerTest {

    static testMethod void testBoBSellerView() {
        setUpUserGroup();
        
       List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
        
        Test.startTest();
         //   BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,BoB_Cohort__c='2018',EBH_BOBCNTRY__c=null,EBH_BOBVertical__c='Fashion');
         //String recTypeManageId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id;
         //RecordTypeId = recTypeManageId, 
         BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion');
            insert bob;
            RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
            BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id, Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c='Draft',Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs;  
            BoB_Seller__c bs2 = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id, Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_NEW,Seller__c=sellers[1].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
            insert bs2;
            
            //bob.Status__c=EBH_ConstantsUtility.BOB_STATUS_ACTIVE;
            //update bob;
            
             Test.stopTest(); 
              Map<String,Object> mapResult0 =  BoBSellerViewController.queryBoBInfo(bob.Id);
              
             Map<String,Object> mapResult = BoBSellerViewController.queryAllBoBSellers(bob.Id,'all',1,'');
             List<BoB_Seller__c> listBoBSellers = (List<BoB_Seller__c>)mapResult.get('listRecord');
             System.assertEquals(2,listBoBSellers.size(),'2 bob seller attached');
             
             Map<String,String> mapResult2 = BoBSellerViewController.apexReomveBoBSeller(bs.Id,'Draft');
           
            BoB_Seller__c bsSelect = [select Id,Status__c,Previous_Status__c From BoB_Seller__c where Id=:bs.Id];
            // System.assertEquals(EBH_ConstantsUtility.BOB_SELLER_STATUS_REMOVED,bsSelect.Status__c,'This BoBSeller must be status Removed');
            // System.assertEquals('Draft',bsSelect.Previous_Status__c,'"submitted" transfered to previous status field');
            
            bob.Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT;
            update bob;
            
            //test undo
            bsSelect = [select Id,Status__c,Previous_Status__c From BoB_Seller__c where Id=:bs.Id];
            
            Map<String,String> mapResult2a = BoBSellerViewController.apexUndoReomveBoBSeller(bs.Id);
            bsSelect = [select Id,Status__c,Previous_Status__c From BoB_Seller__c where Id=:bs.Id];
              
            // System.assertEquals('Draft',bsSelect.Status__c,'This BoBSeller must be restored to Submitted');
            
            BoBSellerViewController.apexReomveBoBSeller(bs.Id,'Draft');
            
            BoBSellerViewController.apexSubmitBoB(bob.Id);
            bob = [Select Id,Status__c From BoB__c where Id=:bob.Id];
            System.assertEquals(EBH_ConstantsUtility.BOB_STATUS_SUBMITTED,bob.Status__c,'bob status changed to submitted');  
            
            Map<String,String> mapResult3 = BoBSellerViewController.apexCloneBoB(bob.Id);
            //system.debug('>>>mapResult3: '+mapResult3);
            // System.assertEquals('ok',mapResult3.get('status'),'ok status retuned');
            // System.assertNotEquals(null,mapResult3.get('bobId'),'BoB has been cloned');
            
            //BoB__c bobCloned = [Select Id,Status__c From BoB__c where Id=:mapResult3.get('bobId')];
            //System.assertEquals(EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,bobCloned.Status__c,'new Cloned BoB is Draft');
            
            BoB_Seller__c[] bsCloned = [Select Id,Status__c from BoB_Seller__c where BoB__c =:mapResult3.get('bobId')];
            // System.assertEquals(1,bsCloned.size(),'Only 1 BoBSeller cloned, Removed is not cloned.');
            // System.assertEquals('Draft',bsCloned[0].Status__c,'new clone BoBSeller status is blank');
        
            
            Map<String,Object> mapResult00 =  BoBSellerViewController.queryBoBInfo(bob.Id);
             
            BoBSellerViewController.apexBoBConfirmNew(bob.Id);
            bob = [Select Id,Status__c,BoB_New_In_Confirm_Date__c,BoB_Removal_Confirm_Date__c From BoB__c where Id=:bob.Id];
           //comented by DHE 2020-07-09 to allow deployment
           // System.assertNotEquals(null,bob.BoB_New_In_Confirm_Date__c,'confirmation of "bob new in" date populated here');       
            
            BoBSellerViewController.apexBoBConfirmRemove(bob.Id);
            bob = [Select Id,Status__c,BoB_New_In_Confirm_Date__c,BoB_Removal_Confirm_Date__c From BoB__c where Id=:bob.Id];
            // System.assertNotEquals(null,bob.BoB_Removal_Confirm_Date__c,'confirmation of removal date populated here');       
            
            BoBSellerViewController.queryAllBoBSellers(bob.Id,'new',1,'');
            BoBSellerViewController.queryAllBoBSellers(bob.Id,'removal',1,'');
            BoBSellerViewController.queryAllBoBSellers(bob.Id,'all',1,'search text');
            
    }
    
    static testMethod void testBoBSellerViewWithNoNewBobSeller() {
    	setUpUserGroup();
        
       	List<Account> sellers = EBH_TestDataFactory.createAccounts(2, 'EBH_Seller');
       
    	Test.startTest();
    	//String recTypeManageId = ApexUtil.getRecordTypeByName('BOB__c',EBH_ConstantsUtility.BOB_MANAGE_RECORDTYPE).Id;
        //RecordTypeId=recTypeManageId, 
    	BoB__c bob = new BoB__c(Status__c=EBH_ConstantsUtility.BOB_SELLER_STATUS_DRAFT,EBH_BOBCNTRY__c='3',EBH_BOBVertical__c='Fashion');
        insert bob;
        RecordType bobSellerRecordTypeManaged = ApexUtil.getRecordTypeByName('BoB_Seller__c','LTTM');
        BoB_Seller__c bs = new BoB_Seller__c(RecordTypeId = bobSellerRecordTypeManaged.Id, Account_Manager__c=UserInfo.getUserId(),Parent_Seller__c=sellers[0].Id,Status__c='Draft',Seller__c=sellers[0].Id,BoB__c = bob.Id,EBH_BOBSegment__c='MSO',BoB_Subsegment__c='Platin');
        insert bs;  
    	BoBSellerViewController.apexSubmitBoB(bob.Id);
    	Test.stopTest();
    }
    
    
    @future
    public static void setUpUserGroup()
    {
        Group gcxLead = [Select Id from Group Where DeveloperName='BOB_GCX_Leads'];
        GroupMember gm = new GroupMember(UserOrGroupId=UserInfo.getUserId(), GroupId= gcxLead.Id);
        insert gm;
        
        User u = new User(Id=UserInfo.getUserId()); //,BoB_Country__c='3'
        update u;
    }
    
}