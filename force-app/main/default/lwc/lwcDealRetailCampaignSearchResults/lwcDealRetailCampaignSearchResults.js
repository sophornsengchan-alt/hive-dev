import { LightningElement,api,track,wire } from 'lwc';

export default class LwcDealRetailCampaignSearchResults extends LightningElement {
    searchText = '';
    /** NEW VIEW */    
    
    @api mdtName;
    // @track isShowDensity = false; // disable density //MN-02122021-US-0010808
    @api messageNoRecord;
    @track isShowBtnIntr = false;
    @track lbButtonIntr = false;
    @track isCheckBox = false; // disable checkbox
    @track isDisableSearch = true; // disable search and filter section
    
    
    /** END NEW VIEW */
    connectedCallback(){

        var url = new URL(location.href);
        let decodeSearchText = decodeURI(url.searchParams.get('searchText'));
        console.log('dRC... searchText: ',decodeSearchText);
        this.searchText= decodeSearchText;        
        console.log('drc searchText: ',this.searchText);
      
    }

}