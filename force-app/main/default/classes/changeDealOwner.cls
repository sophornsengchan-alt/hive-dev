/**
* @Description   :  This class used for changing Deal owners in bulk from Deal list view - a feature that's not YET available in Lightning.
*/

public class changeDealOwner {

    public EBH_Deal__c objDeaL {get;set;}
    public List<EBH_Deal__c> lstSelectedDeals {get;set;}
    public Boolean boolSendEmailOptionchk {get;set;}
    ApexPages.StandardSetController stdSetCtlr;
    String strPageRef;
    
    public changeDealOwner(ApexPages.StandardSetController controller) {
        boolSendEmailOptionchk = false;
        stdSetCtlr = controller;
        objDeal = new EBH_Deal__c(); 
        lstSelectedDeals = new List<EBH_Deal__c>();
        if(UserInfo.getUiThemeDisplayed() == 'Theme4d') {
        	//NK:30/04/2018: [EPH-5580] SFDC Change of Lightning URL format- In House Check for custom codes
            //strPageRef = '/one/one.app?source=aloha#/sObject/EBH_Deal__c/list?filterName='+stdSetCtlr.getFilterId();
            strPageRef = '/lightning/o/EBH_Deal__c/list?filterName='+stdSetCtlr.getFilterId(); 
        }
        else {
            strPageRef = '/00Q?fcf='+stdSetCtlr.getFilterId();
        }
    }

    public pageReference updateDealOwnerAction() {

        for (EBH_Deal__c d : (EBH_Deal__c[])stdSetCtlr.getSelected()) {
            EBH_Deal__c objD = new EBH_Deal__c(Id = d.Id,
                                 OwnerId = objDeal.OwnerId);
            lstSelectedDeals.add(objD);
        }
        
        Database.DMLOptions dlo = new Database.DMLOptions();
        dlo.EmailHeader.triggerAutoResponseEmail = boolSendEmailOptionchk;
        dlo.EmailHeader.triggerUserEmail = boolSendEmailOptionchk;
        Database.update(lstSelectedDeals, dlo);
        
        return new Pagereference(strPageRef);
    }
    
    public pageReference cancelAction() {
        return new Pagereference(strPageRef);
    }
}