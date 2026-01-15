@isTest
private class RecordTypePickerControllerTest {
    
    @isTest 
    static void test_invokeGetRecordTypes () {

        Test.startTest();

            List<RecordTypePickerController.Request> requests = new List<RecordTypePickerController.Request>();

            RecordTypePickerController.Request request = new RecordTypePickerController.Request();
            request.objectApiName = 'Contract';
            
            requests.add(request);

            List<RecordTypePickerController.Result> result = RecordTypePickerController.invokeGetRecordTypes(requests);

            System.assert( !result.isEmpty(), 'There should be result return.');

        Test.stopTest();

    }
}