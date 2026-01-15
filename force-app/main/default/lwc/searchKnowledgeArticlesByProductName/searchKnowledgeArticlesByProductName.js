import { LightningElement, wire, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import KnowledgeArticles from '@salesforce/apex/KnowledgeSearchController.getKnowledgeArticles';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';


const columns = [
    {
        label: 'Title',
        fieldName: 'url',
        type: 'url',
        sortable: true,
        typeAttributes: {
            label: { fieldName: 'Title' },
            target: '_blank'
        }
    },
    { label: 'Question', fieldName: 'Question__c', type: 'text' },
    { label: 'Created Date', fieldName: 'CreatedDate', type: 'date' },
    //{ label: 'Total View', fieldName: 'ArticleTotalViewCount', type: 'text' },
];

export default class SearchKnowledgeArticlesByProductName extends NavigationMixin(LightningElement) {
    @api selectedProduct;

    data = [];
    columns = columns;
    @api recordId;
    @api content;
    @api isIssueResolved = false;
    @api isValid = false;
    recordSelected = false;
    error;
    hiveUniversityUrl = 'https://hive.my.trailhead.com';
    

    @wire(KnowledgeArticles, { searchText: '$selectedProduct' })
    wiredArticles({ error, data }) {
        this.data = [];
        if (data) {
            this.data = data.map(row => {
                // Clone the row
                let rowData = { ...row };
                // Generate the URL for the record
                rowData.url = '/' + rowData.Id;
                return rowData;
            });
        } else if (error) {
            console.log
            this.error = error;
        }
    }
    connectedCallback() {
        let hiveUniurl = `https://hive.my.trailhead.com/search?keywords=${encodeURIComponent(this.selectedProduct)}`;
        this.hiveUniversityUrl = hiveUniurl;
    }

/*
handleResolveIssue() {
    this.isValid = true;
    this.isIssueResolved = true;
    this.isModalOpen = false; // Close the modal dialog
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
}
*/
/*handleCreateCase() {
    this.isValid = true;
    this.isModalOpen = false; // Close the modal dialog
    // Add your logic for creating a case and moving to the next screen here
    this.isIssueResolved = false;
    const navigateNextEvent = new FlowNavigationNextEvent();
    this.dispatchEvent(navigateNextEvent);
}*/

}