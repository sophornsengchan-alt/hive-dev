/**
 * change history:
 *      05.11.2022/ vadhanak voun/US-0012034 - [UK] Localization for Coupon Contract
 *                              /this component is specific for UK Coupon Contract - only for UK!
 *      30.01.2023/ vadhanak voun/US-0013146 - UK Champion Testing Fixes
 */
import { LightningElement,track,api } from 'lwc';
import lblAccordionTitle from '@salesforce/label/c.AccordionTitle_Coupon_UK';
import colHeaderCatBase from '@salesforce/label/c.HeadersOverride_CatBase';
import colHeaderItemBase from '@salesforce/label/c.HeadersOverride_ItemBase';
import Seller_Share_Description from '@salesforce/label/c.Seller_Share_Description_Item_Base';
import Seller_Share_DescriptionCategory from '@salesforce/label/c.Seller_Share_Description';

export default class LwcContractUK_SEP extends LightningElement {
    @api isItemBaseContract;
    @api isCatBaseContract;
    @api contractTemplate;
    @api additionalFilter;
   
    fieldsNoLink = ["Item_ID__c","Category_ID__c"]; 

    isShowAccordion = false;
    //[{"fieldName":"Category_ID__c","label":"Kategorie ID","type":"STRING"},{"fieldName":"Category__c","label":"Kategorie","type":"STRING"},{"fieldName":"Co_Invest__c","label":"Erfolgsprämie (%) *","type":"PERCENT"}]
    Labels={lblAccordionTitle,Seller_Share_Description,Seller_Share_DescriptionCategory}

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