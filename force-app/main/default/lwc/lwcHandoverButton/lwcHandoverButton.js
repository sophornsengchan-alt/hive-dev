import { LightningElement,api,wire,track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import handoverDoInit from '@salesforce/apex/HandOverButtonController.handoverDoInit';
import handoverSubmit from '@salesforce/apex/HandOverButtonController.handoverDoSubmit';
export default class LwcHandoverButton extends LightningElement {
    @api recordId;
    @api showSpinner = false;
    isReady = false;
    @track isFieldRequired = false;
    activeSections = ['Opportunity_Information', 'Legal_Entity_Information','Additional_Information'];

    data = {};
    
    value = 'option1';
    records = {};
    get options() {
        return [
            { label: 'Durchstarter', value: 'option1' }
        ];
    }

    handleNext() {
        this.doInit();
    }

    handleSubmit() {
        if(this.isBlank(this.data.Consultation_Language)){
            this.isFieldRequired = true;
            return;
        }
        this.isFieldRequired = false;
        this.dohandOverSubmit();
    }
    handleOppChange(event){
        let field = event.target.name;
        this.records[field] = event.target.value;
    }
    handleDataChange(event) {
        this.data.Consultation_Language = event.target.value;
        if(this.isBlank(this.data.Consultation_Language)){
            this.isFieldRequired = true;
        }else{
            this.isFieldRequired = false;
        }
    }

    dohandOverSubmit(){
        this.showSpinner = true;
        let projectToSave = {};
        let legalEntityName = this.records.LegalEntity__r ? this.records.LegalEntity__r.Name : '';
        projectToSave.Name = 'Onboarding DE ' + legalEntityName;
        projectToSave.LegalEntity__c = this.records.LegalEntity__c;
        projectToSave.LeadSource__c = this.records.LeadSource;
        projectToSave.OracleID__c = this.records.Oracle_ID__c;
        projectToSave.Opportunity__c = this.recordId;
        if(this.records.Seller__c != null){
            projectToSave.EBH_Seller__c = this.records.Seller__c;
        }
        projectToSave.Seller_Name__c = this.records.Seller_Name__c;
        projectToSave.EBH_Contact__c = this.records.Primary_Contact__c;
        projectToSave.Site__c = this.records.Site__c;
        projectToSave.Vertical__c = this.records.Focus_Vertical__c;
        projectToSave.Website__c = this.records.Additional_Website__c;
        projectToSave.Comments__c = [
            `Consultation in which Language: ${this.data.Consultation_Language || ''}`,
            `What has already been discussed with Seller: ${this.data.Discussed_Seller || ''}`,
            `ASP: ${this.records.ASP__c || ''}`,
            `SKU: ${this.records.SKUs__c || ''}`,
            `Customer Type: ${this.records.Customer_Type__c || ''}`
        ].join('\n');

        // Pass projects as a list for bulk processing
        handoverSubmit({projects: [projectToSave]})
            .then((result) => {
                if(result.status== 'ok'){
                        this.showSuccessToast('Handover completed successfully.');
                        this.dispatchEvent(new CloseActionScreenEvent());
                        // Refresh the record page to show the newly created project in related lists
                        setTimeout(() => {
                            eval("$A.get('e.force:refreshView').fire();");
                        }, 1000);
                }else if(result.status== 'ko'){
                    this.errorMessage = result.error;
                    this.showErrorToast(result.error);
                }
            })
            .catch((error) => {
                console.log('error ',error);
                let errorMessage = error?.body?.message || 'Error occurred';
                this.showErrorToast(errorMessage);
            }).finally(() => {
                this.isReady = true;
                this.showSpinner = false;
            });
    }

            // helper to determine if legal entity block has any value (used by template)
            get hasLegalEntity() {
                return !!(this.data && (this.data.legalEntity_Name || this.data.legalEntity_Address));
            }

    isBlank(value) 
    {
        return (value === undefined || value === null )|| (value !=null && value.trim() === '');
    }
    

    doInit(){
        this.showSpinner = true;
        handoverDoInit({ recordId: this.recordId})
            .then((result) => {
                if(result.status== 'ok'){
                    this.records = result.data;
                    this.data['Discussed_Seller'] = this.records.Description?this.records.Description:'';
                    this.data['Discussed_Seller'] = this.records.NextStep ? this.data['Discussed_Seller'] + ' ' + this.records.NextStep : this.data['Discussed_Seller'];
                    this.data['Consultation_Language'] = this.records.Languages__c;
                    this.data['isContactHas'] = this.records.Primary_Contact__c != null;
                    if(this.data['isContactHas']){
                        this.data['Phone_Mobilephone'] = this.records.Primary_Contact__r.Phone ? this.records.Primary_Contact__r.Phone : '';
                        this.data['Phone_Mobilephone'] = this.records.Primary_Contact__r.MobilePhone? this.data['Phone_Mobilephone'] + ' , '+ this.records.Primary_Contact__r.MobilePhone : this.data['Phone_Mobilephone'];
                        this.data['isPhoneHas'] = this.data['Phone_Mobilephone'] != '';
                        this.data['isEmailHas'] = this.records.Primary_Contact__r.Email != null;
                    }
                    
                    this.data['isSellerHas'] = this.records.Seller__c != null;
                    let legalEntity = this.records.LegalEntity__r? this.records.LegalEntity__r : null;
                    if(legalEntity != null){
                        this.data['legalEntity_Name'] = legalEntity.Name?legalEntity.Name:'';
                        this.data['legalEntity_Address'] = legalEntity.EBH_BillingStreet__c ?  legalEntity.EBH_BillingStreet__c : '';
                        this.data['legalEntity_Address'] = legalEntity.EBH_BillingCity__c ?  this.data['legalEntity_Address'] + ', ' + legalEntity.EBH_BillingCity__c : this.data['legalEntity_Address'];
                        this.data['legalEntity_Address'] = legalEntity.EBH_BillingCountry__c ?  this.data['legalEntity_Address'] + ', ' + legalEntity.EBH_BillingCountry__c : this.data['legalEntity_Address'];
                        this.data['legalEntity_Address'] = legalEntity.EBH_BillingPostalCode__c ?  this.data['legalEntity_Address'] + ', ' + legalEntity.EBH_BillingPostalCode__c : this.data['legalEntity_Address'];
                    }
                }else if(result.status== 'ko'){
                    this.errorMessage = result.error;
                }
            })
            .catch((error) => {
                console.log('error ',error);
                this.errorMessage = 'An error occurred while initializing the component.';
                this.errorMessage = error?.body?.message || 'Error occurred';
                this.showErrorToast(this.errorMessage);
            }).finally(() => {
                this.isReady = true;
                this.showSpinner = false;
            });
    }

    showSuccessToast(message){
        this.showToast("Success",message,"success")
    }

    showErrorToast(message){
        this.showToast("Error",message,"error")
    }

    showToast(title,message,variant){
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            }),
        );
    }
}