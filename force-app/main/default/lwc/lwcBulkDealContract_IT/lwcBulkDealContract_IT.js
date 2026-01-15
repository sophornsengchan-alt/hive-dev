/*********************************************************************************************************************************
@ Author:         Sambath Seng (sambath.seng@gaea-sys.com)
@ Purpose:        US-0013450 - 2. Deal Contract agreement page/ Approve and Decline Actions: Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 19.05.2023 / Sambath Seng / Create component
*********************************************************************************************************************************/
import { LightningElement,wire,track,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import ErrorMissingAgreementCheckBox from '@salesforce/label/c.SEPBulkDealContract_ErrorMissingAgreementCheckBox';
import btnApproveAll from '@salesforce/label/c.SEPBulkDealContract_ApproveAll';
import btnDeclineAll from '@salesforce/label/c.SEPBulkDealContract_DeclineAll';
import btnApproveSelected from '@salesforce/label/c.SEPBulkDealContract_ApproveSelected'; 
import btnDeclineSelected from '@salesforce/label/c.SEPBulkDealContract_DeclineSelected'; 
import btnMoreAction from '@salesforce/label/c.SEPBulkDealContract_MoreAction'; 
import lbDeclineReason from '@salesforce/label/c.SEPBulkDealContract_DeclineReason';
import lbDeclineReasonPlaceholder from '@salesforce/label/c.SEPBulkDealContract_DeclineReasonPlaceholder';
import lbCheckboxAgree from '@salesforce/label/c.SEPBulkDealContract_CheckboxLabel';
import lbTCagreement from '@salesforce/label/c.SEPBulkDealContract_TC';
import btnCancel from '@salesforce/label/c.Cancel'; 
import btnSave from '@salesforce/label/c.Save'; 
//import getAllPickListValue from '@salesforce/apex/SEPCouponController.getAllPickListValue';
import getSelectedSellerDeclineReason from '@salesforce/apex/SEPDealContractAgreementController.getSelectedSellerDeclineReason';//TH:US-0016373: comment out getAllPickListValue and used getSelectedSellerDeclineReason to get selected seller decline reason from metadata
import doApproveOrDeclineDeals from '@salesforce/apex/SEPDealContractAgreementController.doApproveOrDeclineDeals';
import generateApprovedPDF from '@salesforce/apex/SEPDealContractAgreementController.generateDealApprovedPDF';
import apexGetAccounts from '@salesforce/apex/AccountPickerController.getDEEligibleAccounts';

export default class LwcBulkDealContract_IT extends NavigationMixin(LightningElement) {

    isCheckAgree = false;
    showTC = false;
    mAllRecords = {};
    selectedDeals = {};
    totalRecord = 0;
    totalPage=0;
    isModalOpen = false;
    optionsSellerDeclineReason;
    sellerDeclineReason;
    onShowLoadingSpinner = false;
    isDeclineAllDeals = false;
    dealStatusSellerApproved = 'Seller Approved';
    dealStatusSellerRejected = 'Seller Rejected';
    isLinkedAccounts = false;
    sellerId = '';
    redirectToDealHome = false;
    @track additionalFilter;

    labels = {ErrorMissingAgreementCheckBox
        ,btnApproveAll
        ,btnDeclineAll
        ,btnApproveSelected
        ,btnDeclineSelected
        ,btnMoreAction
        ,btnCancel
        ,btnSave
        ,lbDeclineReason
        ,lbDeclineReasonPlaceholder
        ,lbCheckboxAgree
        ,lbTCagreement
    };

    connectedCallback() {
        this.additionalFilter = " AND EBH_BusinessName__c =\'" + this.sellerId +"\'";
        getSelectedSellerDeclineReason({mdtName: 'Deal_Seller_Decline_Reason_IT',objectApiName: 'EBH_Deal__c',fieldName: 'Seller_Decline_Reason__c'})
        .then(result => {
            this.optionsSellerDeclineReason = this.sellerDeclineReasonsOptions(result);
        })
        .catch(error => {
            this.showSpinner = false;
        });

        this.doGetAccounts();
    }

    renderedCallback() {
        if (this.redirectToDealHome) {
            this.redirectToURL('/my-deal-lists');
        }
    }

    sellerDeclineReasonsOptions(data) {
        let opts = [];
        if (data) {
            for (var index in data){
                opts.push({ label : index, value: data[index]});
            }
        }
        return opts;
    }

    handleCheckSignAgreement(event) {
        this.isCheckAgree = event.target.checked;   
    }

    handleApproveAll() {
        this.validateAgreementCheckBox();
        if(this.isValidForApprove(true)){
            this.onShowLoadingSpinner = true;
            doApproveOrDeclineDeals({
                dealIds : {}, 
                isSelected : false, declineReason : '', 
                status : this.dealStatusSellerApproved, 
                sellerId : this.sellerId
            })
            .then(result => {
                if(result["status"] == "success"){
                    this.mAllRecords = {};
                    this.selectedDeals = {};
                    this.reloadListView();
                    if(result['generateApprovedPDF']){
                        this.handleGenerateApprovedPDF(result.newDcaId)
                    }else{
                        this.onShowLoadingSpinner = false;
                    }
                } else if(result["status"] == "error") {
                    this.onShowLoadingSpinner = false;
                    console.log(result["error"]);
                    console.log(result["errorDetail"]);  
                }
            })
            .catch(error => {
                this.onShowLoadingSpinner = false;
                console.log('Error : ',error); 
            });
        }
    }

    handleDeclineAll() {
        if(this.totalRecord > 0){
            this.isDeclineAllDeals = true;
            this.isModalOpen = true;
        }
    }

    handleApproveSelected() {
        this.validateAgreementCheckBox();
        if(this.isValidForApprove(false)){
            this.onShowLoadingSpinner = true;

            doApproveOrDeclineDeals({
                dealIds : this.selectedDeals, 
                isSelected : true, 
                declineReason : '', 
                status : this.dealStatusSellerApproved, 
                sellerId : this.sellerId
            })
            .then(result => {
                if(result["status"] == "success"){
                    this.mAllRecords = {};
                    this.selectedDeals = {};
                    this.reloadListView();
                    if(result['generateApprovedPDF']){
                        this.handleGenerateApprovedPDF(result.newDcaId)
                    }else{
                        this.onShowLoadingSpinner = false;
                    }
                }else if(result["status"] == "error") {
                    this.onShowLoadingSpinner = false;
                    console.log(result["error"]);
                    console.log(result["errorDetail"]);    
                }
            })
            .catch(error => {
                this.onShowLoadingSpinner = false;
                console.log('Error : ',error);  
            });
        }
    }

    handleGenerateApprovedPDF(dcaId){
        generateApprovedPDF({dcaId : dcaId})
        .then(result => {
            if(result["status"] == "success"){
                this.onShowLoadingSpinner = false;
                this.getPDFDownload(result.attachmentId);
                if(this.totalRecord == 0){
                    this.redirectToDealHome = true;
                }
            } else if(result["status"] == "error") {
                this.onShowLoadingSpinner = false;
                console.log(result["error"]);
                console.log(result["errorDetail"]);  
            }
        })
        .catch(error => {
            this.onShowLoadingSpinner = false;
            console.log('Error generate pdf : ',error); 
        });
    }

    handleDeclineSelected() {
        if(Object.keys(this.selectedDeals).length > 0){
            this.isDeclineAllDeals = false;
            this.isModalOpen = true;
        }
    }

    handleSubmitDecline() {
        let declineReasonInput = this.template.querySelector('.Seller_Decline_Reason__c');
        if(!declineReasonInput.checkValidity()){
            declineReasonInput.reportValidity();
        }else{
            if(this.isDeclineAllDeals){
                this.onShowLoadingSpinner = true;
                doApproveOrDeclineDeals({
                    dealIds : {}, 
                    isSelected : false, 
                    declineReason : this.sellerDeclineReason, 
                    status : this.dealStatusSellerRejected, 
                    sellerId : this.sellerId
                })
                .then(result => {
                    if(result["status"] == "success"){
                        this.mAllRecords = {};
                        this.selectedDeals = {};
                        this.reloadListView();
                        this.isModalOpen = false;
                        this.onShowLoadingSpinner = false;
                        if(this.totalRecord - result.totalDealsUpdate == 0){
                            this.redirectToDealHome = true;
                        }
                    }else if(result["status"] == "error") {
                        console.log(result["error"]);
                        console.log(result["errorDetail"]);    
                    }
                })
                .catch(error => {
                    this.onShowLoadingSpinner = false;
                    console.log('Error : ',error);  
                });
            } else {
                this.onShowLoadingSpinner = true;

                doApproveOrDeclineDeals({
                    dealIds : this.selectedDeals, 
                    isSelected : true, 
                    declineReason : this.sellerDeclineReason, 
                    status : this.dealStatusSellerRejected, 
                    sellerId : this.sellerId
                })
                .then(result => {
                    if(result["status"] == "success"){
                        this.mAllRecords = {};
                        this.selectedDeals = {};
                        this.reloadListView();
                        this.isModalOpen = false;
                        this.onShowLoadingSpinner = false;
                        if(this.totalRecord - result.totalDealsUpdate == 0){
                            this.redirectToDealHome = true;
                        }
                    }else if(result["status"] == "error") {
                        console.log(result["error"]);
                        console.log(result["errorDetail"]);    
                    }
                })
                .catch(error => {
                    this.onShowLoadingSpinner = false;
                    console.log('Error : ',error);  
                });
            }
        }
    }

    validateAgreementCheckBox() {
        let statusCheckbox = this.template.querySelector('.agreementCheckbox');
        if(!this.isCheckAgree){
            statusCheckbox.setCustomValidity(this.labels.ErrorMissingAgreementCheckBox);
        }else{
            statusCheckbox.setCustomValidity('');
        }
        statusCheckbox.reportValidity();
    }

    onAgreementTermSEPInit(event){
        let init = event.detail["init"];
        if(init){
            this.showLoadingSpinner = false;
        }
    }

    openTC() {
        this.showTC = true;
    }

    onAgreementTermSEPAccepted(event){
        this.showTC = false;
    }

    updateCheckBox(event){
        this.mAllRecords = event.detail["mAllRecords"];
        this.totalPage = event.detail["totalPage"];
        var tmpMap = this.mAllRecords;
        var tmpArr = new Array();
        for (var i=1; i<=this.totalPage; i++) {
            var recPerPage = tmpMap[i];
            for (var j=0; j<recPerPage.length; j++) {
                var rec = recPerPage[j];
                if (rec.is_Checked) {
                    tmpArr.push(rec.Id);
                }
            }
        }
        this.selectedDeals = tmpArr;
    }

    updateTotalRecord(event) {
        this.totalRecord = event.detail["totalRecord"];
    }

    closeModal() {
        this.isModalOpen = false;
        this.sellerDeclineReason = '';
    }

    handleSellerDeclineReasonChange(event) {
        this.sellerDeclineReason = event.detail.value;
    }

    @api reloadListView() {
        let child_lwc = this.template.querySelector('c-lwc-list-view');
        child_lwc.reloadPage();
    }

    getPDFDownload(attId) {
        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+attId+"?asPdf=false&operationContext=CHATTER"
    }

    isValidForApprove(isApproveAll) {
        if (isApproveAll) {
            return this.isCheckAgree && this.totalRecord > 0;
        }  else {
            return this.isCheckAgree && Object.keys(this.selectedDeals).length > 0;
        }
    }

    redirectToURL(toURL) {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: toURL
            }
        })
    }

    handleAccountChange(event) {
        this.sellerId = event.detail["selectedVal"];
        this.additionalFilter = " AND EBH_BusinessName__c =\'" + this.sellerId +"\'";
    }

    doGetAccounts() {        
        apexGetAccounts()
        .then(result => {
            let accResult = result.accRelationCoupons;
            if (accResult.length > 1 ) {
                 this.isLinkedAccounts = true;
            }
        }).catch(error => {
            console.log("apexGetAccounts error",error);
        });
    }

    get checkButtonAvailability() {
        if(this.isLinkedAccounts && this.sellerId != ''){
            return true;
        } else if(this.isLinkedAccounts && this.sellerId == '') {
            return false;
        } else {
            return true;
        }
    }

}