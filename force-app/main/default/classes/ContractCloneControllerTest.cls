@Istest
private class ContractCloneControllerTest {
	@isTest
    private static void testMethod1() 
    {
        Blob bodyBlob=Blob.valueOf('id,name');
        ContentVersion cv = new ContentVersion(Title='Test Attr',VersionData = bodyBlob, pathOnCLient='test.csv');
        insert cv;
        Test.startTest();
        List<Id> cvIds = new List<Id>();
        cvIds.add(cv.Id);
        List<String> ids = ContractCloneController.getAttachments(cvIds);
        System.AssertEquals(ids.size(), 1);
    }
}