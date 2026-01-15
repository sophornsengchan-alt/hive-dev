/*********************************************************************************************************************************
@ Name:         DynamicDatatable
@ Version:      1.0
@ Author:       Acmatac Seing
@ Purpose:      Generic dynamic datatable that can be used for simple use case such as related list
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.02.2024 / Acmatac Seing / US-0016646 - Homepage for AM Cockpit - EA Components
*********************************************************************************************************************************/

import { LightningElement, api } from 'lwc';
const DELAY = 300;
const recordsPerPage = [10,25,50,75,100];
const pageNumber = 1;
const SHOWDIV = 'visibility:visible';
const HIDEDIV = 'visibility:hidden';  
const DEFAULTHEIGHT = '170';
import {isNullorUndefinedorZero } from "c/hiveUtils";

export default class DynamicDatatable extends LightningElement {
    _records = [];
    // Input Attributes from Parent Componant
    @api keyField;
    @api showSearchBox = false; //Show/hide search box; valid values are true/false
    @api showPagination = false; //Show/hide pagination; valid values are true/false
    @api pageSizeOptions = recordsPerPage; //Page size options; valid values are array of integers
    @api totalRecords; //Total no.of records; valid type is Integer
    // @api records; //All records available in the data table; valid type is Array
    @api maxRowSelection; //All records available in the data table; valid type is Array 
    @api columns = []; //Records to be displayed on the page
    @api headerTitle = 'Datatable Header';
    @api headerIcon = 'standard:table';
    @api clonedRecords = [];

    tableHeightStyle = 'height: '+ DEFAULTHEIGHT +'rem;';    // Set Default Height 
    @api
    get tableHeight() {
        return this.tableHeightStyle;
    }

    set tableHeight(value) {
       this.tableHeightStyle = 'height: '+ value +'rem;'; 
    }    

    get hasRecord(){
        return this.totalRecords > 0;
    }

    @api
    get records(){
        return this._records;
    }

    set records(value){
        this._records = value;
        this.connectedCallback();
    }

    pageSize; //No.of records to be displayed per page
    totalPages; //Total no.of pages
    pageNumber = pageNumber; //Page number
    searchKey; //Search Input
    paginationVisibility = SHOWDIV; 
    rowNumberOffset; //Row number
    preSelected; //preSelectedOnDisplay
    recordsToDisplay = []; //Records to be displayed on the page
    
    filteredRecords = []; //Filtered records available in the data table; valid type is Array
    selectedRecords = []; //OverallSelected records  in the data table; valid type is Array 
    pageSelectedRecords = []; //Page Selected rows  in the data table; valid type is Array
    filtredNum; // Total no.of Filtered records; valid type is Integer
    totalSelected = 0;
    refreshCurrentData;
    //SORT
    defaultSortDirection = 'asc';
    sortDirection = 'asc';
    sortedBy;

    //Called after the component finishes inserting to DOM
    connectedCallback() {
        // if showPagination is false then set pageSize to totalRecords
        if(this.showPagination == false){
            this.pageSize = this._records.length;
        }else{
            if(this.pageSizeOptions && this.pageSizeOptions.length > 0){
                this.pageSize = this.pageSizeOptions[0];
            }
            else{
                this.pageSize = this.totalRecords;
                this.showPagination = false;
            }
        }

        this.paginationVisibility = this.showPagination === false ? HIDEDIV : SHOWDIV;
        this.filteredRecords = this._records;
        this.filtredNum = this.totalRecords;
        this.setRecordsOnPage();
    }

    handleRecordsPerPage(event){
        this.pageSize = event.target.value;
        this.setRecordsOnPage();
    }

    handlePageNumberChange(event){
        if(event.keyCode === 13){
            this.pageNumber = event.target.value;
            this.setRecordsOnPage();
        }
    }
   
