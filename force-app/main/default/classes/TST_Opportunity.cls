/**
 * Author : Gaeasys
 * CreatedDate: 31-May-2018
 * Description:
 */
@isTest
private class TST_Opportunity {

	@testSetup static void setup(){
		TST_DataGenerator.setupSimpleData(new Set<String>{'Account','Opportunity'});
	}

    static testMethod void updateOppStage() {

    	
		Opportunity opp = (Opportunity) QueryUtil.queryRecords('Opportunity').get(0);

		system.assertNotEquals( opp.stageName, Label.OPP_STATUS_QM );
		system.assertEquals(opp.Media_Plan__c, null);

		Test.startTest();
		opp.StageName = 'Qualified Meeting';
		update opp;

		Test.stopTest();
		
		//opp = (Opportunity) QueryUtil.queryRecord(opp.id);
		//List<Media_Plan__c> mediaPlans = (List<Media_Plan__c>) QueryUtil.queryRecords('Media_Plan__c', 'Opportunity__c =\'' + opp.Id + '\'');

		//system.assertEquals(1, mediaPlans.size());

		//system.assertEquals(opp.Media_Plan__c, mediaPlans.get(0).id);

		
    }

    static testMethod void newOppRedirectorController(){

    	Account acc = (Account) QueryUtil.queryRecords('Account').get(0);
    	//String devName = Label.OPP_RECORDTYPENAME_AD;
    	String devName = Label.OPP_RECORDTYPEDEVNAME_DIRECT;
		RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Opportunity' AND DeveloperName = :devName Limit 1];
		Opportunity opp = TST_DataGenerator.generateOpp(acc.Id);
		opp.RecordTypeId = recordType.Id;
		insert opp;
		
		Test.startTest();

		RemoteResponse response = LC_NewOppRedirectorController.getRelatedAccount(acc.Id);
		Map <String, Object> content = (Map <String, Object>)response.content;
		Account oneAcc = (Account)content.get('relatedAcc');
		List<Account> acclist = new List<Account>();
		acclist.add(oneAcc);
		system.assertEquals(1, acclist.size());

		String recordId = opp.RecordTypeId + '';
		RemoteResponse recordTypeName = LC_NewOppRedirectorController.getRecordTypeData(recordId, acc.Id);
		system.assert(String.valueOf(recordTypeName.content).contains(recordId));

		Test.stopTest();

    }

    static testMethod void advertiserSearch(){
    	Account acc = (Account) QueryUtil.queryRecords('Account').get(0);
    	String devName = Label.ACC_RECORDTYPENAME_ADV;
    	RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = :devName Limit 1];
    	acc.RecordTypeId = recordType.Id;
    	update acc;

    	Test.startTest();
    	RemoteResponse response = LC_AdvertiserSearchController.getAdvertisers(acc);
    	Map <String, Object> content = (Map <String, Object>)response.content;
		List<Account> acclist = (List<Account>)content.get('lstAdvertiser');

		system.assertEquals(1, acclist.size());
		Test.stopTest();
    }
    static testMethod void chooseAgency(){
    	Account acc = (Account) QueryUtil.queryRecords('Account').get(0);
    	String devName = Label.ACC_RECORDTYPENAME_AGENCY;
    	RecordType recordType = [SELECT Id FROM RecordType WHERE SobjectType = 'Account' AND DeveloperName = :devName Limit 1];
    	acc.RecordTypeId = recordType.Id;
    	update acc;

		Advertiser_Agency_Relationship__c ads = new Advertiser_Agency_Relationship__c();
		ads.Advertiser__c = acc.Id;
		ads.Agency__c = acc.Id;
		ads.Active__c = true;
		ads.Name = 'Test Ads 001';
		ads.Bill_To__c = 'Agency';
		insert ads;
		Test.startTest();

		RemoteResponse response = LC_ChooseAgencyController.getInitData(acc.Id);
		Map <String, Object> content = (Map <String, Object>)response.content;
		List<Advertiser_Agency_Relationship__c> advAgencyRel = (List<Advertiser_Agency_Relationship__c>)content.get('lstAdvAgencyRel');
		system.assertEquals(1, advAgencyRel.size());

		Account advertiser = (Account)content.get('advertiser');
		system.assertEquals(acc.Name, advertiser.Name);

		RemoteResponse response1 = LC_ChooseAgencyController.createAdvAgencyRelation(acc.Id, acc.Id,ads,'','test' );
		Id content2 = (Id)response1.content;
		system.assert(content2 != null);

		Test.stopTest();
    }

    static testMethod void newOpportunity(){
		
    	Account acc = (Account) QueryUtil.queryRecords('Account').get(0);

		Advertiser_Agency_Relationship__c ads = new Advertiser_Agency_Relationship__c();
		ads.Agency__c = acc.Id;
		insert ads;

		Test.startTest();

        String adsId = String.valueOf(ads.Id);
		String agencyId = String.valueOf(acc.Id);
		LC_NewOpportunity.initializeData(adsId,agencyId,adsId);

		Test.stopTest();

    }
	
	// 22.12.2020 / Sophal Noch /  US-0008746 - [Ads 2020] Remove Old Daily/Monthly Forecast Revenue Generated
    // static testMethod void testForecastRevenueFromTrigger(){
    		
    // 		Test.startTest();
    		
    // 		Opportunity opp = (Opportunity) QueryUtil.queryRecords('Opportunity').get(0);
    // 		opp.Start_Date__c = Date.today();
    // 		opp.End_Date__c = Date.today().addDays(10);
    // 		opp.Amount = 1000;
    // 		//opp.RecordTypeId = [Select Id from RecordType Where SobjectType = 'Opportunity' and DeveloperName = :Label.OPP_RECORDTYPENAME_AD].Id;
    // 		opp.RecordTypeId = [Select Id from RecordType Where SobjectType = 'Opportunity' and DeveloperName = :Label.OPP_RECORDTYPEDEVNAME_DIRECT].Id;
    		
    // 		update opp;
    		
    // 		List<FMRS__c> oppFMRS = [Select Id From FMRS__c Where Opportunity__c = :opp.Id];
    // 		system.assertEquals(oppFMRS.isEmpty(), false);
    		
    // 		List<FDRS__c> oppFDRS = [Select Id From FDRS__c Where Opportunity__c = :opp.Id];
    // 		system.assertEquals(oppFDRS.isEmpty(), false);
    		
    // 		Test.stopTest();
    		
    // }

}