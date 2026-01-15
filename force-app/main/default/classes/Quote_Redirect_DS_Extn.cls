public with sharing class Quote_Redirect_DS_Extn {

    private String quoteId;
    public String nonce {get; private set;}

    public Quote_Redirect_DS_Extn(ApexPages.StandardController controller) {
        quoteId = ((Quote)controller.getRecord()).Id   ;
        nonce = ApexPages.currentPage().getParameters().get('nonce');  
    }
}