    previousPage(){
        this.pageNumber = this.pageNumber-1;
        this.setRecordsOnPage();
    }
    nextPage(){
        this.pageNumber = this.pageNumber+1;
        this.setRecordsOnPage();
    }

    @api
    setRecordsOnPage(){
        this.recordsToDisplay = [];
        if(!this.pageSize){
            this.pageSize = this.filtredNum;
        }
        this.totalPages = Math.ceil(this.filtredNum/this.pageSize);
        this.setPaginationControls();
        for(let i = (this.pageNumber - 1) * this.pageSize; i < this.pageNumber * this.pageSize; i++) {
            if(i === this.filtredNum) continue;
            if( !isNullorUndefinedorZero(this.filteredRecords[i])) {
                this.recordsToDisplay.push(this.filteredRecords[i]);
            }
        }
        this.preSelected = [];
        this.selectedRecords.forEach((item) => {
           if(item.selected)
                 this.preSelected.push(item.Id);
         })       
        let paginatedRecords = new Object();
        paginatedRecords.recordsToDisplay = this.recordsToDisplay;
        paginatedRecords.preSelected = this.preSelected;
        if(this.maxRowSelection === '1' ){
            this.totalSelected = 0;
        }    
        if(this.selectedRecords && this.selectedRecords.length > 0){
            this.refreshCurrentData = true;
        }                                   
    }

    setPaginationControls(){
        // Previous/Next buttons visibility by Total pages
        if(this.totalPages === 1){
            this.showPrevious = HIDEDIV;
            this.showNext = HIDEDIV;
        }else if(this.totalPages > 1){
           this.showPrevious = SHOWDIV;
           this.showNext = SHOWDIV;
        }
        // Previous/Next buttons visibility by Page number
        if(this.pageNumber <= 1){
            this.pageNumber = 1;
            this.showPrevious = HIDEDIV;
        }else if(this.pageNumber >= this.totalPages){
            this.pageNumber = this.totalPages;
            this.showNext = HIDEDIV;
        }
        // Previous/Next buttons visibility by Pagination visibility
        if(this.paginationVisibility === HIDEDIV){
            this.showPrevious = HIDEDIV;
            this.showNext = HIDEDIV;
        }
    }

    handleKeyChange(event) {
        window.clearTimeout(this.delayTimeout);
        const searchKey = event.target.value;
        if(searchKey){
            this.delayTimeout = setTimeout(() => {
                //this.paginationVisibility = HIDEDIV;
                this.setPaginationControls();

                this.searchKey = searchKey;
                //Use other field name here in place of 'Name' field if you want to search by other field
                //this.recordsToDisplay = this.records.filter(rec => rec.includes(searchKey));
                //Search with any column value (Updated as per the feedback)
                this.filteredRecords = this.records.filter(rec => JSON.stringify(rec).toLowerCase().includes(searchKey.toLowerCase()));
                this.filtredNum = this.filteredRecords.length; 
                this.setRecordsOnPage();
            }, DELAY);
        }else{
            this.filteredRecords = this.records; 
            this.filtredNum = this.totalRecords;            
            this.paginationVisibility = SHOWDIV;
            this.setRecordsOnPage();
        }        
    }

    mergeObjectArray(firstArray, secondArray, prop){
        var reduced =  firstArray.filter( aitem => ! secondArray.find ( bitem => aitem[prop] === bitem[prop]) )
        //let arr3 = arr1.map((item, i) => Object.assign({}, item, arr2[i]));
        return reduced.concat(secondArray);
    }    

    handelSort(event){        
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.filteredRecords];
        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        this.filteredRecords = cloneData;  
        this.sortDirection = sortDirection;
        this.sortedBy = sortedBy;        
        this.setRecordsOnPage();
    } 

    sortBy(field, reverse, primer) {
        const key = primer
            ? function(x) {
                  return primer(x[field]);
              }
            : function(x) {
                  return x[field];
              };

        return function(a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }    
}