/**
 * @description Test unit for coverage on SitePickList class
 * @createdDate 27-Oct-2021
 * @author      Samnang MUONG
 */
@isTest
private class SitePickListTest {
    
    @isTest static void test_SitePickList() {
        SitePickList spl = new SitePickList();
        spl.getDefaultValue();
        spl.getValues();
    }
}