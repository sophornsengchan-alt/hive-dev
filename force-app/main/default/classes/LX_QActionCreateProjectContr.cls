/*********************************************************************************************************************************
@ Class:         LX_QActionCreateProjectContr
@ Version:       1.0
@ Author:        Acmatac Seing (acmatac.seing@gaea-sys.com)
@ Purpose:       US-0006890 [AU] Priority Changes required for Soft Launch 9th Dec
@ AuraComp:      LX_QActionCreateProject.cmp
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 03.12.2019 / Acmatac Seing (acmatac.seing@gaea-sys.com) / Created the class.
@ Change history: 14.12.2022 / Bora Chhorn (bora.chhorn@gaea-sys.com) / US-0011835 - Clean Lead Layouts (Technical Debt)
*********************************************************************************************************************************/

public without sharing class LX_QActionCreateProjectContr {

    private static Map<String, String> mProjectLead = new Map<String, String>{
        'Lead__c' => 'Id',
        'LeadSegment__c' => 'LeadSegment__c',
        'LeadSource__c' => 'LeadSource',
        'OtherLeadSource__c' => 'OtherLeadSource__c',
        'Campaign__c' => 'Campaign__c',
        'Website__c' => 'Website',
        'OtherMarketPlaces__c' => 'EBH_OtherMarketplaces__c',
        'OnlineRank__c' => 'OnlineRank__c',
        'Comments__c' => 'EBH_CommentsBusinessReview__c',
        'ShippingTechnology__c' => 'ShippingTechnology__c',
        'Theoretical_Revenue__c' => 'TheoreticalRevenue__c',
        'Site__c' => 'Site__c'
    };

    private static Map<String, String> mRT_LeadProject = new Map<String, String>{
        // 'EBH_eBayAUEnterprise' => 'eBayAUEnterprise', //BR-US-0011835
        'EBH_eBayAUSMB' => 'eBayAUSMB'
    };

/**************** 
* Public Method
*******/

    @AuraEnabled
    public static Map<String, Object> doGetLead(String recordId) {
        Map<String, Object> mResult = new Map<String, Object>();

        try{
            String queryStr = 'SELECT RecordType.DeveloperName, Status, '+ String.join((Iterable<String>)mProjectLead.values(), ',') +' FROM Lead WHERE Id =: recordId';
            Lead oLead = Database.query(queryStr);
            Map<String, Object> mField = new Map<String, Object>();
            for(String projField : mProjectLead.keySet()){
                Object val = oLead.get(mProjectLead.get(projField));
                if(val == null){
                    // lookup field null => continue
                    if(projField == 'Campaign__c'){
                    	continue;
                    }else{
                        val = '';
                    }
                }
                mField.put(projField, val);
            }
            // Set default project recordtype by lead
            String projRT = mRT_LeadProject.get(''+oLead.getSObject('RecordType').get('DeveloperName'));
            mResult.put('status', oLead.Status);
            mResult.put('recordTypeId', ApexUtil.getRecordTypeByName('EBH_Project__c', projRT).Id);
            mResult.put('params', mField);

            mResult.put('isSuccess', true);
        } catch (Exception ex) {
            mResult.put('isSuccess', false);
            mResult.put('msg', ex.getMessage());
            //mResult.put('msg', ex.getMessage()+ ', ' +ex.getStackTraceString());
        }

        return mResult;
    }


/****************
* Public Method End
*******/

}