/*********************************************************************************************************************************
@ Change history: 13.03.2025 / Sovantheany Dim / US-0016373 - 14 - Seller Portal - Contract Sign Off 
*********************************************************************************************************************************/
import { LightningElement,api,wire } from 'lwc';
import { NavigationMixin,CurrentPageReference } from 'lightning/navigation';
import customLabels from 'c/customLabels';
import getSelectedSellerDeclineReason from '@salesforce/apex/SEPDealContractAgreementController.getSelectedSellerDeclineReason';
import doApproveOrDeclineDeals from '@salesforce/apex/SEPDealContractAgreementController.doApproveOrDeclineSubsidizeDeals';

export default class SubsidizedDealContractApproval extends NavigationMixin(LightningElement) {
    @api recId;
    labels = customLabels;
    onShowLoadingSpinner = false;
    mAllRecords = {};
    totalPage=0;
    selectedDeals = {};
    isCheckAgree = false;
    totalRecord = 0;
    isDeclineAllDeals = false;
    isModalOpen = false;
    optionsSellerDeclineReason = [];
    sellerDeclineReason;
    redirectToDealHome = false;
    redirectToApproveContract = false;
    dealStatusSellerApproved = 'Seller Approved';
    dealStatusSellerRejected = 'Seller Rejected';
    agreementTermUrl = '/s/user-guide?sb=dealAgreementTerms';

    renderedCallback() {
        if (this.redirectToDealHome) {
            this.redirectToURL(this.labels.UrlSubsidizedDCA);
        }else if(this.redirectToApproveContract){
            this.redirectToURL(this.labels.UrlSubsidizedDCA+'?'+this.labels.Subsidized_Approved_Contract_Tab);
        }
    }

    connectedCallback() {
        this.getSelectedSellerDeclineReason();
    }

    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.currentPageReference = currentPageReference;
            this.recId = currentPageReference.state?.recordId;
            //console.log('SubsidizedDealContractApproval recId = ' + this.recId);
        }
    }

    getSelectedSellerDeclineReason() {
        getSelectedSellerDeclineReason({ mdtName: 'Deal_Seller_Decline_Reason_US',objectApiName: 'EBH_Deal__c',fieldName: 'Seller_Decline_Reason__c'})
            .then(result => {
                for (let index in result){
                    this.optionsSellerDeclineReason.push({ label : index, value: result[index]});
                }
            })
            .catch(error => {
                this.showSpinner = false;
                console.log('Error in getting selected seller decline reason: ' + JSON.stringify(error));
            });
    }

    redirectToURL(toURL) {
        this[NavigationMixin.Navigate]({
            type: "standard__webPage",
            attributes: {
                url: toURL
            }
        })
    }

    updateCheckBox(event){
        this.mAllRecords = event.detail.mAllRecords;
        this.totalPage = event.detail.totalPage;
        let tmpMap = this.mAllRecords;
        let tmpArr = new Array();
        for (let i=1; i<=this.totalPage; i++) {
            let recPerPage = tmpMap[i];
            for (let j=0; j<recPerPage.length; j++) {
                let rec = recPerPage[j];
                if (rec.is_Checked) {
                    tmpArr.push(rec.Id);
                }
            }
        }
        this.selectedDeals = tmpArr;
    }

    updateTotalRecord(event) {
        this.totalRecord = event.detail.totalRecord;
    }

    handleCheckSignAgreement(event) {
        this.isCheckAgree = event.target.checked;   
    }

    handleGoBack() {
        this.redirectToURL(this.labels.UrlSubsidizedDCA);
    }

    handleDeclineAll() {
        if(this.totalRecord > 0){
            this.isDeclineAllDeals = true;
            this.isModalOpen = true;
        }
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
                    isSelectedAll : true, 
                    declineReason : this.sellerDeclineReason, 
                    status : this.dealStatusSellerRejected, 
                    dcaId : this.recId,
                    totalRecord : this.totalRecord
                })
                .then(result => {
                    //console.log('result : ',JSON.stringify(result));
                    if(result.status === "success"){
                        this.mAllRecords = {};
                        this.selectedDeals = {};
                        this.reloadListView();
                        this.isModalOpen = false;
                        this.onShowLoadingSpinner = false;
                        if(this.totalRecord - result.totalDealsUpdate === 0){
                            this.redirectToDealHome = true;
                            this.redirectToApproveContract = false;
                        }
                    }else if(result.status === "error") {
                        console.log('Error : ',result.error);
                        console.log('Error Detail : ',result.errorDetail);    
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
                    isSelectedAll : false, 
                    declineReason : this.sellerDeclineReason, 
                    status : this.dealStatusSellerRejected, 
                    dcaId : this.recId,
                    totalRecord : this.totalRecord
                })
                .then(result => {
                    if(result.status === "success"){
                        this.mAllRecords = {};
                        this.selectedDeals = {};
                        this.reloadListView();
                        this.isModalOpen = false;
                        this.onShowLoadingSpinner = false;
                        if(this.totalRecord - result.totalDealsUpdate === 0){
                            this.redirectToDealHome = true;
                            this.redirectToApproveContract = false;
                        }
                    }else if(result.status === "error") {
                        console.log('Error : ',result.error);
                        console.log('Error Detail : ',result.errorDetail);    
                    }
                })
                .catch(error => {
                    this.onShowLoadingSpinner = false;
                    console.log('Error : ',error);  
                });
            }
        }
    }

    handleApproveAll() {
        this.validateAgreementCheckBox();
        if(this.isValidForApprove()){
            this.onShowLoadingSpinner = true;
            doApproveOrDeclineDeals({
                dealIds : {}, 
                isSelectedAll : true, declineReason : '', 
                status : this.dealStatusSellerApproved, 
                dcaId : this.recId,
                totalRecord : this.totalRecord
            })
            .then(result => {
                if(result.status === "success"){
                    this.mAllRecords = {};
                    this.selectedDeals = {};
                    this.reloadListView();
                    if(result.attachmentId){
                        window.location.href = "https://"+window.location.hostname+"/sfc/servlet.shepherd/version/download/"+result.attachmentId+"?asPdf=false&operationContext=CHATTER";
                    }
                    if(this.totalRecord - result.totalDealsUpdate === 0){
                        this.redirectToApproveContract = true;
                        this.redirectToDealHome = false;
                    }
                    this.onShowLoadingSpinner = false;
                } else if(result.status === "error") {
                    this.onShowLoadingSpinner = false;
                    console.log('Error : ',result.error);
                    console.log('Error Detail : ',result.errorDetail);  
                }
            })
            .catch(error => {
                this.onShowLoadingSpinner = false;
                console.log('Error : ',error); 
            });
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

    isValidForApprove() {
        return this.isCheckAgree && this.totalRecord > 0;
    }

    handleSellerDeclineReasonChange(event) {
        this.sellerDeclineReason = event.detail.value;
    }

    closeModal() {
        this.isModalOpen = false;
        this.sellerDeclineReason = '';
    }

    @api reloadListView() {
        let child_lwc = this.template.querySelector('c-lwc-list-view');
        child_lwc.reloadPage();
    }
}