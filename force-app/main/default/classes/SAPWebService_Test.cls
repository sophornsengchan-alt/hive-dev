@isTest
private class SAPWebService_Test {

    static testmethod void testWithDatesGrouping1and2() {

            SAP_WebService__c sws = new SAP_WebService__c();
            sws.name = 'TEST';
            sws.sap_id__c = 'TEST';

            sws.aggregate_query__c = 'SELECT Seller_Name__r.EBH_RegistrationCountry__c country, CALENDAR_YEAR(createdDate) grp1, CALENDAR_MONTH(createdDate) grp2, SUM(Cost_Share_Seller_LC__c) val FROM Coupon_Co_Invest__c  WHERE Seller_Name__r.EBH_RegistrationCountry__c IN ({!criteria1}) AND Seller_Name__r.EBH_RegistrationCountry__c = {!criteria2} GROUP BY Seller_Name__r.EBH_RegistrationCountry__c, CALENDAR_YEAR(createdDate), CALENDAR_MONTH(createdDate) ORDER BY Seller_Name__r.EBH_RegistrationCountry__c,CALENDAR_YEAR(createdDate), CALENDAR_MONTH(createdDate)  ';
            sws.line_item_static_text__c = 'TEST {!grp1} {!grp2}';

            sws.document_type__c = 'Z2';
            sws.header_static_text__c = 'TEST'; 
            insert sws;

            SAP_Webservice_GL_Line__c sgl1 = new SAP_Webservice_GL_Line__c();
            sgl1.sap_webservice__c = sws.id;
            sgl1.gl_code__c = '12345';
            insert sgl1;

            SAP_Webservice_GL_Line__c sgl2 = new SAP_Webservice_GL_Line__c();
            sgl2.sap_webservice__c = sws.id;
            sgl2.gl_code__c = '67890';
            insert sgl2;


            id accSellerRT = [SELECT id FROM recordType WHERE sobjecttype = 'Account' AND name = 'Seller'].id;

            Account customer = new Account(name='TEST', recordTypeId=accSellerRT, EBH_RegistrationCountry__c = 'UK');
            insert customer;

            Coupon__c coupon = new Coupon__c(coupon_id__c = 'TEST',Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra');
            insert coupon;

            Decimal coInvAmount = 123.45;
            Coupon_Co_Invest__c cci = new Coupon_Co_Invest__c();
            cci.seller_name__c = customer.id;
            cci.coupon_name__c = coupon.id;
            cci.Co_Invest__c = coInvAmount;
            cci.Contra_LC__c = 100;
            insert cci;

            Test.startTest();

            String response = SAPWebService.getRecords(sws.sap_id__c, String.valueOf(SYSTEM.TODAY()), String.valueOf(SYSTEM.TODAY()), 'DE,UK', 'UK');

            Test.stopTest();

            JSONParser jp = JSON.createParser(response);
            jp.nextValue();
            while (jp.hasCurrentToken()) {
                if (jp.getCurrentName() != null) {
                    System.debug('>>>>' + jp.getCurrentName() + ':' + jp.getText());
                    if (jp.getCurrentName().startsWith('DL04')) {System.assertEquals(coInvAmount, Decimal.valueOf(jp.getText()));}
                    if (jp.getCurrentName().startsWith('FT03')) {System.assertEquals(3, Integer.valueOf(jp.getText()));}
                    if (jp.getCurrentName().startsWith('DL19')) {System.assert(jp.getText().contains(System.now().format('MMM')));}
                    
                }
                jp.nextValue();
            }


 }
 static testmethod void testWithStringGrouping1() {

    SAP_WebService__c sws = new SAP_WebService__c();
    sws.name = 'TEST';
    sws.sap_id__c = 'TEST';
    sws.aggregate_query__c = 'SELECT Seller_Name__r.EBH_RegistrationCountry__c country, coupon_name__c grp1, SUM(Cost_Share_Seller_LC__c) val FROM Coupon_Co_Invest__c  WHERE Seller_Name__r.EBH_RegistrationCountry__c IN ({!criteria1}) AND Seller_Name__r.EBH_RegistrationCountry__c = {!criteria2} GROUP BY Seller_Name__r.EBH_RegistrationCountry__c, coupon_name__c ORDER BY Seller_Name__r.EBH_RegistrationCountry__c,coupon_name__c  ';
    sws.line_item_static_text__c = 'TEST {!grp1} ';
    sws.document_type__c = 'Z2';
    sws.header_static_text__c = 'TEST'; 
    insert sws;

    SAP_Webservice_GL_Line__c sgl1 = new SAP_Webservice_GL_Line__c();
    sgl1.sap_webservice__c = sws.id;
    sgl1.gl_code__c = '12345';
    sgl1.Tax_Code__c = 'OBZT';
    insert sgl1;

    SAP_Webservice_GL_Line__c sgl2 = new SAP_Webservice_GL_Line__c();
    sgl2.sap_webservice__c = sws.id;
    sgl2.gl_code__c = '67890';
    sgl2.Tax_Code__c = 'OBZT';
    insert sgl2;


    id accSellerRT = [SELECT id FROM recordType WHERE sobjecttype = 'Account' AND name = 'Seller'].id;

    Account customer = new Account(name='TEST', recordTypeId=accSellerRT, EBH_RegistrationCountry__c = 'UK');
    insert customer;

    Coupon__c coupon = new Coupon__c(coupon_id__c = 'TEST',Main_Coupon_Site__c = 'ebay.de',Coupon_Co_invest_Type__c='Contra');
    insert coupon;

    Decimal coInvAmount = 123.45;
    Coupon_Co_Invest__c cci = new Coupon_Co_Invest__c();
    cci.seller_name__c = customer.id;
    cci.coupon_name__c = coupon.id;
    cci.Co_Invest__c = coInvAmount;
    cci.Contra_LC__c = 100;
    insert cci;

    Test.startTest();
    String response = SAPWebService.getRecords(sws.sap_id__c, String.valueOf(SYSTEM.TODAY()), String.valueOf(SYSTEM.TODAY()), 'DE,UK', 'UK');
    Test.stopTest();

    JSONParser jp = JSON.createParser(response);
    jp.nextValue();
    while (jp.hasCurrentToken()) {
        if (jp.getCurrentName() != null) {
            System.debug('>>>>' + jp.getCurrentName() + ':' + jp.getText());
            if (jp.getCurrentName().startsWith('DL04')) {System.assertEquals(coInvAmount, Decimal.valueOf(jp.getText()));}
            if (jp.getCurrentName().startsWith('FT03')) {System.assertEquals(3, Integer.valueOf(jp.getText()));}
            if (jp.getCurrentName().startsWith('DL19')) {System.assert(jp.getText().contains(cci.coupon_name__c));}
            if (jp.getCurrentName() == 'DL05_TaxCode') {System.assertEquals(jp.getText(), 'OBZT');}
                }
                jp.nextValue();
            }


 }
}