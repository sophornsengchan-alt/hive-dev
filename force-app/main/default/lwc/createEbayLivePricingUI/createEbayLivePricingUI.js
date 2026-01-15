import { LightningElement, track, api } from 'lwc';
import customLabel from 'c/customLabels';

export default class createEbayLivePricingUI extends LightningElement {
    label = customLabel;
    @api contractPricingMatrixData = [];
    @api choiceSelected;
    @api isReview = false;

    @api 
    set pricingData(value) {
        this._pricingData = (value || []).map(item => ({
            ...item,
            FVFBaseRate504__c: item.FVFBaseRate504__c ?? 0,
            FVFRate508__c: item.FVFRate508__c ?? 0
        }));
    }

    get pricingData() {
        return this._pricingData || [];
    }

    @api 
    set feeTypeData(value) {
        this._feeTypeData = (value || []).map(item => ({
            ...item,
            FeeValue__c: item.FeeValue__c ?? 0
        }));
    }

    get feeTypeData() {
        return this._feeTypeData || [];
    }

    @api 
    set feeTypeDataRegulatory(value) {
        this._feeTypeDataRegulatory = (value || []).map(item => ({
            ...item,
            FeeValue__c: item.FeeValue__c ?? 0
        }));
    }

    get feeTypeDataRegulatory() {
        return this._feeTypeDataRegulatory || [];
    }

    @api 
    set feeTypeDataFixedFee(value) {
        this._feeTypeDataFixedFee = (value || []).map(item => ({
            ...item,
            FeeValue__c: item.FeeValue__c ?? 0
        }));
    }

    get feeTypeDataFixedFee() {
        return this._feeTypeDataFixedFee || [];
    }

    // Final Value Fee Discount
    get isChoiceOne() {
        console.log('isChoiceOne:'+this.choiceSelected.includes(this.label.ChoiceFVFDiscount));
        return this.choiceSelected.includes(this.label.ChoiceFVFDiscount);
    }
    
    // Fixed Fee Credit
    get isChoiceTwo() {
        console.log('isChoiceTwo:'+this.choiceSelected.includes(this.label.ChoiceFixedFeeCredit));
        return this.choiceSelected.includes(this.label.ChoiceFixedFeeCredit);
    }
    
    // Insertion Fee Credit
    get isChoiceThree() {
        console.log('isChoiceThree:'+this.choiceSelected.includes(this.label.ChoiceInsertionFeeCredit));
        return this.choiceSelected.includes(this.label.ChoiceInsertionFeeCredit);
    }

    // Regulatory Fee Credit
    get isChoiceFour() {
        console.log('isChoiceFour:'+this.choiceSelected.includes(this.label.ChoiceRegulatoryFeeCredit));
        return this.choiceSelected.includes(this.label.ChoiceRegulatoryFeeCredit);
    }

    get categoryColumnSize() {
        const CHOICE_NUMBER_TO_SIZE_MAP = {
            4: "4", // Category gets 4 columns
            3: "3", // Category gets 3 columns
            2: "4", // Category gets 4 columns
            1: "6"  // Category gets 6 columns
        };
        const choiceCount = [this.isChoiceOne, this.isChoiceTwo, this.isChoiceThree, this.isChoiceFour].filter(choice => choice).length;

        return CHOICE_NUMBER_TO_SIZE_MAP[choiceCount] || "12"; // Fallback
    }

    get choiceColumnSize() {
        const CHOICE_NUMBER_TO_SIZE_MAP = {
            4: "2", // Each choice gets 2 columns
            3: "3", // Each choice gets 3 columns
            2: "4", // Each choice gets 4 columns
            1: "6"  // Single choice gets 6 columns
        };
        const choiceCount = [this.isChoiceOne, this.isChoiceTwo, this.isChoiceThree, this.isChoiceFour].filter(choice => choice).length;

        return CHOICE_NUMBER_TO_SIZE_MAP[choiceCount] || "12"; // Fallback
    }

