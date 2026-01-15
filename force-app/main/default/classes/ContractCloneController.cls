public class ContractCloneController {
    /*********************************************************************************************************************************
    @ Method:         getAttachments
    @ Version:        1.0
    @ Author:         SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:        US-0014235 - Contract Cloning Flow
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:    List<ContenVersion> ContentVersion_Selected_Records
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  05.04.2024 / Srong tin / Created the method.
    *********************************************************************************************************************************/
    @InvocableMethod(label='getAttachments' description='get Attachments Notes')
    public static List<String> getAttachments(List<Id> contenVersionIds) {
        List<String> documentId = new List<String>();
        List<ContentVersion> newConvList = new List<ContentVersion>();
        
        for( ContentVersion conV : [SELECT Title, ContentLocation,Origin,PathOnClient, VersionData FROM ContentVersion WHERE Id in: contenVersionIds]){
            ContentVersion newConv = new ContentVersion();
            newConv.Title = conV.Title;
            newConv.ContentLocation = conV.ContentLocation;
            newConv.Origin = conV.Origin;
            newConv.PathOnClient = conV.PathOnClient;
            newConv.VersionData = conV.VersionData;
            newConvList.add(newConv);
        }
        insert newConvList;
        for(ContentVersion conv: [SELECT Id,ContentDocumentId FROM ContentVersion WHERE Id in: newConvList]){
            documentId.add(conv.ContentDocumentId);
        }
        return documentId;   
    }
}