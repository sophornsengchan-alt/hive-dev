/**
 * Author : Gaeasys
 * CreatedDate: 28-12-2018
 * Description:
 */
 
@isTest
private class TST_DFPCredentialController {
    
    @testSetup static void setup(){
		//
		AdServer_Login__c adServer = new AdServer_Login__c(RecordTypeId=[Select id, name From RecordType Where  Name=: DARTUtil.DART6 AND SobjectType =:Util.NS+'AdServer_Login__c' limit 1].id,
            Name = 'testLogin',
            Login_URL__c='http://test.com',
            User_Name__c='dart6testuser@gmail.com',
            Password__c ='testpwddart6123456',
            Active__c = true,
            Network_ID__c='123456',
            Client_ID__c = 'xxxxxxxxxxxxxxxxxxxxx',
            Client_Secret__c = 'xxxxxxxxxxxxxxx',
            Refresh_Token__c = 'xxxxxxxxxxx',
            RT_Waiting__c = true
        );
        insert adServer;
	}
	
	static testMethod void testCredentialProcess() { 

		AdServer_Login__c adServer = (AdServer_Login__c) QueryUtil.queryRecords(Util.NS+'AdServer_Login__c').get(0);
		ApexPages.currentPage().getParameters().put('code', 'test');
		
		Test.startTest();
			DFPCredentialController con = new DFPCredentialController();
			
			con.selectedValue = adServer.Id;
			con.getRunOfNetworkID();
			
			con.saveToken();
			con.processCredential();
			con.cancel();
		Test.stopTest();
		
	}
    
}