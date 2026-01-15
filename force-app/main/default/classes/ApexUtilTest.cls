@Istest
private class ApexUtilTest {
	static testMethod void testUtil()
	{
		Test.startTest();
			ApexUtil.formatNumber(10000,',','.',2);
			ApexUtil.formatNumber(10000,2,'DE');
			ApexUtil.checkNull(10);
			ApexUtil.formatTime(null);
			ApexUtil.formatTime24h(null);
			ApexUtil.formatTime12H(Time.newInstance(1, 1, 1, 1));
			ApexUtil.mapCurrencySign.get('USD');
			ApexUtil.toDecimal('1000',2);
			ApexUtil.toDecimal0('1000',2);
			ApexUtil.toInteger('10');
			ApexUtil.toDouble('10');
			ApexUtil.getUserRoleByName('Global');
			ApexUtil.getRecordTypeByName('Account','EBH_Seller');
			ApexUtil.getRecordTypeBySobjectName('Account');
			ApexUtil.doSend('subject','test@test.com','html body here');
			ApexUtil.checkPermissionSet(new Set<String>{'no_permission_name'});
			ApexUtil.getValue('Parent.Name',new Account(Name='Test'));
			ApexUtil.runningInASandbox();
			ApexUtil.getSiteUrl('Deal_Acceptance');
			ApexUtil.getUsersMemberByGroup(new  Set<String>{'group1'});
			ApexUtil.constructQuoteString(new Set<String>{'x','y'});
			ApexUtil.generateSQOLFields('Account');
			ApexUtil.doCompare('=',4,4);
			ApexUtil.doCompare('<',4,4);
			ApexUtil.doCompare('<=',4,4);
			ApexUtil.doCompare('>',4,4);
			ApexUtil.doCompare('>=',4,4);
			ApexUtil.genUniqueString(10);
			ApexUtil.countRunningBatch(new Set<String>{'Batch1'});
			ApexUtil.countRunningBatchByUser(new Set<String>{'BatchCohortAction'}, new Set<String>{'BatchApex'}, new Set<Id>{UserInfo.getUserId()}); // 13.11.2023 / Sophal Noch / US-0014345
			ApexUtil.nullStr('');
			ApexUtil.findCronJob(new Set<String>{'BatchCouponSellerStatus'});
			Map<String, List<ApexUtil.PicklistEntryWrapper>> objResults  = ApexUtil.getDependentMap(EBH_Deal__c.getSObjectType(),'EBH_DealSiteId__c','EBH_Vertical__c');
			ApexUtil.getPicklistValues(EBH_Deal__c.EBH_DealFormat__c);
        ApexUtil.getFieldIdRef('EBH_BusinessName__r.Name');
        ApexUtil.fixNumber('15.5','EN');
        ApexUtil.permissionSetMembers('test');
		ApexUtil.getCurrentUser();

		Map<String,String> binding = new Map<String,String>();
		List<EmailTemplate>  template = [select Id, Name, Body, Subject, HtmlValue, DeveloperName from EmailTemplate where DeveloperName = 'NA_Deals_Notify_Approvals' LIMIT 1];
		if(template.isEmpty()){
			binding.put('{!User.Phone}', 'xxxxxxxxxxxx');
		}else{
			binding.put('{!EBH_Deal__c.Merchant_Approver__c}', 'Test Name');
			binding.put('{!EBH_Deal__c.Link}', URL.getOrgDomainUrl().toExternalForm());
		}

		Messaging.SingleEmailMessage preparedEmail = ApexUtil.prepareEmail(null, new String[] {'sophal.noch@gaea-sys.com.invalid'}, null, 'NA_Deals_Notify_Approvals', 'Sample_GreatMeetingYou', binding, null, null);
		//ApexUtil.sendEmail(new List<Messaging.SingleEmailMessage>{preparedEmail});

		Test.stopTest(); 

		ApexUtil.getProfileByName('Administrator');
		ApexUtil.getPermissionSetL('test');
		ApexUtil.getOWDbyAddress('');
		ApexUtil.getFieldSet('Account', 'test') ;
		ApexUtil.validSFId(UserInfo.getUserId());
		ApexUtil.MAP_LOCALE_DATEFORMAT();

		ApexUtil.chunkList(new List<Object>{'a','b'},1);

		ApexUtil.isProduction();
		ApexUtil.gmtDateToDTZone(system.today(),Time.newInstance(1, 2, 3, 4),'PST');
        ApexUtil.generateUniqueString(new List<ID>{UserInfo.getUserId()});

		ApexUtil.revokeUserAccess3PLink(UserInfo.getUserId(),'xyzabc');
		//VM 03/02/2025 / US-0016639 - Testing Feedback fixes - Deals - Sprint 117
		String todayDateFormat = Date.today().format();
        todayDateFormat = todayDateFormat.replaceAll('[0-9]',''); // remove all numbers from string format of date
        String dateSeperator  = String.isNotEmpty(todayDateFormat) ? todayDateFormat.substring(0,1) : '/';
		dateSeperator = dateSeperator == '.' ? '\\.' : dateSeperator;
		ApexUtil.getIndexOfUserDateFormat(dateSeperator);

		//NK:16/08/2022
		String wordNum1 = ApexUtil.numberToWords(124L); 
		System.assertEquals('One Hundred Twenty Four', wordNum1);

		String wordNum2 = ApexUtil.numberToWords(Decimal.valueOf('121.51')); 
		System.assertEquals('One Hundred Twenty One point Fifty One', wordNum2);

		String wordNum3 = ApexUtil.numberToWords(Decimal.valueOf('121.51')); 
		System.assertEquals('One Hundred Twenty One point Fifty One', wordNum3);

		String wordNum4 = ApexUtil.numberToWordsCurrency(Decimal.valueOf('121.51')); 
		System.assertEquals('One Hundred Twenty One and Fifty One cents', wordNum4);
		
		ApexUtil.chunkListSOBJ(new List<Account>{new Account()},1);

		//MN-22112022US-0012333
		String curDomain = ApexUtil.getDomain();
		System.assert(String.isNotBlank(curDomain), 'This method should not return null.');

		//MN-15052023-
		ApexUtil.MAP_LOCALE_DATEONLY();

		ApexUtil.generateUniqueId(ApexUtil.IdPrefixType.LOGIN_FAILED);

	}

