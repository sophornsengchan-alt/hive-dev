/**
 * change history:
 *      24.11.2022/ Loumang SENG /US-0012025 - [FR] Localization for Coupon Contract
 *                              /this component is specific for FR Coupon Contract - only for FR!
 *      04.04.2023 / Sambath Seng / US-0013014 - [IT] Display Coupon T&Cs on coupon contract in collapsible menu + PDF Download 
 */
import { LightningElement,track,api } from 'lwc';
import colHeaderCatBase from '@salesforce/label/c.HeadersOverride_CatBase';
import colHeaderItemBase from '@salesforce/label/c.HeadersOverride_ItemBase';
import accordionTitle_IT from '@salesforce/label/c.accordionTitle_IT';//SB 04.04.2023 US-0013014 - [IT] Display Coupon T&Cs on coupon contract in collapsible menu + PDF Download 

export default class LwcContractIT_SEP extends LightningElement {
    @api isItemBaseContract;
    @api isCatBaseContract;
    @api contractTemplate;
    @api additionalFilter;
    isShowMenuCollape = false; //SB 04.04.2023 US-0013014 - [IT] Display Coupon T&Cs on coupon contract in collapsible menu + PDF Download 

    fieldsNoLink = ["Item_ID__c","Category_ID__c"]; 

    Labels = {accordionTitle_IT};

    colHeaderCatBaseOverride = JSON.parse(colHeaderCatBase);
    colHeaderItemBaseOverride = JSON.parse(colHeaderItemBase);

    paginatorLabelOverride ={"next":"Next","prev":"Previous","goto":"Go to page"};
    connectedCallback() 
    {
    // console.log("this.additionalFilter",this.additionalFilter);

    
    }

    get aggrementText1()
    {
        return this.contractTemplate==undefined?'': this.contractTemplate.split("<!--section-->")[0];
    }
    get aggrementText2()
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[1];
    }  
    get isCatBase()
    {
        return this.isCatBaseContract;
    }
    get isItemBase()
    {
        return this.isItemBaseContract;
    }
    //SB 04.04.2023 US-0013014 - [IT] Display Coupon T&Cs on coupon contract in collapsible menu + PDF Download 
    get aggrementText3()
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[2];
    }
    get iconMenuCollape()
    {
        return this.isShowMenuCollape ? "utility:chevronup" : "utility:chevrondown";
    }
    get displayMenuCollape()
    {
        return this.isShowMenuCollape;
    }
    onShowMenuCollape()
    {
        this.isShowMenuCollape = !this.isShowMenuCollape;
    }
}