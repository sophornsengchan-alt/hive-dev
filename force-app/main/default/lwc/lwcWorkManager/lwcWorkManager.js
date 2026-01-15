/*********************************************************************************************************************************
@ Class:          LwcWorkManager
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014270 - HoneyComb Work Manager
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 15.10.2023 / Vadhanak Voun / Created the class. 
@                 06.11.2023 / Vadhanak Voun / US-0014370 - HoneyComb Work Manager - part2
@                 22.11.2023 / Vadhanak Voun / US-0014446 - Honeycomb work manager is showing wrong next sprint
@                 22.03.2024 / Vadhanak Voun / US-0014986 - To be able to Hide Current Sprint Panel on the Hive Work Manager
@                 25.11.2024 / Vadhanak Voun / US-0016305 - Sorting in the Hive Work Manager doesn't work
*********************************************************************************************************************************/
import { LightningElement } from 'lwc';
import apexWorkManagerInit from '@salesforce/apex/WorkManagerHIVE.workManagerInit';
import apexWmMoveStory from '@salesforce/apex/WorkManagerHIVE.wmMoveStory';
import apexWmSaveSetting from '@salesforce/apex/WorkManagerHIVE.wmSaveSetting';

export default class LwcWorkManager extends LightningElement {
    FTYPE_MAPPING = {"STRING":"text","DOUBLE":"number","PICKLIST":"combo","REFERENCE":"lookup"};
    rowBtnAttr = {
        type:"button",
        fixedWidth: 80,
        typeAttributes: {
            label: 'Edit',
            name: 'edit',
            vaiant:''
        }
    };
    
    //NK:22/03/2024:US-0014986
    listViewPanelOptions = [];

    blockMessage = {showMessage:false,type:"",msg:"",msgDetail:""};    //,isError:function(){return this.type==="error"}

    current_page;
    panel_selected_field_name;
    panel_selected_field_val;

    current_field_panel_meta={};
    wm_page_options ;
    wm_panel_options;

    mapFieldPanelMeta={};

    wmData; //json data saved in User field: copado__Work_Manager_Panels__c
    currentWM={pWrappers:[]}; //current work manager 
    wm_panel_cols;
        
    DEFAULTLOADINGMSG = 'Loading...';
    loadingMsg ;
    showProgress  = true;
    // panelRecordData = []; //records for each panel

    panelBtnDropState = {};

    curSprint;
    nextSprint;

    pklComponentsFilter = [];
    filterCompoSelected = "none";
    filterHiveProSelected;

    mainFilter2 = ""; //saved filter for HIVE_Products__c
    mainFilter3 = ""; //save filter for Component__c
   
    
    userWMSetting = {lastVisitPage:null,userCols:[],hiddenPanels:{}}; //personal setting for each user 
    //called from panel
    dragStart;
    dropAt;
    dropAtBbnTable; //when drop on the Backurnner table then ignore the drop on Panel

    listCritProduct = [];
    listCritComponent = [];

    dropDownAtPanelName = {};   //name of panel that drop down is opened. sent from child
    connectedCallback() {
        //NK:25/11/2024:US-0016305
        document.addEventListener('click', this.handleDocumentClick);

        this.doInit(true);       

    }
    
    disconnectedCallback() 
    {
        //NK:25/11/2024:US-0016305
        // Remove event listener when component is destroyed
        document.removeEventListener('click', this.handleDocumentClick);
    }

    renderedCallback() {
        // this.filterCompoSelected = null;
        // this.filterHiveProSelected = null;
    }

