/*********************************************************************************************************************************
@ Class:     ProjectAUOnboardingStageReportController
@ Version:       1.0
@ Author:        Mony Nou (mony.nou@gaea-sys.com)
@ Purpose:       US-0010922 - Report: Project Stage duration report
@----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 24.03.2022 / Mony Nou (mony.nou@gaea-sys.com) / US-0010922
*********************************************************************************************************************************/
public with sharing class ProjectAUOnboardingStageReportController {
    
    public String acqMngrName {get;set;}
    public String intMngrName {get;set;}
    public String reportFilterProjDurAcqMngr {get;set;}
    public String reportFilterProjDurIntMngr {get;set;}
    public String reportFilterCurProject {get;set;}
    public String reportFilterExistedProject {get;set;}

    public Boolean isProjDuration {get;set;}
    
    public ProjectAUOnboardingStageReportController() {

        //initialize variables
        initialize();

        String rp = (ApexPages.currentPage().getParameters().containsKey('rp'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('rp')+''):'';
        if (String.isNotBlank(rp) && rp.equalsIgnoreCase('duration')) isProjDuration = true;

        String id = (ApexPages.currentPage().getParameters().containsKey('id'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+''):'';
        
        //This is for Project Duration Report (AC2)
        if (isProjDuration) {

            String acqMngrId = (ApexPages.currentPage().getParameters().containsKey('id'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('acqMngr')+''):'';
            String intMngrId = (ApexPages.currentPage().getParameters().containsKey('id'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('intMngr')+''):'';
            List<String> lstProjDurAcqMngr = new List<String>{generateReportFilterField('CUST_ID','equals',id)};
            List<String> lstProjDurIngMngr = new List<String>{generateReportFilterField('CUST_ID','equals',id)};

            Map<String, String> mUsrName = new Map<String, String>();
        

            if (String.isNotBlank(acqMngrId)) mUsrName.put(acqMngrId, '');
            if (String.isNotBlank(intMngrId)) mUsrName.put(intMngrId, '');

            if (!mUsrName.isEmpty()) {
                for (User usr : [SELECT Id, Name FROM User WHERE ID IN:mUsrName.keySet()]) { mUsrName.put(usr.Id, usr.Name); } 

                if (mUsrName.containsKey(acqMngrId) && String.isNotBlank(mUsrName.get(acqMngrId))) {
                    acqMngrName = mUsrName.get(acqMngrId);
                    lstProjDurAcqMngr.add(generateReportFilterField('CHILD_CREATED_NAME','equals',acqMngrName));
                    
                }
                if (mUsrName.containsKey(intMngrId) && String.isNotBlank(mUsrName.get(intMngrId))) {
                    intMngrName = mUsrName.get(intMngrId);
                    lstProjDurIngMngr.add(generateReportFilterField('CHILD_CREATED_NAME','equals',intMngrName));
                }
            }
            

            reportFilterProjDurAcqMngr = generateReportFilterParam(lstProjDurAcqMngr);
            reportFilterProjDurIntMngr = generateReportFilterParam(lstProjDurIngMngr);

        } else { //This is for Project Duration Average Report (AC3)

            String stage = (ApexPages.currentPage().getParameters().containsKey('stage'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('stage')+''):'';
            String tm = (ApexPages.currentPage().getParameters().containsKey('tm'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('tm')+''):'';
            String proj = (ApexPages.currentPage().getParameters().containsKey('proj'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('proj')+''):'';
            String projTime = (ApexPages.currentPage().getParameters().containsKey('time'))?String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('time')+''):'';


            List<String> lstCurProjFilterColumn = new List<String>{generateReportFilterField('CUST_ID','equals',id)};
            List<String> lstExsProjFilterColumn = new List<String>{generateReportFilterField('CUST_ID','notEqual',id)};

            if (String.isNotBlank(stage) && !stage.equalsIgnoreCase('null')) {
                
                lstCurProjFilterColumn.add(generateReportFilterField('Project_Stage_History__c.Stage__c','equals',stage));
                lstExsProjFilterColumn.add(generateReportFilterField('Project_Stage_History__c.Stage__c','equals',stage));
            }

            

            if (String.isNotBlank(tm) && !tm.equalsIgnoreCase('null')) {

                for (User usr : [SELECT Name FROM User WHERE ID=:tm]) {
                    lstCurProjFilterColumn.add(generateReportFilterField('CHILD_CREATED_NAME','equals',usr.Name));
                    lstExsProjFilterColumn.add(generateReportFilterField('CHILD_CREATED_NAME','equals',usr.Name));

                } 
                
            }
            
            if (String.isNotBlank(proj) && !proj.equalsIgnoreCase('null')) {

                for (EBH_Project__c pro : [SELECT Name FROM EBH_Project__c WHERE ID=:proj]) {
                    lstExsProjFilterColumn.add(generateReportFilterField('CUST_NAME','equals',pro.Name));

                } 
                
            }

            if (String.isNotBlank(projTime) && !projTime.equalsIgnoreCase('null')) {

                lstExsProjFilterColumn.add(generateReportFilterField('CUST_CREATED_DATE','equals',projTime));
                
            }

            reportFilterCurProject = generateReportFilterParam(lstCurProjFilterColumn);
            reportFilterExistedProject = generateReportFilterParam(lstExsProjFilterColumn);

        }
        

    }

    private String generateReportFilterField(String column, String operator, String value) {
        Map<String, String> tmp = new Map<String, String>{
            'column' => column,
            'operator' => operator,
            'value' => value
        };
        return JSON.serialize(tmp);
        // String tmp = '{column:\''+column+'\',operator:\''+operator+'\',value:\''+value+'\'}';
        // return tmp;
    }

    private String generateReportFilterParam(List<String> lstFilterFields) {
        return '[' + String.join(lstFilterFields, ',') + ']';
    }

    private void initialize() {
        isProjDuration = false;
        acqMngrName = '';
        intMngrName = '';
        reportFilterProjDurAcqMngr = '';
        reportFilterProjDurIntMngr = '';
        reportFilterCurProject = '';
        reportFilterExistedProject = '';
        
    }



    ///////// Method for AURA 
    @AuraEnabled
    public static Map<String,Object> apexInit(String recId){
        
        Map<String,Object> mapResult = new Map<String,Object>();
        
        try {

            Set<String> sStage = new Set<String>();
            Map<String, String> mTeamMember = new Map<String, String>();
            Map<String, String> mExtProject = new Map<String, String>();

            for (AggregateResult agg : [SELECT CreatedById uid, CreatedBy.Name uname, Stage__c st FROM Project_Stage_History__c WHERE Project__c =:recId GROUP BY CreatedById, CreatedBy.Name,Stage__c]) {
                String stage = String.valueOf(agg.get('st'));   
                sStage.add(stage);

                String uid = String.valueOf(agg.get('uid'));
                String uname = String.valueOf(agg.get('uname'));
                if (!mTeamMember.containsKey(uid)) mTeamMember.put(uid,uname);
            }

            for (AggregateResult agg : [SELECT Id projId, Name projName FROM EBH_Project__c  WHERE Id !=:recId and (AcquisitionManager__c in:mTeamMember.keySet() or IntegrationManager__c IN:mTeamMember.keySet()) group by Id, Name]) {
                String projId = String.valueOf(agg.get('projId'));
                String projName = String.valueOf(agg.get('projName'));
                if (!mExtProject.containsKey(projId)) mExtProject.put(projId,projName);
            }

            mapResult.put('stages',sStage);
            mapResult.put('teamMember', mTeamMember);
            mapResult.put('extProjects', mExtProject);
            mapResult.put('status','ok');

        } catch (Exception ex) { mapResult.put('status','ko');mapResult.put('error',ex.getMessage());mapResult.put('errorDetail',ex.getStackTraceString()); }

        return mapResult;
    }

    
}