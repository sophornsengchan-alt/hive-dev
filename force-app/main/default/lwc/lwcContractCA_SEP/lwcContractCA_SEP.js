/**
 * change history:
 *      20.02.2023/ mony nou/ US-0012748 - [AU] Localization for Coupon Contract
 *                              /this component is specific for AU Coupon Contract - only for AU!
 */
import { LightningElement,track,api } from 'lwc';
import colHeaderCatBase from '@salesforce/label/c.HeadersOverride_CatBase';
import colHeaderItemBase from '@salesforce/label/c.HeadersOverride_ItemBase'

export default class LwcContractAU_SEP extends LightningElement {

    @api isItemBaseContract;
    @api isCatBaseContract;
    @api contractTemplate;
    @api additionalFilter;

    isShowAccordion = false;

    fieldsNoLink = ["Item_ID__c","Category_ID__c"]; 

    colHeaderCatBaseOverride = JSON.parse(colHeaderCatBase);
    colHeaderItemBaseOverride = JSON.parse(colHeaderItemBase);

    paginatorLabelOverride ={"next":"Next","prev":"Previous","goto":"Go to page"};

    connectedCallback() 
    {
       // console.log("this.additionalFilter",this.additionalFilter);
       //console.log("--colHeaderItemBaseOverride",this.colHeaderItemBaseOverride);
       
    }
   
    get aggrementText1()
    {
        return this.contractTemplate==undefined?'': this.contractTemplate.split("<!--section-->")[0];
    }
    get aggrementText2()
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[1];
    }  
  
    get termAndConditioins()
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[2];
    }
    get isCatBase()
    {
        return this.isCatBaseContract;
    }
    get isItemBase()
    {
        return this.isItemBaseContract;
    }

    get iconShowDetail(){
        return this.isShowAccordion ? "utility:chevronup" : "utility:chevrondown";
    }
    get displayDetail(){
        return this.isShowAccordion;
    }
    onShowDetail(){
        this.isShowAccordion = !this.isShowAccordion;
    }



}