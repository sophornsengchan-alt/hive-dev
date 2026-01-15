/*****************************************************************************************************************************
@ Class:        SidebarLinkRegionPicklistTest
@ Version:      1.0
@Author:        Sambath Seng (sambath.seng@gaea-sys.com)
------------------------------------------------------------------------------------------------------------------------------
@ Change history: 18-3-2022 / Sambath Seng / US-0011390 - Refactor Useful Links for new Permission Model
*****************************************************************************************************************************/
@isTest
private class SidebarLinkRegionPicklistTest {
    @isTest static void testSidebarLinkRegionPicklist() {
        SidebarLinkRegionPicklist spl = new SidebarLinkRegionPicklist();
        spl.getDefaultValue();
        spl.getValues();
    }
}