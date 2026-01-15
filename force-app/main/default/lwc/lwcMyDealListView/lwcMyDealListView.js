/*********************************************************************************************************************************
@ Change history:  	26.11.2021 / Sovantheany Dim (sovantheany.dim@gaea-sys.com) / Create the class. US-0010793: [SEP] Seller views their Deals in Deal Windows
*********************************************************************************************************************************/
import { LightningElement,api,track} from 'lwc';

export default class LwcMyDealListView extends LightningElement {
    @api recordId;
    @api mdtNameMyDeal;
    @api messageNoRecordMyDeal;
    //@track isShowDensity = false; // disable density //MN-02122021-US-0010808
    @track isShowBtnIntr = false;
    @track lbButtonIntr = false;
    @track isCheckBox = false; // disable checkbox
    @track isDisableSearch = true; // disable search and filter section
}