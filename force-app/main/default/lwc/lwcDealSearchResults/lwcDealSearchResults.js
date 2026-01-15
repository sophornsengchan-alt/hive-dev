import { LightningElement, track, wire, api } from 'lwc';

export default class LwcDealSearchResult extends LightningElement {
    searchText;

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
        console.log('deal ... searchText: ',decodeSearchText);
        this.searchText= decodeSearchText;        
        console.log('searchText: ',this.searchText);
      
    }

}