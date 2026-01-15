/**
 * change history:
 *      22.11.2022/ Loumang SENG /US-0012025 - [FR] Localization for Coupon Contract
 *                              /this component is specific for FR Coupon Contract - only for FR!
 */
import { LightningElement,track,api } from 'lwc';
import colHeaderCatBase from '@salesforce/label/c.HeadersOverride_CatBase';
import colHeaderItemBase from '@salesforce/label/c.HeadersOverride_ItemBase';
import FR_MenuCollape_Label from '@salesforce/label/c.FR_MenuCollape_Label';

export default class LwcContractFR_SEP extends LightningElement {
    @api isItemBaseContract;
    @api isCatBaseContract;
    @api contractTemplate;
    @api additionalFilter;
    isShowMenuCollape = false; // 15.12.2022 / Sophal Noch / US-0012903
   
    fieldsNoLink = ["Item_ID__c","Category_ID__c"]; 

    colHeaderCatBaseOverride = JSON.parse(colHeaderCatBase);
    colHeaderItemBaseOverride = JSON.parse(colHeaderItemBase);

    Labels = {FR_MenuCollape_Label} // 15.12.2022 / Sophal Noch / US-0012903

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

    get aggrementText3() // 15.12.2022 / Sophal Noch / US-0012903
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[2];
    }
    get aggrementText4() // 15.12.2022 / Sophal Noch / US-0012903
    {
        return this.contractTemplate==undefined?'':this.contractTemplate.split("<!--section-->")[3];
    }  
    get iconMenuCollape(){
        return this.isShowMenuCollape ? "utility:chevronup" : "utility:chevrondown";
    }
    get displayMenuCollape(){
        return this.isShowMenuCollape;
    }
    onShowMenuCollape(){
        this.isShowMenuCollape = !this.isShowMenuCollape;
    }

}