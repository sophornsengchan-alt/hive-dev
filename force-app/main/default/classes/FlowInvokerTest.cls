@isTest
private  class FlowInvokerTest {
    @IsTest
    static void testInvoke(){

        String flowApiName = 'flowapiname';
        Map<String, Object> flowInputs = new Map<String, Object>();
        flowInputs.put('recordId', '123456');
        List<Map<String,Object>> ls = new List<Map<String,Object>>();
        ls.add(flowInputs);

        Test.startTest();      
        FlowInvoker.invoke(flowApiName, ls);
        Test.stopTest();   
    }
}