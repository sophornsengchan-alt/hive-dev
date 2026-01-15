@IsTest(SeeAllData = true)
public with sharing class LightningForgotPasswordControllerTest {

    /* Verifies that ForgotPasswordController handles invalid usernames appropriately */
    @IsTest
    static void testLightningForgotPasswordControllerInvalidUserName() {
    System.assertEquals(LightningForgotPasswordController.forgotPassword('fakeUser', 'http://a.com'), Label.Site.invalid_email);
    System.assertEquals(LightningForgotPasswordController.forgotPassword(null, 'http://a.com'), Label.Site.invalid_email);
    System.assertEquals(LightningForgotPasswordController.forgotPassword('a', '/home/home.jsp'), Label.Site.invalid_email);
    }

    /* Verifies that null checkEmailRef url throws proper exception. */
    @IsTest
    static void testLightningForgotPasswordControllerWithNullCheckEmailRef() {
    System.assertEquals(LightningForgotPasswordController.forgotPassword('a', null), 'Argument 1 cannot be null');
    System.assertEquals(LightningForgotPasswordController.forgotPassword('a@salesforce.com', null), 'Argument 1 cannot be null');
    }

    /* Verifies that LightningForgotPasswordController object is instantiated correctly. */
    @IsTest
    static void LightningForgotPasswordControllerInstantiation() {
    LightningForgotPasswordController controller = new LightningForgotPasswordController();
    System.assertNotEquals(controller, null);
    }

    // Sambath Seng 13.09.2021 US-0008409 - Upgrade code coverage of LightningForgotPasswordController from 50% to 85% [ lines not covered 9]
    @isTest
    static void testForgotPassword() {
        String result=LightningForgotPasswordController.forgotPassword('test@test.test', 'http://www.fake');
        System.assertEquals(null, result);
    }
    // Sambath Seng 13.09.2021 US-0008409 - Upgrade code coverage of LightningForgotPasswordController from 50% to 85% [ lines not covered 9]
    @isTest
    static void testSetExperienceId() {
        System.assertEquals(LightningForgotPasswordController.setExperienceId(null), null);
		String result = LightningForgotPasswordController.setExperienceId('1111111111');
        system.assert(String.isNotBlank(result));
    }
}