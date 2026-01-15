/*********************************************************************************************************************************
@ Class:        BookAccountManager
@ Author:       Acmatac Seing
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.12.2023 / Acmatac Seing / US-0014494 - Moving Book Account Manager logic from lwcAccountManagement
*********************************************************************************************************************************/
import { api, LightningElement, wire, track } from 'lwc';
import customLabel from 'c/customLabels';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import { NavigationMixin } from 'lightning/navigation';
// START import apex methods
import getAccountManagementMetadata from '@salesforce/apex/AccountManagementController.getAccountManagementMetadata';
import getActiveCohortSeller from '@salesforce/apex/AccountManagementController.getActiveCohortSeller'; //MN-23122021-US-0010562
import createSubscription from '@salesforce/apex/AccountManagementController.createSubscription';
import requestUnsubscription from '@salesforce/apex/AccountManagementController.requestUnsubscription';//LA-24-12-2021-US-0010563
import getSellerInfo from '@salesforce/apex/AccountManagementController.getSellerInfo';
// END import apex methods

export default class BookAccountManager extends NavigationMixin(LightningElement) {
    label = customLabel;
    @api errors;
    @api metadataName;
    @api selectedSeller;

    showSpinner = true;

    zeroMetadataValue;
    thirdMetadataValue;
    secondMetadataValue;
    firstMetadataValue;
    accountManagementMetadata;
    
    isPlatinum = false; // 10.02.2023 / Sophal Noch / US-0011132
    sellerOptions = [];// Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    accounts = [];// Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    fallbackProfilePic = this.label.ACC_MNG_DEFAULT_PROFILE_PIC; // 06.02.2023 / Sophal Noch / US-0011132
    optOutEftDate = ''; // 06.02.2023 / Sophal Noch / US-0011132
    registrationCountry = '';//TH:US-0014060
    accountManagerInfo = null; //MN-23122021-US-0010562
    isModalOpen = false;
    isUnsubModalOpen = false; //MN-30012023-US-0010832
    subscription = null; //already subscribed
    showPageContent = false;// Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
    eligibleFor_BookAM = false; //AMT 12.01.24 Hide Subscribe to AM button if the seller is not eligible for Book Account Manager

