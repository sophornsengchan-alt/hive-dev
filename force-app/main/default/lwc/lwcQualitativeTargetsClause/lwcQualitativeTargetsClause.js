import { LightningElement, api, track} from 'lwc';

export default class lwcQualitativeTargetsClause extends LightningElement {
    @api recordId;
    @api isReady;
    @api qualitativeTargetsData = [];
    @api qualitativeTargetsToDelete = [];
    @api contractData = {};
    @api isPrevew;
    @track qTargetsData = [];
    connectedCallback() { 
        this.isReady = true;
        let data = JSON.parse(JSON.stringify(this.qualitativeTargetsData));
        if(data.length == 0) {
            this.qTargetsData.push({
                'Id': '',
                'Contract__c': this.contractData.Id,
                'Contract_Seller_Id__c':'',
                'Category_Tree__c': '',
                'Category_Name_and_Number__c': '',
                'Username__c': '',
                'Number_of_SKUs__c': '',
                'Products__c': '',
            });
        }else {
            this.qTargetsData = data;
        }
    }

    filter = {
        criteria: [
            {
                fieldPath: 'Site__c',
                operator: 'eq',
                value: '3',
            }
        ]
    };

    displayInfo = {
        primaryField: 'Seller_Name__c',
        additionalFields: ['SellerOracleId__c'],
    };

    matchingInfo = {
        primaryField: { fieldPath: 'Seller_Name__c', mode: 'startsWith' },
        additionalFields: [{ fieldPath: 'SellerOracleId__c' }],
    };

    displayInfoCat = {
        primaryField: 'Name',
        additionalFields: ['Category_ID__c'],
    };

    matchingInfoCat = {
        primaryField: { fieldPath: 'Name', mode: 'startsWith' },
        additionalFields: [{ fieldPath: 'Category_ID__c' }],
    };
   
    handleChange(event){
        let data = JSON.parse(JSON.stringify(this.qTargetsData));
        let idx = parseInt(event.target.dataset.id);
        let name = event.target.dataset.name;
        data[idx][name] = event.target.value;
        this.qTargetsData = data;
        this.qualitativeTargetsData = data;
    }

    handleChangePicker(event){
        let data = JSON.parse(JSON.stringify(this.qTargetsData));
        let idx = parseInt(event.target.dataset.id);
        let name = event.target.name;
        data[idx][name] = event.detail.value || event.detail.recordId;
        this.qTargetsData = data;
        this.qualitativeTargetsData = data;
    }

    addNewQualitativeTarget(event){
        let data = {
            'Id': '',
            'Contract__c': this.contractData.Id,
            'Contract_Seller_Id__c':'',
            'Category_Tree__c': '',
            'Category_Name_and_Number__c': '',
            'Username__c': '',
            'Number_of_SKUs__c': '',
            'Products__c': '',
        };
        this.qTargetsData.push(data);
        this.qualitativeTargetsData = this.qTargetsData;
    }
    deleteQualitativeTarget(event){
        let data = JSON.parse(JSON.stringify(this.qTargetsData));

        if(this.qTargetsData.length > 1) {
            if(data[data.length - 1].Id != '') {
                this.qualitativeTargetsToDelete.push(data[data.length - 1]);
            }
            
            this.qTargetsData.splice(-1);
            this.qualitativeTargetsData = this.qTargetsData;
        }
    }
}