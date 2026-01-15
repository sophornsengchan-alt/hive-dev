/*********************************************************************************************************************************
@ Class:          LwcInputLookUp
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014370 - HoneyComb Work Manager - part2
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 07.11.2023 / Vadhanak Voun / Created the lwc. 
*********************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import apexDoSearch from '@salesforce/apex/LookupController.doSearch';
export default class LwcInputLookUp extends LightningElement {
    @api sobjectName;
    @api fieldName
    @api fieldLabel;
    @api variant;
    @api iconName;
    @api placeHolder;
 

    searchText = "";
    foundSelectedId;
    foundSelectedName;

 

    @api listFieldDisplayShort; // display on mini result as drop down
    @api listFieldDisplayFull; //when full search

    showModal =false;

    listResult=[];
    showDropResult = false;
    dropDownFocus = false;
    inputFocus = false;

    searching = false
 

    connectedCallback() 
    {
       this.handleDocClick();       
        
    }
    
   
    get searchTextValue()
    {
        return this.searchText;
    }
    get isSeaching()
    {
        return this.searching;
    }
    get showInput()
    {
        return this.isBlank(this.foundSelectedName);
    }
    get showClearBtn()
    {
        return !this.isBlank(this.searchText) && !this.searching;
    }
    // get showSearchIcon()
    // {
    //     return this.isBlank(this.searchText) && !this.searching;
    // }
    timer;
    prepareSearch()
    {
        this.searching = true;
        // console.log("prepareSearch");
        if(this.timer)
        {
            clearTimeout(this.timer);
        }
        this.timer = setTimeout(() => {
            // console.log("prepareSearch doSearch");
            this.doSearch();
        }, 500);
    }

    doSearch() {
        this.searching = true;
        apexDoSearch({sobjType:this.sobjectName,key:'%'+this.searchText+'%',displayEntity1:'Name',displayEntity2:'',displayEntity3:''})
        .then(result => {
            //  console.log("-doSearch-",result);
           this.listResult = result;
           //0: {displayEntity2: 'pro', entityId: 'search'}
           //1: {displayEntity1: 'Product 1 the very first product to be released this century', displayEntity2: '', displayEntity3: '', entityId: 'a6q7A000001dBxkQAE'}
           this.listResult.splice(0, 1);

           //this.showHideSpinner(false);

           if(this.listResult.length <=0)
           {
                this.listResult.push({displayEntity1: 'No Result Found', displayEntity2: '', displayEntity3: '', entityId: null});
           } 

        //    this.template.querySelector('[data-id="input-search"]').focus();
        // this.template.querySelector('[data-id="main-drop"]').focus();
        
        // this.dropDownFocus = true;
        // this.inputFocus = true;

        //    console.log("-doSearch-",this.listResult );
           this.searching = false;
        })
        .catch(error => {
            
            console.log("doSearch error",error);
            this.searching = false;
        });
    }
    handleClearSearch(event)
    {
        this.searchText = "";
        this.foundSelectedName = "";
        this.foundSelectedId = "";
    }

    get hasMore()
    {
        return this.listResult.length >=10;
    }
    showHideModal(state)
    {
        this.showModal = state;
    }
    handleCloseModal()
    {
        this.showHideModal(false);
    }
    handleFocus()
    {
        this.inputFocus = true;

        // setTimeout(() => {
        //     console.log("handleFocus!!!: searchText: "+this.searchText);
        //     this.inputFocus = true;

        //     // this.showDropResult = true;
        //     if(this.searchText !=null && this.searchText.length >=3)
        //     {
                    
        //             this.prepareSearch();

        //     }
        // }, 100);

        this.prepareSearch();

        
    }
    onLostFocus()
    {        
        
        setTimeout(() => { //delay to allow click on item
            // console.log("onLostFocus!!!");
            this.inputFocus  = false;            
        }, 200);
    }
    onInputChange(event)
    {
       this.searchText = event.detail.value;
    //    console.log("searchText--:"+ event.detail.value);

       if((!this.isBlank(this.searchText) && this.searchText.length >=3) || this.isBlank(this.searchText))
       {   
            this.inputFocus = true;
            this.prepareSearch();
       }
        
    //    console.log("searchText-showInput: "+ this.showInput );
    }
    onInputClick(event)
    {
        this.inputFocus = true;
        // console.log("onInputClick--:");
    }
    onItemClick(event)
    {
 
        // console.log("onItemClickc currentTarget",JSON.stringify(event.currentTarget.dataset));
        let data = event.currentTarget.dataset;
    
        if(!this.isBlank(data.id))
        {
            this.foundSelectedId = data.id;
            this.foundSelectedName = data.label;
            this.searchText = this.foundSelectedName;

            
            // this.template.querySelector('[data-id="input-search"]').value = this.foundSelectedName;

            this.listResult = [];

            let ev = new CustomEvent('childmethodlk', {action:"add",detail : {id:this.foundSelectedId,label:this.foundSelectedName}});
            this.dispatchEvent(ev);      

        }
        
        this.dropDownFocus = false;
        this.inputFocus = false;
        
    }
  
    // handleRemoveItem(event)
    // {
    //     console.log("handleRemoveItem:",JSON.stringify(event.currentTarget.dataset));
    //     let itemId = event.currentTarget.dataset.id;
    //     // let index = this.listSelected.findIndex(item => item.id === itemId);
    //     // this.listSelected = this.listSelected.toSpliced(index,1);

    //     let ev = new CustomEvent('childmethodlk', {action:"remove",detail : {id:itemId}});
    //     this.dispatchEvent(ev);      
         
    // }
    
    handleScroll(event)
    {
        // console.log("handleScroll!!!");
        this.dropDownFocus = true;
        this.template.querySelector('[data-id="main-drop"]').focus();
    }
    handleDropBlur(event){
        
        setTimeout(() => {
            // console.log("handleDropBlur");
            this.dropDownFocus = false;
        }, 1000);
        
    }

    get showResult()
    {
       return (this.inputFocus || this.dropDownFocus) && this.listResult.length >0;
    }

    get txtShowAllFor()
    {
        return "Show All Results for \""+this.searchText+"\"";
    }

    @api reset()
    {
        this.searchText = "";
        this.foundSelectedId = "";
        this.foundSelectedName = "";
    }

    @api getSelectRecordId()
    {
        return this.foundSelectedId;
    }

    isBlank(value) 
    {
        return (value === undefined || value === null )|| (value !=null && value.trim() === '');
    }

    handleDocClick()
    {
        document.addEventListener('click', (event) => {
            // console.log('Document was clicked: inputFocus: '+this.inputFocus+"   dropDownFocus: "+this.dropDownFocus);
            if(!this.inputFocus)
            {
                this.dropDownFocus = false; 
            }        
        });
    }
}