/*****************************************************************************************************************************************************************
@ Class:          BCDContractApprovedController
@ Version:        1.0
@ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Change history: Sophal Noch / 14.10.2022 / US-0012073 Created the class.
@               : Srong TIN   / 03.11.2023 / US-0014247 - Hive BCD E-Mail approval 
***********************************************************************************************************************************************************/
public with sharing class BCDContractApprovedController {
    private static final String STATUS_NO_RESPONSE = 'NoResponse';
    private static final String STATUS_STARTED = 'Started';
    private static final Set<String> UNNEEDED_STATUSES = new Set<String>{STATUS_NO_RESPONSE, STATUS_STARTED};

    private final static String DF_DD_MM_YYYY_HH_MM = 'dd/MM/yyyy hh:mm';

    public String bcdId{set;get;}
    public String fileContent{set;get;}
    public String fileName{set;get;}
    public Boolean hasAtt{set;get;}

    public BCD_Statement__c bcd{set;get;}

    public String link{set;get;}

    public List<ApprovalStepWrapper> listApprStep{set;get;}

    /*********************************************************************************************************************************
    @ Method:         getPage
    @ Version:        1.0
    @ Author:         Sophal Noch (sophal.noch@gaea-sys.com)
    @ Purpose:        US-0012073 - Email Alert to GCX Bill and Care
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Change history:  Sophal Noch / 14.10.2022 / US-0012073 Created the method
    @               : Srong TIN   / 03.11.2023 / US-0014247 - Hive BCD E-Mail approval 
    *********************************************************************************************************************************/
    public BCDContractApprovedController getPage() {

        // controller for visual force component page BCDContractApproved.

        bcd = new BCD_Statement__c();
        listApprStep = new List<ApprovalStepWrapper>();
        //SRONG/03.11.2023/US-0014247/ Added fields to query: Number_of_sellers__c,Credit_Total_Value__c,CurrencyIsoCode,Credit_Total_Value_USD__c,Accounts_to_be_debited__c
        List<BCD_Statement__c> listBcd = [Select Id,Name,Credit_Total_Value_USD__c,Accounts_to_be_debited__c,Number_of_sellers__c,CurrencyIsoCode,Credit_Total_Value__c,Total_Amount_Other_Currency__c, BCD_Statement_Quarter__c,BCD_Statement_Year__c,Rev_RollUp__c,BCD_File_SF_Id__c From BCD_Statement__c Where Id =: bcdId Limit 1];
        if(listBcd.isEmpty()) return this;
        bcd = listBcd[0];

        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        link = baseUrl + '/' + bcd.Id;

        // 1 ProcessInstance one record can has multiple ProcessInstances so get the latest one by order by desc.
        List<ProcessInstance> listProInst = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: bcd.Id Order By Id Desc Limit 1];
        
        if(!listProInst.isEmpty()){

            Set<Id> setStepNodeId = new Set<Id>();
            List<ProcessInstanceStep> listStep = new List<ProcessInstanceStep>();
            // 1 ProcessInstance has multiple approval steps, query them below
            for(ProcessInstanceStep step : [SELECT Id, StepNodeId, StepStatus,CreatedDate, ProcessInstanceId, OriginalActor.Name, Actor.Name, Comments FROM ProcessInstanceStep Where StepStatus Not In : UNNEEDED_STATUSES AND ProcessInstanceId = :listProInst[0].Id Order By Id Asc]){
                listStep.add(step);
                setStepNodeId.add(step.StepNodeId);
            }
    
            // ProcessInstanceStep does not have Name field, ProcessInstanceStep.StepNodeId can not look up to ProcessNode.
            // so we have to query ProcessNode by ProcessInstanceStep.StepNodeId below
            Map<Id,ProcessNode> mapSetpNode = new Map<Id,ProcessNode>([SELECT Id, Name FROM ProcessNode where Id IN: setStepNodeId]);
    
            for(ProcessInstanceStep step : listStep){
    
                ProcessNode proNode = mapSetpNode.get(step.StepNodeId);
                String stepNodeName = proNode != null ? proNode.Name : '';
                ApprovalStepWrapper apprStepWrapper = new ApprovalStepWrapper(
                    stepNodeName,
                    step.CreatedDate.format(DF_DD_MM_YYYY_HH_MM),
                    step.StepStatus != null ? step.StepStatus : '',
                    step.OriginalActor?.Name != null ? step.OriginalActor.Name : '',
                    step.Actor?.Name != null ? step.Actor.Name : '',
                    step.Comments != null ? step.Comments : ''
                );
    
                listApprStep.add(apprStepWrapper);
            }
        }

        // BCD_File_SF_Id__c is id to the ContentVersion. It is csv file.
        if(String.isNotBlank(bcd.BCD_File_SF_Id__c)){
            List<ContentVersion> listContVer = [SELECT Id, Title,FileExtension, VersionData FROM ContentVersion Where Id = : bcd.BCD_File_SF_Id__c Limit 1];
            if(!listContVer.isEmpty()){
                hasAtt = true;
                fileContent = listContVer[0].VersionData.toString();
                fileName = listContVer[0].Title + '.' + listContVer[0].FileExtension;
            }
        }

        return this;
       
    }

    private class ApprovalStepWrapper{
        public String name{set;get;}
        public String apprDate{set;get;}
        public String status{set;get;}
        public String ogAppr{set;get;}
        public String cAppr{set;get;}
        public String cmt{set;get;}
        ApprovalStepWrapper( String name, String apprDate, String status, String ogAppr, String cAppr, String cmt){
            this.name = name;
            this.apprDate = apprDate;
            this.status = status;
            this.ogAppr = ogAppr;
            this.cAppr = cAppr;
            this.cmt = cmt;
        }
    }
}