	/*****************************************************************************************************************************
	@ Method:         testGetDateTimezoneOffsetForSite
	@ Version:        1.0
	@ Author:         GitHub Copilot
	@ Purpose:        US-0033985: Test timezone offset calculation for different sites and dates
	------------------------------------------------------------------------------------------------------------------------------
	@ Change history: 02.12.2025 / GitHub Copilot / Created the test Method.
	*****************************************************************************************************************************/
	@isTest
	static void testGetDateTimezoneOffsetForSite() {
		Test.startTest();
		
		// Test US timezone offset calculation
		Date summerDate = Date.newInstance(2025, 6, 15); // June 15, 2025 (DST period)
		Date winterDate = Date.newInstance(2025, 12, 15); // December 15, 2025 (Standard time)
		
		// Test US site offsets (Pacific Time)
		Decimal usSummer = ApexUtil.getDateTimezoneOffsetForSite(summerDate, 'US');
		Decimal usWinter = ApexUtil.getDateTimezoneOffsetForSite(winterDate, 'US');
		
		// US Pacific Time: UTC-7 during DST (summer), UTC-8 during Standard Time (winter)
		System.assertEquals(-25200, usSummer, 'US summer offset should be -7 hours (-25200 seconds)');
		System.assertEquals(-28800, usWinter, 'US winter offset should be -8 hours (-28800 seconds)');
		
		// Test UK timezone offset calculation
		Decimal ukSummer = ApexUtil.getDateTimezoneOffsetForSite(summerDate, 'UK');
		Decimal ukWinter = ApexUtil.getDateTimezoneOffsetForSite(winterDate, 'UK');
		
		// UK: UTC+1 during BST (summer), UTC+0 during GMT (winter)
		System.assertEquals(3600, ukSummer, 'UK summer offset should be +1 hour (3600 seconds)');
		System.assertEquals(0, ukWinter, 'UK winter offset should be 0 hours (0 seconds)');
		
		// Test DE timezone offset calculation
		Decimal deSummer = ApexUtil.getDateTimezoneOffsetForSite(summerDate, 'DE');
		Decimal deWinter = ApexUtil.getDateTimezoneOffsetForSite(winterDate, 'DE');
		
		// DE: UTC+2 during CEST (summer), UTC+1 during CET (winter)
		System.assertEquals(7200, deSummer, 'DE summer offset should be +2 hours (7200 seconds)');
		System.assertEquals(3600, deWinter, 'DE winter offset should be +1 hour (3600 seconds)');
		
		Test.stopTest();
	}
}