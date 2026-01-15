/**
 * Test class for DealAgreementPDFController
 */
@isTest
private class DealAgreementPDFControllerTest {
    
    @isTest 
    public static void test_DealAgreementPDFController1(){

        Test.startTest();

            Test.setCurrentPage(Page.DealAgreementPDF);
            Apexpages.currentPage().getParameters().put('vfcmp', 'Deal_Agreement_CA_Quebec');
            DealAgreementPDFController cntrl = new DealAgreementPDFController();
            ApexPages.Component vfcmp = cntrl.getCustomComponent();

            System.assert(vfcmp != null, 'there should has VF Component initiated.');

        Test.stopTest();
    }

    @isTest 
    public static void test_DealAgreementPDFController2(){

        Test.startTest();

            Test.setCurrentPage(Page.DealAgreementPDF);
            Apexpages.currentPage().getParameters().put('vfcmp', 'Deal_Agreement_CA_Standard');
            DealAgreementPDFController cntrl = new DealAgreementPDFController();
            ApexPages.Component vfcmp = cntrl.getCustomComponent();

            System.assert(vfcmp != null, 'there should has VF Component initiated.');

        Test.stopTest();
    }

    @isTest 
    public static void test_DealAgreementPDFController3(){

        Test.startTest();

            Test.setCurrentPage(Page.DealAgreementPDF);
            Apexpages.currentPage().getParameters().put('vfcmp', 'Deal_Agreement_US_Standard');
            DealAgreementPDFController cntrl = new DealAgreementPDFController();
            ApexPages.Component vfcmp = cntrl.getCustomComponent();

            System.assert(vfcmp != null, 'there should has VF Component initiated.');

        Test.stopTest();
    }

    @isTest 
    public static void test_DealAgreementPDFController4(){

        Test.startTest();

            Test.setCurrentPage(Page.DealAgreementPDF);
            DealAgreementPDFController cntrl = new DealAgreementPDFController();
            ApexPages.Component vfcmp = cntrl.getCustomComponent();

            System.assert(vfcmp != null, 'there should has VF Component initiated.');

        Test.stopTest();
    }
}