    //when click outside the panel drop down
    closeAllDropDown(target)
    {
        // console.log("closeAllDropDown1",JSON.stringify(target)); 
     
       
        //if(target.dataset.btn==="btnDrop")return;

        //let divDrops = this.template.querySelectorAll(`[data-panelid="data-panelid"]`);
        // this.template.querySelectorAll('.drop-panel').forEach(element => {
        //     // element.classList.remove('slds-is-open');
        // });	

        
      
    }
    doInit(refreshSetting) {
        this.showHideSpinner(true,this.DEFAULTLOADINGMSG);
        // this.showHideMessage(false);
        
        this.pklComponentsFilter = [];
        apexWorkManagerInit()
        .then(result => {
            //console.log("-apexWorkManagerInit1-",result);
           this.wm_panel_cols = result.listFieldPage;
           this.wm_panel_options = result.listFieldPanel;       
           this.mapFieldPanelMeta=result.mapFieldPanelMeta;
           
           if(refreshSetting)
           {
                this.userWMSetting = JSON.parse(result.wmSetting==null?"{}":result.wmSetting);
           }          
           this.wmData = JSON.parse(result.wmData);
              
           if(this.isBlank(this.userWMSetting.lastVisitPage)) 
           {
                this.userWMSetting.lastVisitPage = this.wmData.defaultPage;  //set default page
           }

           this.current_page  = this.userWMSetting.lastVisitPage;
           this.userWMSetting.hiddenPanels  = (this.userWMSetting.hiddenPanels===undefined||this.userWMSetting.hiddenPanels===null)?{}:this.userWMSetting.hiddenPanels;

           this.curSprint = result.curSprint;
           this.nextSprint = result.nextSprint;
           //{label: 'Survey Vista', value: 'Clicktools', isActive: 'true', isDefaultValue: 'false'}
           this.pklComponentsFilter = [{label:'-NONE-',value:'none'},...result.pklComponentsFilter];

           this.setCurrentPageMeta();

           this.showHideSpinner(false);

           //console.log("-apexWorkManagerInit2-",result);

           //test msg
        //    this.showHideMessage(true,"success"," tst is completed successfully","",0);

        })
        .catch(error => {
            this.showHideSpinner(false);
            console.log("apexWorkManagerInit error",error);
            // this.showHideMessage(true,"error","this is a message","this is the detail");
        });
    }

    setCurrentPageMeta()
    {
        for(let i=0;i<this.wmData.panelData.length;i++)
        {
            if(this.wmData.panelData[i].pageInfo.pName==this.current_page)
            {
                this.currentWM = this.wmData.panelData[i];                        
                break;
            }
        }

        this.populateViewPanelOptions();
    }

    get wmPageOptions()
    {
        let listP = [];
        if(this.wmData==null) return listP;

        for(let i=0;i<this.wmData.panelData.length;i++)
        {
            listP.push({label:this.wmData.panelData[i].pageInfo.pLabel,value:this.wmData.panelData[i].pageInfo.pName});
        }
        return listP;
    }
    //NK:22/03/2024:US-0014986
    get wmPanelOfPage() //pWrappers
    {
        let listPanelShow = [];
        this.listViewPanelOptions.forEach(panel => {
            if(panel.visible)
            {
                let panelShow = this.currentWM.pWrappers.find(onePanel => onePanel.panelName === panel.name);
                listPanelShow.push(panelShow);
            }
        });
        const pNum = listPanelShow.length;
        const layoutItemSize = 12 / (pNum > 3 ? 3 : pNum);
        listPanelShow.map((item, index) => {
                item.classes = "slds-var-p-top_x-small slds-p-bottom--x-small ";
                item.classes += (index===pNum-1)?"":" slds-var-p-right_x-small ";
               item.layoutSize = layoutItemSize;
               return item;
              });

        return listPanelShow;
    }
   
   get progressMsg()
   {
        return this.loadingMsg;
   }  
   showHideSpinner(state,msg)
   {
        this.showProgress = state;
        this.loadingMsg = msg;       
   }
   //img spinner
   showHideSpinnerSmall(state)
   {
        this.template.querySelector('[data-id="small-spinner"]').classList.toggle('slds-hidden',!state);
   }
   
    handleWMPageChange(event)
    {
        //Work_Manager_Setting__c:	{"lastVisitPage":"Honeycomb_Work_Manager"}
        //console.log("handleWMPageChange1: ",event.detail.value);
        this.userWMSetting.lastVisitPage = event.detail.value;
        this.current_page = this.userWMSetting.lastVisitPage;        
        
        this.showHideSpinnerSmall(true);
        apexWmSaveSetting({jsonString:JSON.stringify(this.userWMSetting)}).then(result => {
            // console.log("saveSetting",result);
            this.showHideSpinnerSmall(false);
        }).catch(error => { 
            console.log("apexWmSaveSetting error",error);
            this.showHideSpinnerSmall(false);
        });
 
        this.setCurrentPageMeta();
 
        //clear all btn state
        this.panelBtnDropState = {};
        this.handleReset();

        this.handleRefresh();
      
    }
   
    handleNew(event)
    {

    }
    handleEdit(event)
    {

    }
    handleRemove(event)
    {

    }
    handleRefresh()
    {
        this.doInit(false);
        this.storeAndAssignFilters();
        this.refreshAllPanels();         
    }

