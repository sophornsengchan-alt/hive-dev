@isTest
private class InfluencerServiceTest {
     
    @IsTest
    static void testgetUserInformation(){
        
        Test.startTest();
            InfluencerService.CustomParameter cp = new InfluencerService.CustomParameter();
            cp.target = 'instagram_business_discovery';
            cp.url = 'https://www.instagram.com/justinbieber/';
            InfluencerService.getUserInformation(new List<InfluencerService.CustomParameter>{cp});
        Test.stopTest();
        
    }

    @IsTest
    static void testgetUserInformation2(){
        
        Test.startTest();
            InfluencerService.CustomParameter cp = new InfluencerService.CustomParameter();
            cp.target = 'wrong_service';
            cp.url = 'https://www.instagram.com/justinbieber/';
            InfluencerService.getUserInformation(new List<InfluencerService.CustomParameter>{cp});
        Test.stopTest();
        
    }

    @IsTest
    static void testgetUserInformation3(){
        
        Test.startTest();
            InfluencerService.CustomParameter cp = new InfluencerService.CustomParameter();
            cp.target = 'instagram_business_discovery';
            cp.url = 'wrong_url';
            InfluencerService.getUserInformation(new List<InfluencerService.CustomParameter>{cp});
        Test.stopTest();
        
    }
}