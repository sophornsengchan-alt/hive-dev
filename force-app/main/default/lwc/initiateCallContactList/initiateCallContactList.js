/*********************************************************************************************************************************
@ Component:    InitiateCallContactList
@ Author:       Sophal Noch
@ Purpose:      09.04.2024 / Sophal Noch / US-0014987 - Convert Initiate Call button screen from Aura to LWC
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 09.04.2024 / Sophal Noch / Create Component
*********************************************************************************************************************************/
import { LightningElement, api } from 'lwc';
import customLabel from 'c/customLabels';

export default class InitiateCallContactList extends LightningElement {
    @api headerName = '';
    @api listContact = [];
    @api columnContacts = [];
    @api sitePrefix;
    @api selectedContacts = [];
    @api isFromRecordInboundCall = false;

    label = customLabel;
    selectedContactIds=[];
    defaultSortDirectionCont = 'asc';
    sortDirectionCont = 'asc';
    sortedByCont = '';

    /**
     * Name: connectedCallback
     * Purpose: init method to prepare contact list to display in lightinig table
    */
    connectedCallback() {
        let relURL = '';
        let accUrl = '';
        let contactUrl = '';
        if(!this.sitePrefix){
            relURL = '/';
        }else{
            relURL = '/gcx/s/';
            accUrl = 'account/';
            contactUrl = 'contact/';
        }

        this.listContact = this.listContact.map(record => {
            let contact =  JSON.parse(JSON.stringify(record));
            contact['link_Name'] = relURL+contactUrl+record.Id;				        	 	           
            contact['link_AccountId'] = relURL+accUrl+record.AccountId;
            contact['AccountId'] = record.Account?.Name;
            contact['RecordTypeId'] = record.RecordType?.Name;
            return contact;
        });

        this.selectedContactIds = [];
        this.selectedContactIds = this.selectedContacts.map((contact) => contact.Id); // add selection to the table if there are exist selection

        // if there are only 1 contact in the list, auto-select that contact
        if(!this.isFromRecordInboundCall && this.selectedContactIds.length <= 0 && this.listContact.length == 1){
            this.selectedContacts = [];
            this.selectedContacts.push(this.listContact[0]);
            this.selectedContactIds.push(this.listContact[0].Id);
            this.transferSelectedContact(this.listContact[0]);
        }

    }

    /**
     * Name: handleSortContact
     * Purpose: method to sort contact by field
     * @param event
    */
    handleSortContact(event) {
        const { fieldName: sortedBy, sortDirection } = event.detail;
        const cloneData = [...this.listContact];

        cloneData.sort(this.sortBy(sortedBy, sortDirection === 'asc' ? 1 : -1));
        
        this.defaultSortDirectionCont = sortDirection;
        this.sortedByCont = sortedBy;
        this.listContact = cloneData;
    }

    sortBy(field, reverse, primer) {
        const key = primer
            ? function (x) {
                  return primer(x[field]);
              }
            : function (x) {
                  return x[field];
              };

        return function (a, b) {
            a = key(a);
            b = key(b);
            return reverse * ((a > b) - (b > a));
        };
    }

    /**
     * Name: handleRowSelectionContact
     * Purpose: when click select contact on the list, send the selected contact to paraent componet
     * @param event
    */
    handleRowSelectionContact(event){
        if(event?.detail?.selectedRows && event.detail.selectedRows.length > 0){
            this.transferSelectedContact(event.detail.selectedRows[0]);
        }
     
    }

    /**
     * Name: transferSelectedContact
     * Purpose: send the selected contact to paraent componet
     * @param selectedCont
    */
    transferSelectedContact(selectedCont){
        let selectedContacts = [];
        selectedContacts.push(selectedCont);
        const payload = new CustomEvent('contactselected', {
            detail: {selectedContacts : selectedContacts}
        });
        this.dispatchEvent(payload);
    }

    get noListContact(){
        return this.listContact.length > 0 ? false : true;
    }

    
}