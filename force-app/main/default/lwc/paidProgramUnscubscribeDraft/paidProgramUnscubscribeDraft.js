import { LightningElement,wire } from 'lwc';

import getAllAccounts from '@salesforce/apex/AccountManagementController.getAllAccounts';

export default class PaidProgramUnscubscribeDraft extends LightningElement {

    selectedSeller = '';
    sellerOptions = [];

    _wireGetAllAccounts;
    @wire(getAllAccounts)
    wireGetAccounts(result) {
        if (result.data) {
            // console.log('wireGetAccounts >>', result.data);
            this._wireGetAllAccounts = result;
            var accounts = [];
            accounts = result.data.listEligibleAccount;
            this.mapSellerIdCohortSeller = result.data.mapCohortSeller;
            var sellerData = [];
            for (var index = 0; index < accounts.length; index++) {
                var oneAcc = accounts[index];
                sellerData.push({
                    label: oneAcc.Name,
                    value: oneAcc.Id
                });
            }
            this.sellerOptions = sellerData;
            if (accounts.length == 1) this.selectedSeller = sellerData[0].value;
        } else {
            // console.log('Error >>', result.data.error);
        }
    };

}