    refreshAllPanels()
    {
        this.template.querySelectorAll("c-lwc-w-m-panel").forEach(panel => {
            panel.updatePageInfo(this.currentWM.pageInfo);
            panel.fireRefresh();
        });	
    }

    handleWMPanelChange(event)
    {
        this.panel_selected_field_name = event.detail.value;
        this.setFieldPanelMeta();

        console.log(this.current_field_panel_meta);

        console.log("lookup: ",this.isLookup);
    }
    handleKeyUpSelectedFieldVal(event)
    {

    }
    get isText()
    {
        return this.current_field_panel_meta.type=="STRING";
    }
    get isLookup()
    {
        return this.current_field_panel_meta.type=="REFERENCE" && this.current_field_panel_meta.referenceto !='RecordType';
    }
    get isNumber()
    {
        return this.current_field_panel_meta.type=="DOUBLE";
    }
    get isPicklist()
    {
        return this.current_field_panel_meta.type=="PICKLIST" ||  this.current_field_panel_meta.referenceto =='RecordType';
    }
    handlePanelFieldChange(event)
    {
        this.panel_selected_field_val = event.detail.value;
         
    }

    get pklFieldOption()
    {
        return this.mapFieldPanelMeta[this.panel_selected_field_name];
        
    }

    handleAddPanel(event)
    {

    }
    handleSearchInPanel()
    {

    }
    setFieldPanelMeta()
    {
        if(this.panel_selected_field_name !=null &&  this.wm_panel_options !=null)
        {
            for(let i=0;i<this.wm_panel_options.length;i++)
            {
                if(this.wm_panel_options[i].value==this.panel_selected_field_name) //fieldName
                {
                    this.current_field_panel_meta = this.wm_panel_options[i];
                }
            }
        }   
        
    }
    handleDropdownOutFocus(event)
    {
        //console.log("handleDropdownOutFocus",JSON.stringify(event.currentTarget.dataset));
        let dropnum = event.currentTarget.dataset.dropnum;
        let divDropPanel = this.template.querySelector(`[data-dropnum="${dropnum}"]`);
        divDropPanel.classList.remove('slds-is-open');
    }
  
