/*********************************************************************************************************************************
@ Class:          Coupon_AU_CS_BriefController
@ Version:        1.0
@ Author:         SRONG TIN (srong.tin@gaea-sys.com)
@ Purpose:        US-0011787 - AU Coupon CS Brief Email Template
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 06.09.2022 / SRONG TIN / Created the class.
*********************************************************************************************************************************/
public class Coupon_AU_CS_BriefController {
    public List<EmailPreviewWrapper> lstEmailPrevWrapper {get;set;}
    private String recordId {get;set;}
    private Coupon__c currentCoupon {get;set;}
    private EmailTemplate et {get;set;}

    public Coupon_AU_CS_BriefController(ApexPages.StandardSetController controller) {
        lstEmailPrevWrapper = new List<EmailPreviewWrapper>();
        recordId = String.escapeSingleQuotes(ApexPages.currentPage().getParameters().get('id')+'');
        String templateName = System.Label.AU_CS_Brief_Email_Template_Name;
        et = [SELECT Id, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templateName];
    }
    /***********************************************************************************************************************************
    @ Method:       initialize 
    @ Version:      1.0
    @ Author:       SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:      US-0011787 - AU Coupon CS Brief Email Template

    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2022 / SRONG TIN / Created the class.
    ***********************************************************************************************************************************/
    public void initialize() {
        currentCoupon = [Select Id,
                                OwnerId,
                                SendCSBriefEmail__c
                        From Coupon__c 
                        Where Id = :recordId];
        // preview email              
        generateEmailPreview(currentCoupon);
    }

    /***********************************************************************************************************************************
    @ Method:       generateEmailPreview 
    @ Version:      1.0
    @ Author:       SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:      US-0011787 - AU Coupon CS Brief Email Template
    @ Parameter:    currentCoupon: Coupon

    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2022 / SRONG TIN / Created the class.
    ***********************************************************************************************************************************/
    public void generateEmailPreview(Coupon__c currentCoupon){

        List<string> toAddress = new List<string>();
        toAddress.add(System.Label.DL_eBay_GCX_AU);
        toAddress.add(System.Label.DL_eBay_AU_BuyerEngagementTeam);
        toAddress.add(System.Label.DL_eBay_AU_RP_CSBrief_GrowthManagers);
        
        EmailPreviewWrapper epw = new EmailPreviewWrapper();
        epw.to_addresses = String.join(toAddress, ', ');
        Messaging.SingleEmailMessage mail = Messaging.renderStoredEmailTemplate(et.Id, currentCoupon.OwnerId, currentCoupon.Id);
        // System.debug('1.Number of Queries used in this apex code so far: ' + Limits.getQueries());
        mail.setToAddresses(toAddress);                  
        mail.setSaveAsActivity(false);

        List<Messaging.SingleEmailMessage> lstEmail = new List<Messaging.SingleEmailMessage>();
        lstEmail.add(mail);
        Messaging.SingleEmailMessage errorEmail = new Messaging.SingleEmailMessage();
        lstEmail.add(errorEmail);
        String strPrevEmail='';
        try {
            List<Messaging.SendEmailResult> previewResult = Messaging.sendEmail(lstEmail);
        }
        catch (Exception ex) { strPrevEmail = mail.getHtmlBody(); }
        
        epw.email_prev_body = strPrevEmail;
        lstEmailPrevWrapper.add(epw);
    }

    public PageReference cancel(){
        PageReference page = new PageReference('/'+recordId);
        page.setRedirect(true);
        return page;
    }

    public PageReference send(){
        try {
            currentCoupon.SendCSBriefEmail__c = Datetime.now();
            PageReference page = new PageReference('/'+recordId);
            page.setRedirect(true);
            update currentCoupon;
            return page;
        } catch (Exception ex) {
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR,ex.getMessage()));
            return null;
        }
    }


    /***********************************************************************************************************************************
    @ Method:       doInitData 
    @ Version:      1.0
    @ Author:       SRONG TIN (srong.tin@gaea-sys.com)
    @ Purpose:      US-0011787 - AU Coupon CS Brief Email Template
    @ Parameter:    recordId: Coupon id
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Returns  Map<String,Object>
    ------------------------------------------------------------------------------------------------------------------------------------
    @ Change history: 06.09.2022 / SRONG TIN / Created the class.
    ***********************************************************************************************************************************/
    @AuraEnabled
    public static Map<String,Object> doInitData(String recordId)
    {
    	Map<String,Object> mapResult = new Map<String,Object>();
        List<Coupon__c> lstCoupon = [Select Id,RecordTypeId From Coupon__c Where Id = :recordId];
        String couponCateType = System.Label.Coupon_Seller_Category_based;
        String recordTypeId = ApexUtil.getRecordTypeByName('Coupon__c',couponCateType).Id;
        String PERMISSION_COUPONSPECIALPERMISSION = System.Label.Coupon_Special_Permission_Set;
    	Boolean isAdmin = (Userinfo.getprofileId() == ApexUtil.ADMIN_PROFILE_ID || Userinfo.getprofileId() == ApexUtil.ADMIN_LT_PRIV_PROFILE_ID);
    	Boolean isCouponSpecialPermission = ApexUtil.checkPermissionSet(new Set<String>{PERMISSION_COUPONSPECIALPERMISSION});
        mapResult.put('isCategoryType',(recordTypeId == lstCoupon[0].recordTypeId));
    	mapResult.put('isHasPermission',(isCouponSpecialPermission || isAdmin ));
    	mapResult.put('status','ok');
    	return mapResult;
    }

   
    public class EmailPreviewWrapper {

        public String email_prev_body {get;set;}
        public String to_addresses {get;set;}
        public String cc_addresses {get;set;}

    }
}