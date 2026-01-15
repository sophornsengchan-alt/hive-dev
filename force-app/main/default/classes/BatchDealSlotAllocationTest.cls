@isTest
private class BatchDealSlotAllocationTest {
    @TestSetup
    static void setup(){
        DealSlotMapping__c ds1 = new DealSlotMapping__c();
        ds1.Name = '1';
        ds1.Day__c = 'Monday';
        ds1.Slot__c = 4;
        ds1.Vertical__c = 'Electronics';
        
        DealSlotMapping__c ds2 = new DealSlotMapping__c();
        ds2.Name = '2';
        ds2.Day__c = 'Tuesday';
        ds2.Slot__c = 5;
        ds2.Vertical__c = 'Electronics';
        
        DealSlotMapping__c ds3 = new DealSlotMapping__c();
        ds3.Name = '3';
        ds3.Day__c = 'Wednesday';
        ds3.Slot__c = 5;
        ds3.Vertical__c = 'Electronics';
        
        DealSlotMapping__c ds4 = new DealSlotMapping__c();
        ds4.Name = '4';
        ds4.Day__c = 'Thursday';
        ds4.Slot__c = 5;
        ds4.Vertical__c = 'Electronics';
        
        DealSlotMapping__c ds5 = new DealSlotMapping__c();
        ds5.Name = '5';
        ds5.Day__c = 'Friday';
        ds5.Slot__c = 5;
        ds5.Vertical__c = 'Electronics';
        
        DealSlotMapping__c ds6 = new DealSlotMapping__c();
        ds6.Name = '6';
        ds6.Day__c = 'Saturday';
        ds6.Slot__c = 5;
        ds6.Vertical__c = 'Electronics';
            
        DealSlotMapping__c ds7 = new DealSlotMapping__c();
        ds7.Name = '7';
        ds7.Day__c = 'Sunday';
        ds7.Slot__c = 5;
        ds7.Vertical__c = 'Electronics';
        insert new List<DealSlotMapping__c>{ds1, ds2, ds3, ds4, ds5, ds6, ds7};
    }
    @isTest
    static void populate12WeeksSlotTest(){
        String hour = String.valueOf(Datetime.now().hour());
        String min = String.valueOf(Datetime.now().minute()); 
        String ss = String.valueOf(Datetime.now().second() + 5);
        String nextFireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        Test.startTest();
            BatchDealSlotAllocation s = new BatchDealSlotAllocation(); 
            System.schedule('Schedule to Insert Deal Sloth Allocation', nextFireTime,s);
        Test.stopTest();
        List<EBH_DealSlotAllocation__c> lstDSA = [SELECT Id FROM EBH_DealSlotAllocation__c];
        System.assert(lstDSA.size() == BatchDealSlotAllocation.default12WeekNum*7, 'EBH_DealSlotAllocation__c should created = ' + BatchDealSlotAllocation.default12WeekNum*7 + ', Actual = ' + lstDSA.size());        
    }
}