    callFromChildPanel(event)
    {
        //console.log("callFromChildPanel",JSON.stringify(event.detail));

        let action = event.detail.action;
        if(action==="spinner")
        {
            this.showHideSpinner(event.detail.state,event.detail.msg);
        }else if(action==="add_rm_field")//NK:22/03/2024:US-0014986
        {
           let fname = event.detail.fname;
           let panelName = event.detail.pname;

            this.handleColumnAddRemove(fname,panelName);

        }else if(action==="dragstart")
        {
            //console.log("--showdropzone");
            this.dragStart = event.detail.data;
            this.dropAtBbnTable = false;
            this.showAllDropZones(event.detail.from_panel);
            
        }else if(action==="drop")
        {
            let from_panel = event.detail.from_panel;
            if(event.detail.el==="tr")
            {
                this.dropAtBbnTable = true;
                //console.log("drop table.....");
                this.moveTo("bbn",event.detail);

            }else if(event.detail.el==="panel" && !this.dropAtBbnTable)
            {
                //console.log("drop panel.....");
                this.moveTo("sprint",event.detail);
            } 

        }else if(action==="dragend")
        {
            //console.log("--dragend");
            this.hideAllDropZones();
            
        }else if(action==="sort")
        {
            // console.log("--sort");
        //     Backburner is stick with BBRank asc; we we can move up/down;
        //     not allowed sorting on Backburner panel
        //     NK:06/111/2023:US-0014370 - disabled all sorting. to allow backburner updated in all panels
        //     NK:25/11/2024:US-0016305 - allow sorting in all panels
        //    if(event.detail.from_panel !="Backburner")
        //    {
                this.sortRowInPanel(event.detail.sortOrder,event.detail.sortDir,event.detail.from_panel);
        //    }            
        }else if(action==="update_ranks")
        {
           // this.moveTo("bbn",event.detail);
           this.updateBBRanks();

        }else if(action==="update_sprint")
        {
          this.updateSprint(event.detail);

        }else if(action==="showMessage") //NK:25/11/2024:US-0016305
        {
            let msgParam = event.detail.params;
           this.showHideMessage(msgParam.state,msgParam.type,msgParam.message,msgParam.detail,msgParam.duration);

        }else if(action==="show_rm_field") //NK:25/11/2024:US-0016305
        {
            this.dropDownAtPanelName[event.detail.pname]=true;
        }
    

    } 
    updateBBRanks()
    {
            //console.log("bbn");
            //msgProgress="Updating Backburner Rank";
            let bbPanel = this.template.querySelector(`[data-pnameone="Backburner"]`);
            let listIds = bbPanel.getListIds();
            
            //console.log("listIds",listIds);            
           // bbPanel.swapItem(fromIndex,dropToIndex); 
            this.showHideSpinner(true,"Updating BackBuner Ranks");
            
            apexWmMoveStory({action:"update_bburner",toSprintId:null,listIds:listIds})
            .then(result => {                
               //console.log("-update_bburner-",result);
               if(result.status==="ok")
               {
                    this.handleRefresh();
                    this.showHideMessage(true,"success","BackBuner Ranks Updated","",4000);//error warning success
               }else
               {
                    this.showHideSpinner(false);
                    this.showHideMessage(true,"error",result.error,result.errorDetail);//error warning success 
               }
            })
            .catch(error => {
                this.showHideSpinner(false);
                console.log("update_bburner error",error);
            });
          
    } 
    moveTo(scope,data)
    {   
        //to panel:
        //dragStart: {"panel":"Backburner","id":"a3c7A000000hylQQAQ","index":"3"}
        // data:     {"el":"panel","action":"drop","to_panel":"Current_Sprint"}
        //==to table bbn:
        //dragStart: {"panel":"Current_Sprint","id":"a3c7A000000hylUQAQ","index":"2"} 
        //data:      {"el":"tr","action":"drop","to_panel":"Backburner","dropatrow":{"panel":"Backburner","id":"a3c7A000000hylPQAQ","index":"2"}}
        
       // console.log("moveTo scope: "+ scope+ " - dragStart: "+ JSON.stringify(this.dragStart)+"  --data:  "+ JSON.stringify(data));
        
        if(!this.dragStart)return;

        let fromPanelName = this.dragStart.panel;
        let toPanelName = data.to_panel;
        
        let itemId = this.dragStart.id; //recordId

        let panelFrom = this.template.querySelector(`[data-pnameone="${fromPanelName}"]`);
        let panelTo = this.template.querySelector(`[data-pnameone="${toPanelName}"]`);

        if(scope==="bbn" )
        {
            //console.log("moveTo in: fromPanelName: "+fromPanelName +" toPanelName: "+toPanelName );
            //NK:06/111/2023:US-0014370 - allow drag drop in all panels
            // if(fromPanelName === toPanelName && fromPanelName==="Backburner")//backburner ranking moving up/down
            if(fromPanelName === toPanelName)//backburner ranking moving up/down
            {
                //console.log("move to bnn aa");
                 
                if(panelFrom.isSearching())
                {
                    this.showHideMessage(true,"warning","Cannot move up/down when searching","",4000);
                    panelFrom.focusSearch();
                     
                }else
                {
                    let fromIndex = parseInt(this.dragStart.index);
                    //console.log("move to bnn 11aa - start");
                    let toIndex = parseInt(data.dropatrow.index);
                    panelTo.swapItem(fromIndex,toIndex);  //no need to manageListChanged()

                    //console.log("move to bnn 11 - done");
                }
                
            }else
            {   //moved to BackBurner and drop at table when searching
                if(panelTo.isSearching())
                {
                    this.showHideMessage(true,"warning","Cannot move to Backburner when searching","",4000);
                    panelTo.focusSearch();
                     
                }else
                {
                     //console.log("move to bnn 22aaa - start");
                    let toIndex = parseInt(data.dropatrow.index);            
                    let itemToMove = panelFrom.getItemByItemId(itemId);
                    panelTo.addItemToIndex(itemToMove,toIndex);        
                    panelFrom.removeItem(itemId);
                    
                    panelFrom.manageListChanged();
                    panelTo.manageListChanged();
                    //console.log("move to bnn 22 - done");
                }

               
            }

        }else if(scope==="sprint" && fromPanelName != toPanelName)
        {
            //REMOVE from sprint and move to Backburner
            // and drop at panel area
            if(toPanelName==="Backburner") 
            {
                //console.log("move to Backburner");

                let itemToMove = panelFrom.getItemByItemId(itemId);
                // let toIndex = parseInt(data.dropatrow.index);  
                panelTo.addItem(itemToMove);
                panelFrom.removeItem(itemId);
                
            }else if(toPanelName==="Current_Sprint") //move to other sprint
            {
                
                let itemToMove = panelFrom.getItemByItemId(itemId);
                panelTo.addItem(itemToMove);
                panelFrom.removeItem(itemId);

                //console.log("move to Current_Sprint - done");
            }
            else if(toPanelName==="Next_Sprint") //move to other sprint
            {
                // console.log("move to Next_Sprint - start: "+ itemId);

                let itemToMove = panelFrom.getItemByItemId(itemId);
                panelTo.addItem(itemToMove);
                panelFrom.removeItem(itemId);

                // console.log("move to Next_Sprint - done: "+ itemId);
            }   
            
            panelFrom.manageListChanged();
            panelTo.manageListChanged();
        }
    }

