import { LightningElement, api, wire, track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

import getContractData from "@salesforce/apex/ContractAmendmentListController.getContractData";

export default class lwcContractAmendmentList extends NavigationMixin(LightningElement) {
    @api recordId;
    @api proposalPricing = []; //MN-30092025-US-0033245
    @api proposalFeeType = []; //MN-30092025-US-0033245

    count = 0;
    @track isFeeTypeNoData;
    @track isPricingNoData;
    @track pricingList;
    @track feeTypeList;
    @track feeTypePricingRelatedList;

    connectedCallback(){

        this.isFeeTypeNoData = false;
        this.isPricingNoData = false;
        this.count = 0;
        this.getContractData();
    }

    getContractData(){
        getContractData({ recordId: this.recordId }).then(result => {
            this.pricingList = result.pricingList;
            this.feeTypeList = result.feeTypeList;
            this.count = (result.pricingList.length + result.feeTypeList.length);
            if(result.pricingList.length == 0){
                this.isPricingNoData = true;
            }
            if(result.feeTypeList.length == 0){
                this.isFeeTypeNoData = true;
            }

            //MN-30092025-US-0033245--START
            let proposalPricing = JSON.parse(JSON.stringify(this.proposalPricing)); 
            let proposalFeeType = JSON.parse(JSON.stringify(this.proposalFeeType)); 
            let proposalPricingMap = new Map(proposalPricing.map(p => [p.Name, p]));
            let proposalFeeTypeMap = new Map(proposalFeeType.map(f => [f.Name, f]));

            //Loop through pricing list and its feetype to set plutus link and status
            this.pricingList = this.pricingList.map(item => {

                let pricing = {...item};

                if (proposalPricingMap.has(item.pricing.Name)) {
                    pricing.plutusLink = proposalPricingMap.get(item.pricing.Name).ProposalUrl__c;
                    pricing.plutusStatus = proposalPricingMap.get(item.pricing.Name).ProposalStatus__c;
                }

                pricing.recordLink = '/' + item.pricing.Id;
                
                pricing.feeTypes = item.feeTypes?.map(feetype => {
                    feetype.recordLink = '/' + feetype.Id;
                    if (proposalFeeTypeMap.has(feetype.Name)) {
                        return {
                            ...feetype,
                            plutusLink: proposalFeeTypeMap.get(feetype.Name).ProposalUrl__c,
                            plutusStatus: proposalFeeTypeMap.get(feetype.Name).ProposalStatus__c
                        };
                    }
                    return feetype;
                }) || [];
                
                return pricing;
            });

            this.feeTypeList = this.feeTypeList.map(item => {
                
                let feetype = {...item};
                feetype.recordLink = '/' + item.Id;
                feetype.contractLink = '/' + item.RelatedContract__r.Id;
                return feetype;
            });

            //MN-30092025-US-0033245--END

        }).catch(error => {
            console.log('ERROR :: ', error);
        });
    }

    /* MN-30092025-US-0033245 -- No longer needed
    handleOpenRecord(event) {
        let linkId = event.target.dataset.id;
        this.handleRedirect(linkId);
    }

    handleRedirect(linkId) {
        this[NavigationMixin.GenerateUrl]({ 
            type: 'standard__recordPage',
            attributes: {
                recordId: linkId,
                actionName: 'view'
            }
        }).then((url) => {
            window.open(url, '_self');
        });
        
    }
    */
}