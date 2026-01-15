import { LightningElement, api,track,wire} from 'lwc';

export default class LwcCreateEbayLivePricingUI extends LightningElement {

    @api pricing = {};
    @api contract = {};
    @api isError = false;

    @track isLoading = false;
    @track title = '';
    @track hasError = false;

    mapSiteCurrency = {
        'DE': 'EUR',
        'UK': 'GBP',
        'FR': 'EUR',
        'IT': 'EUR',
        'ES': 'EUR',
        'AU': 'AUD',
        'US': 'USD',
        'CA': 'CAD',
        'AT': 'EUR',
        'BE': 'EUR',
        'NL': 'EUR',
        'CH': 'CHF',
        'CZ': 'CZK',
        'DK': 'DKK',
        'FI': 'EUR',
        'HU': 'HUF',
        'IE': 'EUR',
        'NZ': 'NZD',
        'NO': 'NOK',
        'PL': 'PLN',
        'SE': 'SEK',
        'US Motors': 'USD',
        'CAFR': 'CAD'
    }

    mapCurrencySymbol = {
        
        'EUR': '€',    // EUR
        'GBP': '£',     // GBP
        'AUD': 'A$',   // AUD
        'USD': '$',     // USD
        'CAD': 'CA$',   // CAD
        'CHF': 'CHF', // CHF (Swiss Franc has no special symbol)
        '197': 'Kč',  // CZK
        'DKK': 'kr',  // DKK
        'HUF': 'Ft',  // HUF
        'NZD': 'NZ$', // NZD
        'NOK': 'kr',  // NOK
        'PLN': 'zł',  // PLN
        'SEK': 'kr'  // SEK          
    }


    connectedCallback() {
        this.handleInitData();     
    }

    handleInitData() {

        this.title = 'Sales Threshold (' + this.mapCurrencySymbol[this.mapSiteCurrency[this.contract.EBH_Site__c]] + ')' || 'Sales Threshold';
        this.checkIfInputIsBlank();
    }

    checkIfInputIsBlank() {

        let data = JSON.parse(JSON.stringify(this.pricing));
        let isBlank = Object.values(data).some(
            v => v === null || v === undefined || v === ''
        );

        this.hasError = isBlank;
    }

    handleChangeTierFields(event) {

        let data = JSON.parse(JSON.stringify(this.pricing));

        const fieldName = event.target.dataset.name;
        const fieldValue = event.target.value;

        data[fieldName] = fieldValue;

        this.pricing = data;

        this.checkIfInputIsBlank();
    }

}