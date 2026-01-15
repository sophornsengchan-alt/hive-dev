public with sharing class KnowledgeSearchController {
    
    //Get knowledge articles which contains input text
    @AuraEnabled(cacheable=true)
    public static List<Knowledge__kav> getKnowledgeArticles(String searchText) {
        List<Knowledge__kav> knowledgeArticlesList = new List<Knowledge__kav>();
        if (searchText != '' && searchText != null) {
            for(Knowledge__kav kav : [SELECT Id, Title, Summary,Question__c,CreatedDate,ArticleCaseAttachCount,ArticleTotalViewCount,KnowledgeArticleId FROM Knowledge__kav where PublishStatus='Online']) {
                if((kav.Title != null && kav.Title.contains(searchText)) || (kav.Question__c != null && kav.Question__c.contains(searchText)))
                    knowledgeArticlesList.add(kav);
            }
        }
        return knowledgeArticlesList;
    }

}