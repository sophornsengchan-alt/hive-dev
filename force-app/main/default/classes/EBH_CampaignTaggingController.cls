/*********************************************************************************************************************************
@ Class:          EBH_CampaignTaggingController 
@ Version:        1.0
@ Author:         Neha Lund
@ Purpose:        Controller Class for EBH_CampaignTagging page 
EPH-5797 : Move control group to Target List
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 22.05.2018 / NEHA LUND / Created the class.
*********************************************************************************************************************************/
Public class EBH_CampaignTaggingController {

    public String tags {set;get;}
    public boolean duplicateValue {set;get;}
    public Set<String> duplicates {set;get;}
    Id campaignId;
    public EBH_CampaignTaggingController (ApexPages.StandardController controller) {
        duplicates = new Set<String>();
        campaignId = controller.getRecord().Id;
        duplicateValue = false;
    }

    public PageReference updatePicklistField()
    {
        duplicateValue = false;

        duplicates = new Set<String>();
        //Get the details of the current picklist as we need to include the existing values
        SobjectType objType    = Schema.getGlobalDescribe().get('Campaign');
        Map<String,Schema.SObjectField> objFields = objType.getDescribe().fields.getMap();
        SObjectField fieldName = objFields.get('EBH_Tags__c');
        Schema.DescribeFieldResult fieldResult = fieldName.getDescribe();
        fieldResult = fieldResult.getSObjectField().getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();


        EBH_MetadataService.MetadataPort service = new EBH_MetadataService.MetadataPort();
        service.SessionHeader = new EBH_MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();
        EBH_MetadataService.Picklist pt = new EBH_MetadataService.Picklist();
        List<EBH_MetadataService.PicklistValue> ptv = new list<EBH_MetadataService.PicklistValue>();
        pt.sorted= true;
        EBH_MetadataService.PicklistValue toadd;
        tags = tags.replaceAll('\r\n','\n');

        Set<String> uniqueValues = new Set<String>();
        //Add Existing values back in
        for (Schema.PicklistEntry pl : ple){
            if (pl.isActive()){
                EBH_metadataservice.PicklistValue existingPLValue = new ebH_metadataservice.PicklistValue();
                existingPLValue.fullName  = pl.getValue();
                existingPLValue.default_x = pl.isDefaultValue();
                uniqueValues.add(pl.getValue());
                ptv.add(existingPLValue);
            }
        }

        for(string s: tags.split('\n')){

            if( !String.isBlank(s)){
                toAdd = new EBH_MetadataService.PicklistValue();


                toadd.fullName = s;
                toadd.default_x = false ;

                if(!uniqueValues.contains(s)){
                    ptv.add(toadd);
                    uniqueValues.add(s);
                }
                else{
                    duplicates.add(s);
                    duplicateValue = true;
                }
            }
        }


        if( !duplicateValue){

            pt.picklistValues = ptv;
            EBH_MetadataService.CustomField customField = new EBH_MetadataService.CustomField();
            customField.fullName = 'Campaign.EBH_Tags__c';
            customField.label = 'Tags';  // you can change the label on the fly as well
            customField.type_x = 'MultiselectPicklist'; 

            customField.visibleLines = 5;  // only for multipicklist
            customField.picklist = pt ;

            EBH_MetadataService.UpdateMetadata ut = new EBH_MetadataService.UpdateMetadata();
            ut.currentName = 'Campaign.EBH_Tags__c';
            ut.metadata= customField;
            if(!test.isRunningTest())
            EBH_MetadataService.AsyncResult[] results = service.updateMetadata(new List<EBH_MetadataService.updateMetadata> {ut});



            List<EBH_MetadataService.updateMetadata> recordTypeUpdates = new List<EBH_MetadataService.updateMetadata>();
            ut = new EBH_MetadataService.UpdateMetadata();
            EBH_MetadataService.RecordTypePicklistValue ohmVersions = new EBH_MetadataService.RecordTypePicklistValue();
            ohmVersions.Picklist = 'EBH_Tags__c';
            ohmVersions.values = ptv;

            for(RecordType rtName: [SELECT name, developername, description from RecordType where sobjectType = 'Campaign' and
            (developerName = 'EBH_Campaign' OR developerName = 'EBH_CampaignRequest' )
            and isActive = true]){

            EBH_MetadataService.RecordType rt = new EBH_MetadataService.RecordType();
            rt.active = true;
            rt.fullName = 'Campaign.'+rtname.DeveloperName;
            rt.description = rtname.description;
            rt.label = rtname.Name;
            rt.PicklistValues = new EBH_MetadataService.RecordTypePicklistValue[] { ohmVersions };
            ut = new EBH_MetadataService.UpdateMetadata();
            ut.currentName = 'Campaign.'+rtname.DeveloperName;
            ut.metadata= rt;
            recordTypeUpdates.add(ut);
            }
            
            if(!Test.isRunningTest())
            service.updateMetadata(recordTypeUpdates );
            
            recordTypeUpdates = new List<EBH_MetadataService.updateMetadata>();
            ut = new EBH_MetadataService.UpdateMetadata();
            for(RecordType rtName: [SELECT name, developername, description from RecordType where sobjectType = 'Campaign' and
            ( developerName = 'EBH_SubCampaign' )
            and isActive = true]){

            EBH_MetadataService.RecordType rt = new EBH_MetadataService.RecordType();
            rt.active = true;
            rt.fullName = 'Campaign.'+rtname.DeveloperName;
            rt.label = rtname.Name;
            rt.description = rtname.description;
            rt.PicklistValues = new EBH_MetadataService.RecordTypePicklistValue[] { ohmVersions };
            ut = new EBH_MetadataService.UpdateMetadata();
            ut.currentName = 'Campaign.'+rtname.DeveloperName;
            ut.metadata= rt;
            recordTypeUpdates.add(ut);
            }
        
        if(!Test.isRunningTest())
        service.updateMetadata(recordTypeUpdates );

        return new PageReference(EBH_ConstantsUtility.TCC_SLASH +campaignId);
        }
        return null;
    }
}