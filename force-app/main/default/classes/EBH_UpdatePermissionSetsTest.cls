/*********************************************************************************************************************************
@ Class:          EBH_UpdatePermissionSetsTest
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        Handler Class for EBH_UpdatePermissionSets
@ Change history: 25.11.2021 / SRONG TIN / Created the test class.
*********************************************************************************************************************************/
@isTest
public class EBH_UpdatePermissionSetsTest {
    @testSetup
    static void setup(){
        //create an account
        Account acc = new Account( Name = 'TestAccount', EBH_StoreSubscription__c = 'Basic');
        insert acc;

        //create a contact
        Contact con = new Contact(Accepted_Current_Deals_Agreement__c=false,
                                    FirstName='test fn', LastName='test ln', AccountId=acc.Id, Email = 'test123@test.com');
        insert con;
    }
	@IsTest
    static void testMethod1(){
        Account acc = [SELECT Id FROM Account WHERE Name = 'TestAccount' limit 1];

        Profile profile1 = [SELECT Id, Name FROM Profile WHERE Name = 'System Administrator'];

        Contact con = [SELECT Id,Email FROM Contact WHERE FirstName='test fn' AND LastName='test ln' limit 1];
        List<User> uList = new List<User>();
        for(Integer i=1;i<=10;i++){
            User user = new User(
                                Username = 'test12345xx'+i+'@test.com',
                                ProfileId = profile1.Id,
                                Alias = 'test'+i,
            					isactive = true,
                                Email = 'test1xx'+i+'@test.com',
                                EmailEncodingKey = 'UTF-8',
                                LastName = 'McTesty',
                                CommunityNickname = 'jamy'+i,
                                TimeZoneSidKey = 'America/Los_Angeles',
                                LocaleSidKey = 'en_US',
                                LanguageLocaleKey = 'en_US'
                                );
            uList.add(user);
        }
        
        
        insert uList;
        System.runAs(uList[0]){
			PermissionSet[] ps = Database.query(EBH_ConstantsUtility.SOQL_PERMISSIONSET + ' WHERE Name=\'GCX_Super_User\'');
			insert new PermissionSetAssignment(AssigneeId = uList[0].id, PermissionSetId = ps[0].Id);
		}
        Test.startTest();
        	try{
                String soql = 'select id,permission_sets__c from User where isactive=true and profile.UserLicense.name=\'Salesforce\'';
                EBH_UpdatePermissionSets batch = new EBH_UpdatePermissionSets(soql);
                batch.batchSize = 200;
                batch.start(null);
                batch.execute(null, new List<User>());
                batch.finish(null);
            	batch.execute(null);
            }catch(Exception e){
                System.debug('Error'+ e.getMessage());
            }
        Test.stopTest();
    }
}