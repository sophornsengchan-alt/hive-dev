import { LightningElement,track,wire } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import hasPermission from '@salesforce/customPermission/US_Manage_Deals';
import customLabels from 'c/customLabels';
import { getRecord } from 'lightning/uiRecordApi';


export default class DealImportExcel extends NavigationMixin(LightningElement) {

    parentId;
    templateName='';
    msgPopUp='';
    isShowConfirmButton = false;
    labels = customLabels;
    showSpinner = true;
    blockMessage = {showMessage:false,type:"",msg:"",msgDetail:""};
    dcaPermissionUpdateDeal = false;
    FIELDS = ['Deal_Contract_Agreement__c.Status__c'];

    @track showConfirmDialog = false;
    @track showImportCmp = false;

    onActionHandler(e){
        this.showSpinner = false;
        this.showConfirmDialog= false;
        if(e.detail.status === 'confirm'){
            this.showImportCmp = true;
        }else{
            this.doGoBack();
        }
        
    }
    connectedCallback(){
    }
    init(){
        
        if(hasPermission){
            this.msgPopUp = this.labels.Deal_Import_Confirm_Message;
        }else{
            this.showConfirmDialog  = true;
            this.msgPopUp = this.labels.Deal_No_Permission_Import;
        }
    }
    
    checkDCAStatus(status){
        this.dcaPermissionUpdateDeal = status != 'Seller Rejected' && status != 'Sent to Seller' && status != 'Seller Approved'; 
        this.isShowConfirmButton = this.dcaPermissionUpdateDeal;
        this.showConfirmDialog  = true;
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        this.showSpinner = true;
        if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.parentId = currentPageReference.state?.c__parentId;
            this.templateName = currentPageReference.state?.c__template
            if(this.parentId === undefined){
                this.parentId = currentPageReference.attributes?.attributes?.c__parentId;
            }
            if(this.templateName === undefined){
                this.templateName = currentPageReference.attributes?.attributes?.c__template
            }
            this.init();
        }
    }

    doGoBack(){
        this[ NavigationMixin.GenerateUrl ]( {
            type: 'standard__recordPage',
            //type: 'standard__recordRelationshipPage',
            attributes: {
                recordId: this.parentId,
                objectApiName: 'Deal_Contract_Agreement__c',
                //relationshipApiName: 'Deals__r',
                actionName: 'view'
            }
        } ).then((url) => {
            window.open(url, '_self');
        });
    }
    
    get isShowImportCmp(){
        return this.showImportCmp && this.dcaPermissionUpdateDeal;
    }

    @wire(getRecord, { recordId: '$parentId', fields: '$FIELDS'} )
    wiredRecord({ error, data }) 
    {
        if (data && hasPermission) {
            let status =  data.fields["Status__c"].value;
            this.checkDCAStatus(status);
        }
    }
}