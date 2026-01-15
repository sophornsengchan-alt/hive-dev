@isTest
public with sharing class ConvertCSVToStringCollectionTest{
    
    @isTest
    public static void canConvertString(){
        //String testString = 'foo,bar,baz';
        ConvertCSVToStringCollection.Request testReq = new ConvertCSVToStringCollection.Request();
        testReq.csvString = 'foo,bar,baz';

        List<ConvertCSVToStringCollection.Request> testReqList = new List<ConvertCSVToStringCollection.Request>();
        testReqList.add(testReq);

        List<ConvertCSVToStringCollection.Response> testResponseList = ConvertCSVToStringCollection.execute(testReqList);
     
        System.assertEquals(testResponseList[0].stringCollection[0], 'foo');
    }

    @isTest
    public static void canConvertStringCollection(){
        List<String> stringCollection = new List<String>();
        stringCollection.add('foo');
        stringCollection.add('bar');
        stringCollection.add('baz');
        // testString = 'foo,bar,baz';

    }
}