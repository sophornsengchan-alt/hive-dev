@IsTest
private class GC_SaveLogNormalize_Test {

    @IsTest
    static void testContactCallLogCreatesTask() {
        EBH_TestDataFactory.setUpCustomSettings();

        Contact c = new Contact(LastName = 'Tester');
        insert c;

        // Fake Genesys payload with Contact WhoId and short date format
        Map<String,Object> callLog = new Map<String,Object>{
            'whoid' => '[{id:' + c.Id + '}]',
            'subject' => 'Unit Test Call',
            'status' => 'Completed',
            'type' => 'Call',
            'activitydate' => '2025-9-8',
            'calldurationinseconds' => 5,
            'callobject' => 'interaction-xyz'
        };
        Map<String,Object> payload = new Map<String,Object>{
            'callLog' => callLog,
            'interaction' => new Map<String,Object>{ 'id' => 'interaction-xyz' }
        };

        String data = JSON.serialize(payload);

        GC_SaveLogNormalize ext = new GC_SaveLogNormalize();
        String taskId = ext.onSaveLog(data);

        System.assertNotEquals('', taskId, 'Expected a Task to be created');
        Task t = [SELECT Id, WhoId, Subject, ActivityDate FROM Task WHERE Id = :taskId];
        System.assertEquals(c.Id, t.WhoId, 'WhoId should match the Contact');
        // System.assertEquals('Unit Test Call', t.Subject);
        System.assertEquals('Outbound Call', t.Subject, 'Subject should be Outbound Call'); // flow udpate the subject name
    }

    @IsTest
    static void testNonContactLeadSkipsTask() {
        Account acc = new Account(Name = 'Test Acc');
        insert acc;

        Map<String,Object> callLog = new Map<String,Object>{
            'whoid' => acc.Id,  // Not a Contact/Lead
            'subject' => 'Should Not Save',
            'status' => 'Completed',
            'type' => 'Call',
            'activitydate' => '2025-9-8'
        };
        Map<String,Object> payload = new Map<String,Object>{
            'callLog' => callLog
        };

        String data = JSON.serialize(payload);

        GC_SaveLogNormalize ext = new GC_SaveLogNormalize();
        String taskId = ext.onSaveLog(data);

        System.assertEquals('', taskId, 'Expected no Task for non-Contact/Lead');
    }

    @IsTest
    static void testMalformedWhoIdSkipsTask() {
        Map<String,Object> callLog = new Map<String,Object>{
            'whoid' => 'not-an-id',
            'subject' => 'Bad WhoId',
            'status' => 'Completed',
            'type' => 'Call',
            'activitydate' => '2025-9-8'
        };
        Map<String,Object> payload = new Map<String,Object>{
            'callLog' => callLog
        };

        String data = JSON.serialize(payload);

        GC_SaveLogNormalize ext = new GC_SaveLogNormalize();
        String taskId = ext.onSaveLog(data);

        System.assertEquals('', taskId, 'Expected no Task for malformed WhoId');
    }
}