/*********************************************************************************************************************************
@ Name:         CustomDynamicRelatedList
@ Version:      1.0
@ Author:       Sothea Horn
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 21.08.2025 / Sothea Horn / US-0033306 - [TDD] Creating List view for Account Plans on Parent 
*********************************************************************************************************************************/

import { LightningElement, api, wire } from 'lwc';
import getRecords from '@salesforce/apex/CustomDynamicRelatedListController.getRecords';
const FILTER_BY_TODAY = '{date}=TODAY';
const FILTER_BY_NEXT7Day = '({date}=TODAY OR {date}=NEXT_N_DAYS:7)';
const LINK_SUFIX = 'LINK';
export default class CustomDynamicRelatedList extends LightningElement {
    errorMessage;
    allColumns = [];
    allRecords = []; //All records available for data table
    recordWithLimit = []; //Records with limit set from the attribute
    isLoading = true;
    //Used to render table after we get the data from apex controller    
    get showTable(){
        return !this.isLoading && !this.errorMessage;
    }

    selectedFilter = FILTER_BY_NEXT7Day;

    @api tableHeaderTitle='';
    @api headerIcon='standard:table';
    @api tableHeaderIcon='';
    @api tableHeight;
    
    @api recordId;
    @api objApiName='';
    @api fieldSetName='';
    @api parentField='';
    @api ownerField='';
    @api additionalClause='';
    @api sortBy='';
    @api dateFilterField='';
    @api filterByToday=false;
    @api filterByNext7Days=false;
    @api recordLimit;
    @api showPagination;
    @api noRecordMessage;

    
    get genTableHeaderTitle(){
        return this.tableHeaderTitle +' ('+this.allRecords.length+')';
    }

    get filterButtons(){
        let arr = [];
        if(this.filterByToday){
            arr.push({label: 'Today', value: FILTER_BY_TODAY});
        }
        if(this.filterByNext7Days){
            arr.push({label: 'Next 7 Days', value: FILTER_BY_NEXT7Day});
        }
        return arr;
    }

    get filterEnabled(){
        return this.dateFilterField && this.filterButtons.length>0;
    }

    get filterBy(){
        let strFilter = '';
        if(this.dateFilterField && this.selectedFilter){
            strFilter = this.selectedFilter.replaceAll('{date}', this.dateFilterField);   
        }
        return strFilter;
    }

    get noRecordSvgHeight(){
        return parseFloat(this.tableHeight)/2;
    }

    @wire(getRecords, {
        objectApiName: '$objApiName', 
        fieldSetName: '$fieldSetName',
        parentField: '$parentField',
        parentFieldValue: '$recordId',
        ownerField: '$ownerField',
        additionalClause: '$additionalClause',
        sortBy: '$sortBy',
        filterBy: '$filterBy',
        recordLimit: '$recordLimit'
    })
    getRecords({error,data}) {
        this.isLoading = true;
        if(data){
            let that = this;
            // 1) Build your columns directly from data.fields
            let columns = data.fields.map(field => {
                let col = {
                    label: field.label,
                    fieldName: field.fieldApi,
                    type: 'text',
                    sortable: true
                };

                if (field.type === 'REFERENCE') {
                    col.type = 'url';
                    col.typeAttributes = {
                        label: { fieldName: field.fieldName },
                        target: '_blank'
                    };
                 } else if (field.type === 'NAME') {
                    col.type = 'url';
                    col.typeAttributes = {
                        label: { fieldName: field.fieldName+LINK_SUFIX },
                        target: '_blank'
                    };
                } else if (field.type === 'DATETIME' || field.type === 'DATE') {
                    col.type = 'date';
                    col.typeAttributes = {
                        year: "numeric",
                        month: "short",
                        day: "2-digit",
                        timeZone: 'UTC'
                    }
                }
                return col;
            });

            // 2) Flatten each record in data.records
            let records = data.records.map(record => {
                // Make a shallow copy
                let newRec = { ...record };

                // For each field in data.fields, if it has a dot (like "EBH_Account__r.Name"),
                // pull the nested value out of `record` and store it as a top-level property
                data.fields.forEach(field => {
                    if (field.type === 'REFERENCE' && record[field.fieldApi]) {
                        if (field.fieldName.includes('.')) {
                            newRec[field.fieldName] = that.getNestedValue(record, field.fieldName);
                        }
                        newRec[field.fieldApi] = '/' + record[field.fieldApi];
                    } else if (field.type === 'NAME') {
                        newRec[field.fieldName+LINK_SUFIX] = that.getNestedValue(record, field.fieldName);
                        newRec[field.fieldApi] = '/' + record.Id;
                    }
                });

                return newRec;
            });
            this.allColumns = columns;
            this.allRecords = records;
            this.isLoading = false;
        }
        else if (error) {
            // Safely handle/display error
            this.errorMessage = this._normalizeError(error);
            console.log('error:',this.errorMessage);
        }
    }

    handleRadioGroupValueChange(event) {
        this.selectedFilter = event.detail.value; // Update the selected color
    }

    _normalizeError(error) {
        let message = 'Unknown error';
        if (Array.isArray(error.body)) {
            message = error.body.map(e => e.message).join(', ');
        } else if (error.body && typeof error.body.message === 'string') {
            message = error.body.message;
        }
        return message;
    }

    // A small helper to safely walk an object using a dotted path
    getNestedValue(obj, dottedField) {
        return dottedField.split('.').reduce((o, prop) => (o ? o[prop] : undefined), obj);
    }
    
}