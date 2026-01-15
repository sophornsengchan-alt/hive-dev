/*********************************************************************************************************************************
@ Class:          VFLoginFlowController
@ Version:        1.0
@ Author:         Sarom Chetra (sarom.chetra@gaea-sys.com)
@ Purpose:        US-0013848 - Create NPS survey in VFpage instead of flow
@ 
@ Change history: 08.09.2023 / Vimean/ US-0014078 - Changes for US-0013848 Create NPS survey in VFpage instead of flow.      
@               : 26.09.2023/ vadhanak voun/ US-0013948 - Update NPS Logic - Exclude List of Executive Users
@ Change history: 16.02.2023 / Vimean/ US-0014432 - Create new record type and assign default for it.
@ Change history: 22.03.2024 / Vimean/ US-0014948 - NPS Survey - Randomize picklist answer ordering.
@               : 01.07.2024/ vadhanak voun/ US-0015436 - NPS Survey - Add Ask me later button
*********************************************************************************************************************************/
public with sharing class VFLoginFlowController {
    //NK:01/07/2024:US-0015436
    private final String HOME_PAGE_URL = '/lightning/page/home';

    public String reason {get; set;}
    public Integer rating {get; set;}
    public String reasonText {get; set;}
    public Boolean displayTopReasons {get; set;}
    public Boolean displayReason {get; set;}
    public Boolean loading {get; set;}
    private List<SelectOption> options = null;
    private final String ACTION_TYPE_EXCL = 'Exclude'; //NK:26/09/2023:US-0013948

    Map<String, String> MAP_NPS_SURVEY_REASON_OPTIONS = new Map<String, String>();

    final String OTHER_PLS_SPECIFY_IN_COMMENT_FIELD = 'Other_Pls_specify_in_comment_field';

    public List<SelectOption> getRatingOptions() {
        List<SelectOption> options = new List<SelectOption>();
        for(Integer i = 0; i < 11; i++)
        {
            options.add(new SelectOption(String.valueOf(i),String.valueOf(i)));
        }
        return options;
    }
    //@ Change history: 22.03.2024 / Vimean/ US-0014948 - NPS Survey - Randomize picklist answer ordering.
 	public List<SelectOption> getReasonOptions() {

        if (options != null) return options;

 	 	options = new List<SelectOption>();
        //VM US-0014948
        List<NPS_Survey_Reason_Options__mdt> listOp = [SELECT DeveloperName, Value__c,Order__c FROM NPS_Survey_Reason_Options__mdt ORDER BY Order__c ASC];
        if(!listOp.isEmpty()) {
            //suppose last index is Other (Please specify in comment field
            NPS_Survey_Reason_Options__mdt other = listOp.remove(listOp.size()-1);
            while(!listOp.isEmpty()){
                Integer randomIndex = (Math.random() * (listOp.size() -1)).intValue();
                NPS_Survey_Reason_Options__mdt SSRO = listOp[randomIndex];
                options.add(new SelectOption(SSRO.DeveloperName,SSRO.Value__c));
                MAP_NPS_SURVEY_REASON_OPTIONS.put(SSRO.DeveloperName,SSRO.Value__c);
                listOp.remove(randomIndex);
                
            }
            options.add(new SelectOption(other.DeveloperName,other.Value__c));
        }
        

        return options;
  	}

    /*****************************************************************************************************************************
    @ Method:   getShowLoginFlow
    @ Version:  1.0
    @ Author: 	Sarom Chetra (sarom.chetra@gaea-sys.com) 
    @ Purpose:	US-0013848 - Create NPS survey in VFpage instead of flow
    ------------------------------------------------------------------------------------------------------------------------------
    @ Parameter:     none
    ------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 08.09.2023 / Vimean/ US-0014078 - Changes for US-0013848 Create NPS survey in VFpage instead of flow.
    @               : 26.09.2023/ vadhanak voun/ US-0013948 - Update NPS Logic - Exclude List of Executive Users
    *****************************************************************************************************************************/
    public PageReference getShowLoginFlow(){
        User u =[select UserName, Last_NPS_Survey_Send_Date__c,createddate,Active_Approver__c, loginCount__c from user where id=:UserInfo.getUserId()];
        //NK:26/09/2023:US-0013948
        List<NPS_Users__mdt> listMeta = [Select User_Name__c,Action_Type__c,Active__c From NPS_Users__mdt Where User_Name__c=:u.UserName AND Action_Type__c=:ACTION_TYPE_EXCL AND Active__c=TRUE LIMIT 1];
        Date today_minus_90 = Date.today().addDays(Integer.valueOf(System.Label.NPS_Today_Minus_90));
        if ( listMeta.isEmpty() && (u.Last_NPS_Survey_Send_Date__c<today_minus_90 || (u.Last_NPS_Survey_Send_Date__c==null && u.createddate <today_minus_90)) && (u.Active_Approver__c == false && u.loginCount__c > 2)){
            return null;
        }else{
            return Auth.SessionManagement.finishLoginFlow();
        }
    }
    /**
        ...
        : 01.07.2024/ vadhanak voun/ US-0015436 - NPS Survey - Add Ask me later button
    */
    public PageReference finishLoginFlowStartUrl() {         
       
        //finish the login flow and send you to the startUrl (account page in this case)
        Auth.SessionManagement.finishLoginFlow();
        PageReference pgCurrent = ApexPages.currentPage();
        //NK:01/07/2024:US-0015436
        String retUrl = String.isBlank(pgCurrent.getParameters().get('retURL')) ?'/lightning/page/home':String.escapeSingleQuotes(pgCurrent.getParameters().get('retURL'));
        
        PageReference pageRef = new PageReference(retUrl);
        pageRef.setRedirect(true);
        return pageRef;
    }

    //Change history: 08.09.2023 / Vimean/ US-0014078 - Changes for US-0013848 Create NPS survey in VFpage instead of flow.
    //Change history: 16.02.20234 / Vimean/ US-0014432 - Create new record type and assign default for it.
    public PageReference saveRecord () {
        loading = true;
        try {
            NPS_Surveys_Replies__c nsr = new NPS_Surveys_Replies__c();
            nsr.Reply_question_1__c = String.valueOf(rating);
            nsr.Reply_question_2__c = reason == OTHER_PLS_SPECIFY_IN_COMMENT_FIELD || rating > 6? reasonText : '';//MAP_NPS_SURVEY_REASON_OPTIONS.get(reason); VM US-0014078
            nsr.Reply_question_3__c = rating < 7 ? MAP_NPS_SURVEY_REASON_OPTIONS.get(reason) : '';//VM US-0014078
            nsr.User__c = UserInfo.getUserId();
            nsr.Survey_Date__c = Date.today();
            nsr.RecordTypeId = Schema.SObjectType.NPS_Surveys_Replies__c.getRecordTypeInfosByDeveloperName().get('NPS_Survey').getRecordTypeId();//VM US-0014432
            Insert nsr;

            User u =[select loginCount__c, Last_NPS_Survey_Send_Date__c,createddate from user where id=:UserInfo.getUserId()];
            u.Last_NPS_Survey_Send_Date__c = Date.today();
            u.loginCount__c = u.loginCount__c + 1;
            update u;
        } catch (Exception ex) { 
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage())); return null; 
        }
        return null;
    }
    public void selectedRating(){
        displayTopReasons = rating > 6? true: false;
    }

    public void selectedReason(){
        displayReason = reason == OTHER_PLS_SPECIFY_IN_COMMENT_FIELD? true: false;
    }
}