    updateSprint(data)
    {
        let toPanelName = data.to_panel;

        //to_sprint to_bburner update_bburner                  
        let sprintId;
        let msgProgress=""; 
       
        let panelTo = this.template.querySelector(`[data-pnameone="${toPanelName}"]`);
        let listIds = panelTo.getListIds();
        
        //console.log("listIds",listIds);      
      
        if(toPanelName==="Backburner")
        {
            sprintId = null;
            msgProgress="Moving to Backburner";

        }else if(toPanelName==="Current_Sprint")        
        {
            sprintId = this.curSprint.Id;
            msgProgress="Updating the Current Sprint";
            
        }else if(toPanelName==="Next_Sprint")
        {
            sprintId = this.nextSprint.Id;
            msgProgress="Updating the Next Sprint";
        }

        this.showHideSpinner(true,msgProgress);
            
        apexWmMoveStory({action:"to_sprint",toSprintId:sprintId,listIds:listIds})
        .then(result => {                
            //console.log("-updateSprint-",result);
            if(result.status==="ok")
            {
                this.handleRefresh(); 
                this.showHideMessage(true,"success",msgProgress+" is completed successfully","",4000);//error warning success
            }else
            {
                this.showHideMessage(true,"error",result.error,result.errorDetail);//error warning success 
                this.showHideSpinner(false);
            }
                     
        })
        .catch(error => {
            this.showHideSpinner(false);
            console.log("updateSprint error",error);
        });       
    }

    sortRowInPanel(sortField,sortDir,panelName)
    {
        for(let j=0;j<=this.currentWM.pWrappers.length;j++)
        {
            if(this.currentWM.pWrappers[j]==undefined)continue;
            if(this.currentWM.pWrappers[j].panelName===panelName)
            {
                this.currentWM.pWrappers[j].sortOrder = sortField;
                this.currentWM.pWrappers[j].sortOrderDir = sortDir;                    
                this.template.querySelector(`[data-pnameone="${panelName}"]`).fireRefresh();
                break;
            }
        }    
    }
    showAllDropZones(srcPanelName)
    {
        this.template.querySelectorAll("c-lwc-w-m-panel").forEach(panel => {                
            if(panel.panel.panelName !== srcPanelName)
            {
                panel.showDropZone();
                //console.log("--showdropzone11 panel.panel.panelName",panel.panel.panelName);
            }
            
        });	
    }
    hideAllDropZones()
    {
        this.template.querySelectorAll("c-lwc-w-m-panel").forEach(panel => {            
            panel.hideDropZone();
            panel.removeAnyBlink();            
        });	
    }
    handleFilterComponentChange(event)
    {
        console.log("handleFilterComponentChange detail",JSON.stringify(event.detail));
        // console.log("handleFilterComponentChange dataset",JSON.stringify(event.target.dataset));
        // console.log("handleFilterComponentChange filterHiveProSelected: "+ this.filterHiveProSelected +" filterCompoSelected: "+this.filterCompoSelected);
        // if(event.target.dataset.fname==="HIVE_Products__c") 
        // {            
        //     //{"value":["a6q19000000HjNWAA0"]}
        //     if(event.detail.value.length>0)
        //     {
        //         let val = event.detail.value[0]; //lookup field
                 
        //         this.currentWM.pageInfo.mainFilter2 = "HIVE_Products__c='"+val+"'";
        //         this.filterHiveProSelected = "HIVE_Products__c='"+val+"'";

        //         let pp = this.template.querySelector('[data-fname="HIVE_Products__c"]');
        //         //console.log("ppd",this.stringify(event));
              
        //     }else
        //     {                 
        //         this.currentWM.pageInfo.mainFilter2 = ""; 
        //         this.filterHiveProSelected = "";                
        //     }            
            
        // }else 
        if(event.target.dataset.fname==="Component__c")
        {
            // {"value":"Domo"}
            let val = event.detail.value;
            let item = this.pklComponentsFilter.find(element => element.value === val);
            if(item !=undefined && val !=="none")
            {
                if(this.listCritComponent.length===0)
                {
                    this.listCritComponent = [...this.listCritComponent, item];
                }else
                {
                    let index = this.listCritComponent.findIndex(item => item.value === val);
                    if(index===-1)  //do not add duplicate
                    {
                        this.listCritComponent = [...this.listCritComponent, item];
                    } 
                }
            }

            if(this.listCritComponent.length>0)
            {
                this.mainFilter3 = "Component__c IN (" + this.listCritComponent.map(item => "'" + item.value + "'").join(",") + ")";
                
            }else
            {
                this.mainFilter3 = "";
            }

            this.filterCompoSelected = val;             

        }   
        
        this.storeAndAssignFilters();

        this.refreshAllPanels();         
       
    }  
   
    
    get selectedComponent()
    {
        return this.filterCompoSelected;
    }
    get listProductCriteria()
    {
        return this.listCritProduct;
    }
    get listComponentCriteria()
    {
        return this.listCritComponent;
    }

