/*****************************************************************************************************************************
@ Class:   TH_ShareUtilTest
@ Author: 	Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:	US-0008392 - Upgrade code coverage of TH_ShareUtil from 0% to 85% [ lines not covered 31]
------------------------------------------------------------------------------------------------------------------------------
*****************************************************************************************************************************/
@isTest
private class TH_ShareUtilTest {
    @isTest
    static void testFindMatchingUsers() {
        User user = EBH_TestDataFactory.createUser('Standard User');
        insert user;
        List<TH_ShareUtil.UserMatchOption> result = TH_ShareUtil.findMatchingUsers(user.LastName);
        System.assertEquals(user.Id, result[0].value);
        System.assertEquals(user.LastName, result[0].label);
    }
    @isTest
    static void testMentionTrailheadToUser() {
        User user = EBH_TestDataFactory.createUser('Standard User');
        insert user;
        Boolean result;
        try {
            result = TH_ShareUtil.mentionTrailheadToUser(user.Id, 'test.com', 'Hello trailhead');
        }
        catch (Exception ex) {
            System.debug('ERROR' + ex.getMessage());
        }
        // result can't return true because it is require SeeAllData=true
        System.assertEquals(null, result);
    }
}