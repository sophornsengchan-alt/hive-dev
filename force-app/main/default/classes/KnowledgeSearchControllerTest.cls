@isTest
public class KnowledgeSearchControllerTest {

    @TestSetup
    static void setup() {


        User adminUser = EBH_TestDataFactory.createUser('System Administrator');
        adminUser.UserPermissionsKnowledgeUser  = true;
        insert adminUser;

        System.runAs(adminUser) {
        // Create a Knowledge Article
        Knowledge__kav kav = new Knowledge__kav();
        kav.Title = 'Hive Knowledge Article23' + String.valueOf(Crypto.getRandomInteger());
        kav.UrlName = 'Hive-Article';
        kav.Language = 'en_US';
        //kav.PublishStatus = 'Online';
        insert kav;
        
        knowledge__kav obj1 = [SELECT Id,Title,KnowledgeArticleId FROM knowledge__kav WHERE id =: kav.Id];
        
        // Publish the Knowledge Article
        KbManagement.PublishingService.publishArticle(obj1.KnowledgeArticleId , true);
        }
    }
    
    @isTest static void testGetKnowledgeArticles() {
        
        List<Knowledge__kav> result1 = KnowledgeSearchController.getKnowledgeArticles('');
        System.assertEquals(0, result1.size(), 'Expected empty list when searchText is empty');
        
        // Test case 2: Verify that the method returns an empty list when searchText is null
        List<Knowledge__kav> result2 = KnowledgeSearchController.getKnowledgeArticles(null);
        System.assertEquals(0, result2.size(), 'Expected empty list when searchText is null');
        
        // Test case 3: Verify that the method returns the correct knowledge articles when searchText matches the title
        String searchText3 = 'Hive';
        List<Knowledge__kav> result3 = KnowledgeSearchController.getKnowledgeArticles(searchText3);
        for (Knowledge__kav article : result3) {
            System.assert(article.Title.contains(searchText3) || article.Question__c.contains(searchText3), 'Expected searchText to match title or question');
        }
        
        // Test case 4: Verify that the method returns the correct knowledge articles when searchText matches the question
        String searchText4 = 'Contract';
        List<Knowledge__kav> result4 = KnowledgeSearchController.getKnowledgeArticles(searchText4);
        for (Knowledge__kav article : result4) {
            System.assert(article.Title.contains(searchText4) || article.Question__c.contains(searchText4), 'Expected searchText to match title or question');
        }
        
        // Add more test cases as needed
    }
    
}