    // START Get Set
    get labelAmMsgUnsubscribeRequest() { // 06.02.2023 / Sophal Noch / US-0011132
        var tmp = '';
        var sellerName = '';
        if ((this.subscription && this.subscription.Seller__r && this.subscription.Seller__r.Name)) sellerName = this.subscription.Seller__r.Name;

        if (this.label.AM_MSG_UNSUBSCRIBE_REQUEST) {
            tmp = this.label.AM_MSG_UNSUBSCRIBE_REQUEST;
            tmp = tmp.replace("{!Seller__r.Name}", sellerName);
            tmp = tmp.replace("{!Opt_Out_Effective_Date__c}", this.optOutEftDate);
        }
        return tmp;
    }
    get accMgmntFound() { // 06.02.2023 / Sophal Noch / US-0011132
        var tmp = false;
        if (this.accountManagerInfo && this.accountManagerInfo.Id && this.accountManagerInfo.Id != "") tmp = true;
        return tmp;
    }
    get isEnableUnsubscrBtn() { // 10.02.2023 / Sophal Noch / US-0011132
        var tmp = false;
        // if (this.isSubscribed && this.registrationCountry == "Germany" && this.accountManagerInfo && this.accountManagerInfo.Id && this.accountManagerInfo.Id != "") tmp = true;//TH:11.09.23:US-0014060 - Change to the Account Manager Display Logic
        // Acmatac Seing, 12.1.24, US-0014579 Removed Germnay from condition, we have checked it in init.
        if (this.isSubscribed && this.accountManagerInfo && this.accountManagerInfo.Id && this.accountManagerInfo.Id != "") tmp = true;//TH:11.09.23:US-0014060 - Change to the Account Manager Display Logic
        return tmp;
    }
    get accMgmntName() {
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.LastName && this.accountManagerInfo.LastName != "")) tmp += this.accountManagerInfo.LastName + " ";
        if ((this.accountManagerInfo && this.accountManagerInfo.MiddleName && this.accountManagerInfo.MiddleName != "")) tmp += this.accountManagerInfo.MiddleName + " ";
        if ((this.accountManagerInfo && this.accountManagerInfo.FirstName && this.accountManagerInfo.FirstName != "")) tmp += this.accountManagerInfo.FirstName;
        return tmp;
    }
    //MN-30012023-US-0010832
    get accMgmntFirstName() {
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.FirstName && this.accountManagerInfo.FirstName != "")) tmp += this.accountManagerInfo.FirstName;
        return tmp;
    }
    //MN-30012023-US-0010832
    get accMgmntLastName() {
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.LastName && this.accountManagerInfo.LastName != "")) tmp += this.accountManagerInfo.LastName + " ";
        return tmp;
    }
    get accMgmntPhone() {
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.Phone)) tmp = this.accountManagerInfo.Phone + " ";
        return tmp;
    }
    get accMgmntEmail() {
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.Customer_facing_eMail__c)) tmp = this.accountManagerInfo.Customer_facing_eMail__c + " ";
        return tmp;
    }
    get accMgmntProfileImage() { // 06.02.2023 / Sophal Noch / US-0011132
        var tmp = '';
        if ((this.accountManagerInfo && this.accountManagerInfo.MediumPhotoUrl)) tmp = this.accountManagerInfo.MediumPhotoUrl;
        // if ((this.accountManagerInfo && !this.accountManagerInfo.IsProfilePhotoActive)) tmp = this.fallbackProfilePic;
        return tmp;
    }
    get showAccountManager() {
        return (this.isSubscribed || this.isPlatinum) && this.accountManagerInfo;//TH:11.09.23:US-0014060 - Change to the Account Manager Display Logic
    }
    get showName() {
        return ((this.accountManagerInfo && this.accountManagerInfo.Name && this.accountManagerInfo.Name != ""));
    }
    get showPhone() {
        return ((this.accountManagerInfo && this.accountManagerInfo.Phone && this.accountManagerInfo.Phone != ""));
    }
    get showEmail() {
        return ((this.accountManagerInfo && this.accountManagerInfo.Email && this.accountManagerInfo.Email != ""));
    }
    get showSubscribePage() {
        return this.showPageContent && this.firstMetadataValue // Make sure that the metadata is loaded
        && !this.isPlatinum && ((this.subscription == null) || (!this.subscribeOnGoing && !this.isSubscribed && !this.unsubscribeRequest));
    }
    get isSubscribed() {
        return (this.subscription != null && (this.subscription.Status__c == "Subscribed"));
    }
    get subscribeOnGoing() {
        return (this.subscription != null && this.subscription.Status__c == "New" && !this.isPlatinum); // 09.11.2023 / Acmatac SEING / US-0014258
    }
    get unsubscribeRequest() { // 06.02.2023 / Sophal Noch / US-0011132
        //return (this.subscription != null &&  this.subscription.Status__c=="Unsubscribe Request" && !this.isPlatinumOrSuperAnchorPlan);
        return (this.subscription != null && this.subscription.Status__c == "Unsubscribe Request");//TH:11.09.23:US-0014060 - Change to the Account Manager Display Logic
    }
    // END Get Set

    // START Imperative Method
    renderedCallback() {
        
    }
    connectedCallback(){
    }

    onConfirmClick(event) {
        this.showSpinner = true;
        //create subscription request    
        createSubscription({ sellerId: this.selectedSeller })// Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
            .then(result => {
                console.log("--createSubscription",result);
                if (result.status == "ok") {
                    this.isModalOpen = false;
                    refreshApex(this._wireSellerInfo);
                } else {
                    // console.log(error);
                    const evt = new ShowToastEvent({
                        title: "Error",
                        message: result.data.error,
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                }
                this.showSpinner = false;
            })
            .catch(error => {
                // console.log(error);
                const evt = new ShowToastEvent({
                    title: "Error",
                    message: error,
                    variant: "error",
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });

    }
    onClickUnsubscription(event) {//LA-24-12-2021-US-0010563 
        //MN-30012023-US-0010832
        this.showSpinner = true;
        requestUnsubscription({ sellerId: this.selectedSeller })// Sambath Seng 1.2.2023 US-0011155 - [AM]Add Account Picker to DE Book Account Manager
            .then(result => {
                //console.log("--requestUnsubscription",result);
                if (result.status == "ok") {
                    //MN-32012023-US-0010832
                    refreshApex(this._wireSellerInfo);

                } else {
                    console.log(error);
                    const evt = new ShowToastEvent({
                        title: "Error",
                        message: result.data.error,
                        variant: "error",
                    });
                    this.dispatchEvent(evt);
                    this.showSpinner = false;
                }
            })
            .catch(error => {
                // console.log(error);
                const evt = new ShowToastEvent({
                    title: "Error",
                    message: error,
                    variant: "error",
                });
                this.dispatchEvent(evt);
                this.showSpinner = false;
            });
        //LA-24-12-2021-US-0010563
    }
    //MN-30012023-US-0010832
    onClickUnsubConfirm(event) {
        this.isUnsubModalOpen = true;
    }
    onCancelHandle(event) {
        // redirect to home page
        this[NavigationMixin.Navigate]({
            type: "standard__namedPage",
            attributes: {
                pageName: 'home'
            }
        });

    }
    //MN-06022023-US-0012587
    onBackHandle(event) {
        this.isUnsubModalOpen = false;
    }
    onAnchorClickHandle(event) {
        this.isModalOpen = true;
    }
    closeModal(event) {
        this.isModalOpen = false;
    }

    // UTILS
    showSuccessToast(message,mode){
        this.showToast("Success",message,"success",mode)
    }

    showErrorToast(message,mode){
        this.showToast("Error",message,"error",mode)
    }

    showToast(title,message,variant,mode){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant,
                mode: mode
            }),
        );
    }
    // END Imperative Method

    // START Wire Method
    // @wire(accountManagementMetadata, { firstMetadataName: '$firstMetadataName', secondMetadataName: '$secondMetadataName', thirdMetadataName: '$thirdMetadataName' })
    @wire(getAccountManagementMetadata, { metadataName: '$metadataName' })
    accountManagementMetadata(result) {
        if (result.data) {
            // console.log('accountManagementMetadata : ', result.data);
            this.accountManagementMetadata = result.data;
            this.zeroMetadataValue = this.accountManagementMetadata[this.metadataName];
            this.firstMetadataValue = this.accountManagementMetadata[this.metadataName+'1'];
            this.secondMetadataValue = this.accountManagementMetadata[this.metadataName+'2'];
            this.thirdMetadataValue = this.accountManagementMetadata[this.metadataName+'3'];
            this.error = undefined;

        } else if (result.error) {
            console.log('error : ', result.error);
        }

    };

    //MN-24122021-US-0010562, SP-1002023-US-0011132
    @wire(getActiveCohortSeller, {
        sellerId: '$selectedSeller'
    })
    activeCohortSellerInfo(result) {
        if (result.data) {
            // this._wireActiveCohortSeller = result;
            this.accountManagerInfo = result.data.accountMgmtInfo;
        } else if (result.error) {
            console.log('getActiveCohortSeller :: error : ', result.error);
        }
    };

    _wireSellerInfo;
    @wire(getSellerInfo, {
        sellerId: '$selectedSeller'
    })
    GetSelectedSellerInfo(result) {
        if (result.data && result.data.status && result.data.status =='ok' && result.data.account) {
            this._wireSellerInfo = result;
            // console.log('Book AM GetSelectedSellerInfo >>', result.data.GetSelectedSellerInfo);
            let btndata = result.data.account.EBH_StoreSubscription__c;
            this.subscription = result.data.subscription.length > 0 ? result.data.subscription[0] : null;
            this.optOutEftDate = result.data.optOutEftDate; // 06.02.2023 / Sophal Noch / US-0011132
            this.registrationCountry = result.data.account.EBH_RegistrationCountry__c;//TH:US-0014060
            this.eligibleFor_BookAM = result.data.eligibleFor_BookAM;
            this.isPlatinum = btndata == 'Platinum' ? true : false; // 10.02.2023 / Sophal Noch / US-0011132
        } else {
            // console.log('Error >>', result.data.error);
        }
        this.showPageContent = true;
        this.showSpinner = false;
    };
    // END Wire Method

}