    handleChildLookupMethod(event)
    {
        //console.log("handleChildLookupMethod",JSON.stringify(event.detail));
        //detail : {id:this.foundSelectedId,label:this.foundSelectedName}
        
        if(this.listCritProduct.length===0)
        {
            this.listCritProduct = [...this.listCritProduct, event.detail];
        }else
        {
            let index = this.listCritProduct.findIndex(item => item.id === event.detail.id);
            if(index===-1)  //do not add duplicate
            {
                this.listCritProduct = [...this.listCritProduct, event.detail];
            } 
        }
        
        if(this.listCritProduct.length>0)
        {
            this.mainFilter2 = "HIVE_Products__c IN (" + this.listCritProduct.map(item => "'" + item.id + "'").join(",") + ")";
            
        }else
        {
            
            this.mainFilter2 = "";
        }

        this.storeAndAssignFilters();

        this.refreshAllPanels();
        
        //console.log("listCritProduct",JSON.stringify(this.listCritProduct));
        //console.log("mainFilter2",JSON.stringify(this.currentWM.pageInfo.mainFilter2));
    }
    handleRemoveFilterProduct(event)
    {
        
        //console.log("handleRemoveFilterProduct dataset",JSON.stringify(event.currentTarget.dataset));
        let data = event.currentTarget.dataset;
        let index = this.listCritProduct.findIndex(item => item.id === data.id);
        if(index!==-1)  //do not add duplicate
        {
            this.listCritProduct = this.listCritProduct.toSpliced(index,1);
        } 

        if(this.listCritProduct.length>0)
        {
            this.mainFilter2 = "HIVE_Products__c IN (" + this.listCritProduct.map(item => "'" + item.id + "'").join(",") + ")";
             
        }else
        {
            this.mainFilter2 = "";
            this.template.querySelector('[data-id="lpk-product"]').reset();
        }

        this.storeAndAssignFilters();

        this.refreshAllPanels();

    }
    handleRemoveFilterComp(event)
    {
        //console.log("handleRemoveFilterComp dataset",JSON.stringify(event.currentTarget.dataset));
        //detail : {id: ,label: }
        
        let data = event.currentTarget.dataset;
        let index = this.listCritComponent.findIndex(item => item.id === data.id);
        if(index!==-1)  //do not add duplicate
        {
            this.listCritComponent = this.listCritComponent.toSpliced(index,1);
        } 

        if(this.listCritComponent.length>0)
        {
            this.mainFilter3 = "Component__c IN (" + this.listCritComponent.map(item => "'" + item.value + "'").join(",") + ")";
        }else
        {
            this.mainFilter3 = "";
            this.filterCompoSelected = "none";
        }
        
        this.storeAndAssignFilters();

        this.refreshAllPanels();
    }
    storeAndAssignFilters()
    {
        this.currentWM.pageInfo.mainFilter3 = this.mainFilter3;
        this.currentWM.pageInfo.mainFilter2 = this.mainFilter2;
    }

