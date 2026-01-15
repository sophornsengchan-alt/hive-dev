public with sharing class QuoteGenerateAndDocusignController {
    
    private static String pageName = ApexPages.currentPage().getParameters().get('page');
    private static String id  = ApexPages.currentPage().getParameters().get('Id');
    private static String nonce  = ApexPages.currentPage().getParameters().get('nonce');

    private static Quote q = [SELECT id, name,QuoteNumber, opportunityId FROM quote WHERE id = :id];

    public static String quoteId {get; private set;}

    public static PageReference doGenerate() {

        quoteId = id;

        PageReference pDF = new PageReference('/apex/' + pageName);
        
        pDF.getParameters().put('Id',quoteId);

        Blob b = (Test.isRunningTest())?Blob.valueOf('testBody'):pDF.getContentAsPDF();
        String filename = 'Quote_'+q.QuoteNumber +'_'+System.now().format('YYYY-MM-DD_HH:mm:SS');
        
        // Create the content which will be sent to Docusign
        ContentVersion cv = createContentVersion(b, filename, 'pdf', quoteId);
        insert cv;


        return null;
    }


    private static ContentVersion createContentVersion(Blob body, String fileName, String fileExt, Id locationId) {
        ContentVersion conver = new ContentVersion();
        conver.Title = fileName;
        conver.PathOnClient = fileName + (String.isNotBlank(fileExt)?'.':'') + fileExt;
        conver.VersionData = body;
        conver.Origin = 'H';
        conver.FirstPublishLocationId = locationId;
        return conver;
    }

}