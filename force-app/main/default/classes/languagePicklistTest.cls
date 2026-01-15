@isTest 
public class languagePicklistTest {
    @isTest 
    static void test1(){
        test.startTest();
            languagePicklist obj = new languagePicklist(null);
            obj.getDefaultValue();
            obj.getValues();
        test.stopTest();
    }
}