@isTest
public class MyCalendarButtonsPicklistTest {
    static testMethod void test1(){
        test.startTest();
        MyCalendarButtonsPicklist obj = new MyCalendarButtonsPicklist();
        obj.getDefaultValue();
        obj.getValues();
        test.stopTest();
    }
}