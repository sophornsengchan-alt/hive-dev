/*********************************************************************************************************************************
@ Class:         CustomChoiceTest
@ Version:       1.0
@ Author:        vadhanak.vounr (vadhanak.voun@gaea-sys.com)
@ Purpose:       Test class for CustomChoice class
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 04.11.2025 / vadhanank voun (vadhanak.voun@gaea-sys.com) / Created the test class.
*********************************************************************************************************************************/
@isTest
public class CustomChoiceTest {
    
    @isTest
    static void testDefaultConstructor() {
        // Test the default constructor
        Test.startTest();
        CustomChoice choice = new CustomChoice();
        Test.stopTest();
        
        // Verify that the object is created successfully
        System.assertNotEquals(null, choice, 'CustomChoice object should not be null');
        System.assertEquals(null, choice.label, 'Label should be null by default');
        System.assertEquals(null, choice.value, 'Value should be null by default');
    }
    
    @isTest
    static void testParameterizedConstructor() {
        // Test data
        String testLabel = 'Test Label';
        String testValue = 'test_value';
        
        Test.startTest();
        CustomChoice choice = new CustomChoice(testLabel, testValue);
        Test.stopTest();
        
        // Verify that the object is created with correct values
        System.assertNotEquals(null, choice, 'CustomChoice object should not be null');
        System.assertEquals(testLabel, choice.label, 'Label should match the provided value');
        System.assertEquals(testValue, choice.value, 'Value should match the provided value');
    }
    
    @isTest
    static void testParameterizedConstructorWithNullValues() {
        // Test with null values
        Test.startTest();
        CustomChoice choice = new CustomChoice(null, null);
        Test.stopTest();
        
        // Verify that the object handles null values correctly
        System.assertNotEquals(null, choice, 'CustomChoice object should not be null');
        System.assertEquals(null, choice.label, 'Label should be null');
        System.assertEquals(null, choice.value, 'Value should be null');
    }
    
    @isTest
    static void testParameterizedConstructorWithEmptyStrings() {
        // Test with empty strings
        String emptyLabel = '';
        String emptyValue = '';
        
        Test.startTest();
        CustomChoice choice = new CustomChoice(emptyLabel, emptyValue);
        Test.stopTest();
        
        // Verify that the object handles empty strings correctly
        System.assertNotEquals(null, choice, 'CustomChoice object should not be null');
        System.assertEquals(emptyLabel, choice.label, 'Label should be empty string');
        System.assertEquals(emptyValue, choice.value, 'Value should be empty string');
    }
    
    @isTest
    static void testFieldAssignment() {
        // Test direct field assignment
        CustomChoice choice = new CustomChoice();
        String testLabel = 'Direct Assignment Label';
        String testValue = 'direct_assignment_value';
        
        Test.startTest();
        choice.label = testLabel;
        choice.value = testValue;
        Test.stopTest();
        
        // Verify field assignment works correctly
        System.assertEquals(testLabel, choice.label, 'Label should be assigned correctly');
        System.assertEquals(testValue, choice.value, 'Value should be assigned correctly');
    }
    
    @isTest
    static void testMultipleInstances() {
        // Test creating multiple instances
        String label1 = 'Choice 1';
        String value1 = 'choice_1';
        String label2 = 'Choice 2';
        String value2 = 'choice_2';
        
        Test.startTest();
        CustomChoice choice1 = new CustomChoice(label1, value1);
        CustomChoice choice2 = new CustomChoice(label2, value2);
        Test.stopTest();
        
        // Verify both instances are independent
        System.assertEquals(label1, choice1.label, 'First choice label should be correct');
        System.assertEquals(value1, choice1.value, 'First choice value should be correct');
        System.assertEquals(label2, choice2.label, 'Second choice label should be correct');
        System.assertEquals(value2, choice2.value, 'Second choice value should be correct');
        
        // Verify they are different objects
        System.assertNotEquals(choice1, choice2, 'Two instances should be different objects');
    }
    
    @isTest
    static void testLongStringValues() {
        // Test with long string values
        String longLabel = 'This is a very long label that might be used in a choice component to test how the CustomChoice class handles lengthy text values';
        String longValue = 'this_is_a_very_long_value_that_might_be_used_as_an_identifier_in_the_system_to_test_handling_of_lengthy_values';
        
        Test.startTest();
        CustomChoice choice = new CustomChoice(longLabel, longValue);
        Test.stopTest();
        
        // Verify long strings are handled correctly
        System.assertEquals(longLabel, choice.label, 'Long label should be stored correctly');
        System.assertEquals(longValue, choice.value, 'Long value should be stored correctly');
    }
    
    @isTest
    static void testSpecialCharacters() {
        // Test with special characters
        String specialLabel = 'Test & Label with "Special" Characters: <>';
        String specialValue = 'test_value_with_special_chars_&_symbols';
        
        Test.startTest();
        CustomChoice choice = new CustomChoice(specialLabel, specialValue);
        Test.stopTest();
        
        // Verify special characters are handled correctly
        System.assertEquals(specialLabel, choice.label, 'Label with special characters should be stored correctly');
        System.assertEquals(specialValue, choice.value, 'Value with special characters should be stored correctly');
    }
}