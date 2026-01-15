/*****************************************************************************************************************************************************************
@ Class:          DECouponBCDContractApprovedContr
@ Version:        1.0
@ Author:         Bora Chhorn (bora.chhorn@gaea-sys.com)
----------------------------------------------------------------------------------------------------------------------------------------------------------
@ Created the class :  Bora Chhorn / 19.05.2023 / US-0012890 - Step 4: Notify GCX
***********************************************************************************************************************************************************/
public with sharing class DECouponBCDContractApprovedContr {

    private final String APPROVED = 'Approved';
    private final String DF_DD_MM_YYYY_HH_MM = 'dd/MM/yyyy hh:mm';
    
    public String bcdId{set;get;}
    public String fileContent{set;get;}
    public String fileName{set;get;}
    public Boolean hasAtt{set;get;}
    public BCD_Statement__c bcd{set;get;}
    public List<ApprovalStepWrapper> listApprStep{set;get;}
    public String link{set;get;}

    /*********************************************************************************************************************************
    @ Method:         getPage
    @ Version:        1.0
    @ Author:         Bora Chhorn (bora.chhorn@gaea-sys.com)
    @ Purpose:        US-0012890 - Step 4: Notify GCX
    ----------------------------------------------------------------------------------------------------------------------------------
    @ Created method :  Bora Chhorn / 19.05.2023 / US-0012890 - Step 4: Notify GCX
    *********************************************************************************************************************************/
    public DECouponBCDContractApprovedContr getPage() {

        bcd = new BCD_Statement__c();
        listApprStep = new List<ApprovalStepWrapper>();
        List<BCD_Statement__c> listBcd = [Select Id, Number_of_sellers__c, Coupon__r.Name, CurrencyIsoCode, Credit_Total_Value__c, Total_Amount_Other_Currency__c, Credit_Total_Value_USD__c, Accounts_to_be_debited__c, Name, Coupon_Code__c, BCD_File_SF_Id__c From BCD_Statement__c Where Id =: bcdId Limit 1];
        if(listBcd.isEmpty()) return this;
        bcd = listBcd[0];

        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        link = baseUrl + '/' + bcd.Id;

        List<ProcessInstance> listProInst = [SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: bcd.Id Order By Id Desc];
        
        if(!listProInst.isEmpty()){

            Set<Id> setStepNodeId = new Set<Id>();
            List<ProcessInstanceStep> listStep = new List<ProcessInstanceStep>();

            for(ProcessInstanceStep step : [SELECT Id, StepNodeId, StepStatus,CreatedDate, ProcessInstanceId, OriginalActor.Name, Actor.Name, Comments FROM ProcessInstanceStep Where StepStatus =: APPROVED AND ProcessInstanceId IN: listProInst Order By Id Asc]){
                listStep.add(step);
                setStepNodeId.add(step.StepNodeId);
            }

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