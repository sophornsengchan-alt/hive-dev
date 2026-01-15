@isTest
public class Batch_TargetingEngineReminderTest {

    @testSetup static void setUpData() {
        Date day3 = System.today().addDays(3);
		Date day7 = System.today().addDays(7);
		Date today = System.today();

		EBH_Filter__c targetingEngine7Days = new EBH_Filter__c();
		targetingEngine7Days.Name = 'targetingEngine7Days';
		targetingEngine7Days.EBH_TE_Expiration_Date__c = day7;
		insert targetingEngine7Days;

		EBH_Filter__c targetingEngine3Days = new EBH_Filter__c();
		targetingEngine3Days.Name = 'targetingEngine3Days';
		targetingEngine3Days.EBH_TE_Expiration_Date__c = day3;
		insert targetingEngine3Days;

		EBH_Filter__c targetingEngineToday = new EBH_Filter__c();
		targetingEngineToday.Name = 'targetingEngineToday';
		targetingEngineToday.EBH_TE_Expiration_Date__c = today;
		insert targetingEngineToday;

		Account account = new Account();
		account.Name = 'account';
        account.EBH_EmailOut__c = false;
		insert account;
		
		EBH_TargetedSeller__c targetedSeller = new EBH_TargetedSeller__c();
		targetedSeller.EBH_Seller__c = account.Id;
		targetedSeller.EBH_SellerList__c = targetingEngineToday.Id;
		insert targetedSeller;
	}
	private static String CRON_EXP = '0 0 1 * * ? *';
	@isTest
	public static void executeScheduledJob() {
		Test.startTest();
			Batch_TargetingEngineReminder targetingEngine = new Batch_TargetingEngineReminder();
			System.schedule('TargetingEngineSendEmailToUsersBatchTest3', CRON_EXP, targetingEngine); 
		Test.stopTest();
	}
	@isTest
	public static void executeScheduledJob2() {
		Test.startTest();
			Batch_TargetingEngineReminder targetingEngine = new Batch_TargetingEngineReminder();
			Database.executeBatch(targetingEngine);
		Test.stopTest();
		List<EBH_Filter__c> listTargetingEngine = [SELECT Id, EBH_TE_Expiration_Date__c, Name, Owner.email, Owner.name FROM EBH_Filter__c WHERE Name = 'targetingEngineToday'];
		System.assertEquals(0, listTargetingEngine.size());
        
        List<EBH_TargetedSeller__c> listTargetedSeller = [SELECT Id FROM EBH_TargetedSeller__c];
		System.assertEquals(0, listTargetingEngine.size());
	}
}