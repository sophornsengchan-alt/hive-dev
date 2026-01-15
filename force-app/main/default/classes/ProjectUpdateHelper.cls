/*********************************************************************************************************************************
@ Class:          ProjectUpdateHelper
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
@ Purpose:        US-0014671 - Tech debt - Migrate Process Builder to Trigger
----------------------------------------------------------------------------------------------------------------------------------
@ Change history:  25.01.2023 / Sophal Noch / Created the class.
*********************************************************************************************************************************/
public with sharing class ProjectUpdateHelper {
    
    private final String SOQL_RELATED_AU_PROJ = 'Select Id From EBH_Project__c Where EBH_Seller__c IN ( {0} ) AND EBH_Stage__c = \'Store Launched\' AND RecordType.DeveloperName = \'eBayAUSMB\'';
    private String PROJ_STAGE_LIVE_TO_SITE = 'Live to Site';
    
    private String accIds;
    private Boolean isSecCheck = true;
    private List<EBH_Project__c> listProjToUpdate = new List<EBH_Project__c> ();
    private Date currentDate = Date.today();

    private ProjectUpdateHelper setIsSecCheck(Boolean isSecCheck){
       this.isSecCheck = isSecCheck;
       return this;
    }

    private ProjectUpdateHelper setAccIds(Set<String> setAccId){
        this.accIds = ApexUtil.constructQuoteString(setAccId);
        return this;
    }

    private ProjectUpdateHelper retrievRelatedAUProject(){

        String soqlRelatedAUProj = String.format(SOQL_RELATED_AU_PROJ, new String[]{accIds});
        List<EBH_Project__c> listProj = ApexSafe.query().secCheck(isSecCheck).doQuery(soqlRelatedAUProj); 

        if(!listProj.isEmpty()){
            for(EBH_Project__c proj : listProj){
                proj.EBH_Stage__c = PROJ_STAGE_LIVE_TO_SITE;
                proj.ActualLiveToSite__c = currentDate;
                listProjToUpdate.add(proj);
            }
        }

        return this;
    }

    private ProjectUpdateHelper updateListProject(){
        if(!listProjToUpdate.isEmpty()){ 
            ApexSafe.dml().secCheck(isSecCheck).doUpdate(listProjToUpdate, true );
        }
        return this;
    }

    /*********************************************************************************************************************************
    @ Method:         updateRelatedAUProject
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0014671 - Tech debt - Migrate Process Builder to Trigger
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  25.01.2023 / Sophal Noch / Created the method.
    *********************************************************************************************************************************/
    public static void updateRelatedAUProject(Set<String> setAccId){
        new ProjectUpdateHelper().setIsSecCheck(false)  // method call from trigger, so isSecCheck from ApexSafe is set to false
                                .setAccIds(setAccId).retrievRelatedAUProject()
                                .updateListProject();
    }

}