/*********************************************************************************************************************************
@ Class:          lwcSEPToDoList
@ Author:         Patrick Duncan | patrick@triggdigital.com
@ Purpose:        US-0011799 - Refactor to-do list within Seller Portal
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 13/06/22 Patrick Duncan / Created componentsss
@                   22/07/2022 /Sovantheany Dim / US-0011674 - Display To-do List for NA Coupons tab
@                   06/09/2022/ vadhanak voun/ US-0012132 - Counter in the to-do should be dynamic
@                                           / disabled wired, add even listener
*********************************************************************************************************************************/
import { LightningElement, api, wire, track } from 'lwc';
import getToDoListItems from '@salesforce/apex/SEPToDoListController.getToDoListItems';
import cardHeader from '@salesforce/label/c.lwcSEPToDoList_Card_Header';
import hoverText from '@salesforce/label/c.lwcSEPToDoList_Hover_Text';
import noActionToDoMessage from '@salesforce/label/c.lwc_No_Outstanding_Actions';

export default class LwcSEPToDoList extends LightningElement {

    @api isAggregate;
    @api itemsToShow;
    @track toDoListItemsDTO;
    @track doShow;
    @track hasToDoListItem;
 
    label = {
        cardHeader,
        hoverText,
        noActionToDoMessage
    };

    //NK:06/09/2022:US-0012132 - disabled wired to allow refresh
    // @wire(getToDoListItems, { isAggregate: '$isAggregate', itemsToShow: '$itemsToShow'})
    // getToDoListItems({ error, data }) {
    //     if (data) {
    //         this.toDoListItemsDTO = data.filter(item => item.display == true);
    //         var sumOfItems = this.toDoListItemsDTO.reduce((accumulator, item) => 
    //             item.count + accumulator, 0);
    //         //TH:22/07/2022:US-0011674 - AC4: If there is no action to-do, show the below message 
    //         //this.doShow = this.itemsToShow && !this.toDoListItemsDTO.length == 0 && sumOfItems > 0;
    //         this.doShow = this.itemsToShow;
    //         this.hasToDoListItem = sumOfItems > 0;
    //     }
    //     else{
    //         if(this.itemsToShow){
    //             console.log('error ',error);
    //         }
    //         this.doShow = false;
    //     }
    // }

    loadCount() {
        getToDoListItems({ isAggregate: this.isAggregate, itemsToShow: this.itemsToShow})
            .then(data => {
                if (data) {
                    //console.log("data",data);

                    this.toDoListItemsDTO = data.filter(item => item.display == true);
                    var sumOfItems = this.toDoListItemsDTO.reduce((accumulator, item) => 
                        item.count + accumulator, 0);
                    //TH:22/07/2022:US-0011674 - AC4: If there is no action to-do, show the below message 
                    //this.doShow = this.itemsToShow && !this.toDoListItemsDTO.length == 0 && sumOfItems > 0;
                    this.doShow = this.itemsToShow;
                    this.hasToDoListItem = sumOfItems > 0;
                }
                else{
                    if(this.itemsToShow){
                        console.log('error ',error);
                    }
                    this.doShow = false;
                }

                
            })
            .catch(error => {
                this.doShow = false;
                console.log('error ',error);
            });
    }


    renderedCallback(){
        
        try{
            var className = 'slds-size_1-of-'+this.toDoListItemsDTO.length;
            this.template.querySelectorAll('.slds-col').forEach(function(col){
                col.classList.add(className)
            });
        }
        catch(err){}
        
        

    }
    connectedCallback()
    {
        window.addEventListener('message', this.receiveMessage);
        this.loadCount();
    }
    disconnectedCallback() {
        window.removeEventListener('message', this.receiveMessage);
    }

    receiveMessage = (event) => {
       // this.message = event.data
       //console.log("event.data",event.data.name);
       if(event.data.name=="refreshCount")
       {
            this.refreshCount();
       }
    }
     
    refreshCount() {
       // console.log("refreshing...");
        this.loadCount();
    }
    
    
}