    handleReset()
    {
        this.mainFilter2 = "";
        this.mainFilter3 = "";
        this.listCritProduct = [];
        this.listCritComponent = [];
        this.filterCompoSelected = "none"; 
        this.template.querySelector('[data-id="lpk-product"]').reset();
        this.storeAndAssignFilters();
        this.refreshAllPanels();
    }
    isBlank(value) 
    {
        return (value === undefined || value === null )|| (value !=null && value.trim() === '');
    }
  
    handleColumnAddRemove(fname,pname)
    {
        //{"btn":"btnDropDownField","pname":"copado__Sprint__c"}
        //let cols = this.currentWM.pWrappers[pindex].columns;
        //NK:22/03/2024:US-0014986
        let cols = this.currentWM.pWrappers.find(panel => panel.panelName === pname).columns;
        let index = cols.indexOf(fname);
        if (index > -1) { // only splice array when item is found
            cols.splice(index, 1); // 2nd parameter means remove one item only

        }else
        {
            cols.push(fname);
        }
        this.storeAndAssignFilters();
    }
    panelViewChange(event)
    {
        //console.log("panelViewChange",JSON.stringify(event.target.dataset));
        const pname = event.target.dataset.pname;
        const pstate = event.target.dataset.pstate==="true"?true:false;
        //console.log("111q",JSON.stringify(this.userWMSetting.hiddenPanels));
        this.userWMSetting.hiddenPanels[pname] = !pstate;

        //NK:28/03/2024:US-0015027
        this.storeAndAssignFilters();

        this.populateViewPanelOptions();
    }
    //NK:22/03/2024:US-0014986
    populateViewPanelOptions()
    {
        if(!this.currentWM)return;
        //apexWmSaveSetting
        ////Work_Manager_Setting__c:	{"lastVisitPage":"Honeycomb_Work_Manager"}        
        // console.log("hiddenPanels",JSON.stringify(this.userWMSetting.hiddenPanels));
        let listP = [];
        for(let i=0;i<=this.currentWM.pWrappers.length;i++)
        {
            if(this.currentWM.pWrappers[i]===undefined)continue;
            let isVisible = this.checkVisible(this.currentWM.pWrappers[i].panelName);
            listP.push({label:this.currentWM.pWrappers[i].panelLabel,name:this.currentWM.pWrappers[i].panelName,visible:isVisible});
        }

        this.showHideSpinnerSmall(true);
        apexWmSaveSetting({jsonString:JSON.stringify(this.userWMSetting)}).then(result => {
            //console.log("saveSetting2",result);
            this.showHideSpinnerSmall(false);
        }).catch(error => { 
            console.log("apexWmSaveSetting error2",error);
            this.showHideSpinnerSmall(false);
        });
 

        this.listViewPanelOptions = [...listP];

        // console.log(JSON.stringify(this.listViewPanelOptions));
    }

    checkVisible(pName)
    {
        let isVisible = !this.userWMSetting.hiddenPanels?true:this.userWMSetting.hiddenPanels[pName];        
        return (isVisible==null?true:isVisible);
    }
    /***
        @param state: true/false
        @param type: error warning success 
        @param msg: message
        @param detail: detail message
    */
    showHideMessage(state,type,msg,detail,timeOut)
    {
        this.blockMessage.showMessage = state;
        this.blockMessage.type =  type
        this.blockMessage.msg = msg;
        this.blockMessage.msgDetail = detail;
        
        this.showMsg = state;

        let msgBlock = this.template.querySelector('c-lwc-message');
        
        if(msgBlock)
        {
            msgBlock.setMessage(this.blockMessage,state,timeOut);
        }
    }

    //NK:25/11/2024:US-0016305
    handleDocumentClick = (event) => 
    {         
        //console.log("panelName: ", this.dropDownAtPanelName);
        if (this.dropDownAtPanelName && Object.keys(this.dropDownAtPanelName).length > 0) 
        {
            for (const panelName in this.dropDownAtPanelName) 
            {
                if (Object.prototype.hasOwnProperty.call(this.dropDownAtPanelName, panelName)) 
                {
                    this.template.querySelector(`[data-pnameone="${panelName}"]`).closeDropDown(event);
                }
            }
            this.dropDownAtPanelName = {};
        }
        
    }
}