    get enrichedContractPricingMatrixData() {
        return this.contractPricingMatrixData.map(category => {
            const pricingItem = this.pricingData.find(pricing => 
                pricing.EBH_ContractPricingMatrix__c === category.Id
            );
            const insertionFeeTypeItem = this.feeTypeData.find(feeType => 
                feeType.InclusionCategories__c === category.Category_Id__c && 
                feeType.InclusionCategoryName__c === category.Category_Name__c
            );
            const feeTypeItemRegulatory = this.feeTypeDataRegulatory.find(feeType => 
                feeType.InclusionCategories__c === category.Category_Id__c && 
                feeType.InclusionCategoryName__c === category.Category_Name__c
            );
            const fixedFeeTypeItem = this.feeTypeDataFixedFee.find(feeType => 
                feeType.InclusionCategories__c === category.Category_Id__c && 
                feeType.InclusionCategoryName__c === category.Category_Name__c
            );
            console.log('category.Id:'+category.Id);
            console.log('pricingItem:'+JSON.stringify(pricingItem));
            console.log('insertionFeeTypeItem:'+JSON.stringify(insertionFeeTypeItem));
            console.log('feeTypeItemRegulatory:'+JSON.stringify(feeTypeItemRegulatory));
            console.log('fixedFeeTypeItem:'+JSON.stringify(fixedFeeTypeItem));
            return {
                ...category,
                currentFVFBaseRate: pricingItem ? pricingItem.FVFBaseRate504__c : '',
                currentInsertionfeetype: insertionFeeTypeItem ? insertionFeeTypeItem.FeeValue__c : '',
                currentRegulatoryfeetype: feeTypeItemRegulatory ? feeTypeItemRegulatory.FeeValue__c : '',
                currentFixedfeetype: fixedFeeTypeItem ? fixedFeeTypeItem.FeeValue__c : ''
            };

        });
    }
    
    handleFVFBaseRateChange(event) {
        const categoryId = event.target.dataset.categoryId;
        const discountValue = parseFloat(event.target.value);
        this.pricingData = this.pricingData.map(pricing => {
            if (pricing.EBH_ContractPricingMatrix__c === categoryId) {
                return { ...pricing, FVFBaseRate504__c: discountValue };
            }
            return pricing;
        });
    }

    handleInsertionFeeChange(event) {
        const categoryId = event.target.dataset.categoryId;
        const insertionFee = parseFloat(event.target.value);
        
        // Find the corresponding category to get Category_Id__c and Category_Name__c
        const category = this.contractPricingMatrixData.find(cat => cat.Id === categoryId);
        if (category) {
            this.feeTypeData = this.feeTypeData.map(feeType => {
                if (feeType.InclusionCategories__c === category.Category_Id__c && 
                    feeType.InclusionCategoryName__c === category.Category_Name__c) {
                    return { ...feeType, FeeValue__c: insertionFee };
                }
                return feeType;
            });
        }
    }

    handleRegulatoryFeeChange(event) {
        const categoryId = event.target.dataset.categoryId;
        const regulatoryFee = parseFloat(event.target.value);

        // Find the corresponding category to get Category_Id__c and Category_Name__c
        const category = this.contractPricingMatrixData.find(cat => cat.Id === categoryId);
        if (category) {
            this.feeTypeDataRegulatory = this.feeTypeDataRegulatory.map(feeType => {
                if (feeType.InclusionCategories__c === category.Category_Id__c && 
                    feeType.InclusionCategoryName__c === category.Category_Name__c) {
                    return { ...feeType, FeeValue__c: regulatoryFee };
                }
                return feeType;
            });
        }
    }
    handleFixedFeeChange(event) {
        const categoryId = event.target.dataset.categoryId;
        const fixedFee = parseFloat(event.target.value);

        // Find the corresponding category to get Category_Id__c and Category_Name__c
        const category = this.contractPricingMatrixData.find(cat => cat.Id === categoryId);
        if (category) {
            this.feeTypeDataFixedFee = this.feeTypeDataFixedFee.map(feeType => {
                if (feeType.InclusionCategories__c === category.Category_Id__c &&
                    feeType.InclusionCategoryName__c === category.Category_Name__c) {
                    return { ...feeType, FeeValue__c: fixedFee };
                }
                return feeType;
            });
        }
    }

// Add this property to track validation state
@track validationError = '';
@api
validate() {
    // Skip validation in review mode
    if (this.isReview) {
        return { isValid: true };
    }

    let allInputs = this.template.querySelectorAll('lightning-input');
    
    let isValid = true;
    
    allInputs.forEach((input, index) => {
        // Check if input is required and empty
        if (input.hasAttribute('required') || input.required) {
            if (!input.value || input.value.trim() === '') {
                isValid = false;
            }
        }
    });
    
    if (!isValid) {
        this.validationError = this.label.RequiredMessage;
    } else {
        this.validationError = '';
    }
    return { isValid, errorMessage: this.validationError };
}

}