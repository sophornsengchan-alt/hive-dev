@isTest
private class MetadataServiceTest {
    
    
    @isTest
    static void testRemoteSiteSetting() {
        MetadataService.RemoteSiteSetting rss = new MetadataService.RemoteSiteSetting();
        rss.fullName = 'TestRemoteSite';
        rss.description = 'Test Description';
        rss.disableProtocolSecurity = true;
        rss.isActive = true;
        rss.url = 'https://test.com';
        System.assertEquals('TestRemoteSite', rss.fullName);
        System.assertEquals('Test Description', rss.description);
        System.assertEquals(true, rss.disableProtocolSecurity);
        System.assertEquals(true, rss.isActive);
        System.assertEquals('https://test.com', rss.url);
    }

    @isTest
    static void testCreateResponse_Element() {
        MetadataService.CreateResponse_Element resp = new MetadataService.CreateResponse_Element();
        resp.result = new MetadataService.AsyncResult[] { new MetadataService.AsyncResult() };
        System.assertNotEquals(null, resp.result);
    }

    @isTest
    static void testAsyncResult() {
        MetadataService.AsyncResult ar = new MetadataService.AsyncResult();
        ar.checkOnly = true;
        ar.done = true;
        ar.id = '123';
        ar.message = 'msg';
        ar.numberComponentErrors = 0;
        ar.numberComponentsDeployed = 1;
        ar.numberComponentsTotal = 1;
        ar.numberTestErrors = 0;
        ar.numberTestsCompleted = 1;
        ar.numberTestsTotal = 1;
        ar.state = 'Completed';
        ar.stateDetail = 'Detail';
        ar.stateDetailLastModifiedDate = System.now();
        ar.statusCode = 'Success';
        System.assertEquals('123', ar.id);
    }

    @isTest
    static void testCheckStatus_Element() {
        MetadataService.CheckStatus_Element cse = new MetadataService.CheckStatus_Element();
        cse.asyncProcessId = new String[] { '123' };
        System.assertEquals('123', cse.asyncProcessId[0]);
    }

    @isTest
    static void testCheckStatusResponse_Element() {
        MetadataService.CheckStatusResponse_Element csre = new MetadataService.CheckStatusResponse_Element();
        csre.result = new MetadataService.AsyncResult[] { new MetadataService.AsyncResult() };
        System.assertNotEquals(null, csre.result);
    }

    @isTest
    static void testPackageTypeMembers() {
        MetadataService.PackageTypeMembers ptm = new MetadataService.PackageTypeMembers();
        ptm.members = new String[] { 'A', 'B' };
        ptm.name = 'Test';
        System.assertEquals('Test', ptm.name);
        System.assertEquals('A', ptm.members[0]);
    }

    @isTest
    static void testDebuggingHeader_Element() {
        MetadataService.DebuggingHeader_Element dhe = new MetadataService.DebuggingHeader_Element();
        dhe.categories = new MetadataService.LogInfo[] { new MetadataService.LogInfo() };
        dhe.debugLevel = 'DEBUG';
        System.assertEquals('DEBUG', dhe.debugLevel);
    }

    @isTest
    static void testLogInfo() {
        MetadataService.LogInfo li = new MetadataService.LogInfo();
        li.category = 'Apex_code';
        li.level = 'DEBUG';
        System.assertEquals('Apex_code', li.category);
        System.assertEquals('DEBUG', li.level);
    }

    @isTest
    static void testSessionHeader_Element() {
        MetadataService.SessionHeader_Element she = new MetadataService.SessionHeader_Element();
        she.sessionId = 'abc';
        System.assertEquals('abc', she.sessionId);
    }

    @isTest
    static void testRetrieveResponse_Element() {
        MetadataService.RetrieveResponse_Element rre = new MetadataService.RetrieveResponse_Element();
        rre.result = new MetadataService.AsyncResult();
        System.assertNotEquals(null, rre.result);
    }

    @isTest
    static void testDebuggingInfo_Element() {
        MetadataService.DebuggingInfo_Element die = new MetadataService.DebuggingInfo_Element();
        die.debugLog = 'log';
        System.assertEquals('log', die.debugLog);
    }

    @isTest
    static void testCallOptions_Element() {
        MetadataService.CallOptions_Element coe = new MetadataService.CallOptions_Element();
        coe.client = 'client';
        System.assertEquals('client', coe.client);
    }

    @isTest
    static void testCheckDeployStatus_Element() {
        MetadataService.CheckDeployStatus_Element cdse = new MetadataService.CheckDeployStatus_Element();
        cdse.asyncProcessId = '123';
        System.assertEquals('123', cdse.asyncProcessId);
    }

    @isTest
    static void testCreate_Element() {
        MetadataService.Create_Element ce = new MetadataService.Create_Element();
        ce.metadata = new MetadataService.Metadata[] { new MetadataService.RemoteSiteSetting() };
        System.assertNotEquals(null, ce.metadata);
    }

    @isTest
    static void testMetadataPortMethods() {
        Test.startTest();
        MetadataService.MetadataPort port = new MetadataService.MetadataPort();
        // create() and checkStatus() should return null in test context
        MetadataService.AsyncResult[] result1 = port.create(new MetadataService.Metadata[] { new MetadataService.RemoteSiteSetting() });
        MetadataService.AsyncResult[] result2 = port.checkStatus(new String[] { '123' });
        System.assertEquals(null, result1);
        System.assertEquals(null, result2);
        Test.stopTest();
    }

}