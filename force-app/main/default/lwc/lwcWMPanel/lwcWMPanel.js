/*********************************************************************************************************************************
@ Class:          LwcWMPanel
@ Version:        1.0
@ Author:         Vadhanak Voun (vadhanak.voun@gaea-sys.com)
@ Purpose:        US-0014270 - HoneyComb Work Manager
----------------------------------------------------------------------------------------------------------------------------------
@ Change history: 10.06.2023 / Vadhanak Voun / Created the class. 
@               : 08.03.2024 / Vadhanak Voun / US-0014902 - HoneyComb Work Manager - part3
@               : 22.03.2024 / Vadhanak Voun / US-0014986 - To be able to Hide Current Sprint Panel on the Hive Work Manager
@               : 28.03.2024 / Vadhanak Voun / US-0015027 - Hive Work Manager - User Story Prioritization Enhancement
@               : 25.11.2024 / Vadhanak Voun / US-0016305 - Sorting in the Hive Work Manager doesn't work
*********************************************************************************************************************************/
import { LightningElement,api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import apexGetRecordsPanel from '@salesforce/apex/WorkManagerHIVE.getRecordsPanel';
export default class LwcWMPanel extends NavigationMixin(LightningElement) {

    actions = [
        { label: 'View', name: 'view' },
        { label: 'Edit', name: 'edit' },
    ];
    rowBtnAttr = {
        type: 'action',
        typeAttributes: { rowActions: this.actions },
    }
    // rowBtnAttr = {
    //     type:"button",
    //     fixedWidth: 50,        
    //     typeAttributes: {
    //         label: 'Edit',
    //         title:'Edit',
    //         name: 'edit',
    //         variant:'base',
    //         // iconName:'utility:edit'
            
    //     }
    // };

    //panel {"sortOrder":"","pType":"copado__Sprint__c","pId":"a3J19000000OagWEAS","min":"","max":"","columns":["copado__User_Story_Title__c","copado__Status__c","copado__Backburner_Rank__c"]}
    @api panel; //readonly from parent?
   // myPanel; //clone from panel (avoid read-only)
    @api panelIndex;
    @api wm_panel_cols; //from parent - field set
    @api curSprint;
    @api nextSprint;
    sprintOfPanel;
    
    @api pageInfo;
    allowRowDragInside = false; // allow row dra/drop within the same table (move up/down which is only for Backburner)    

    colHeader;     
    listRecords = [];
    mapHiddenRecord = {}; // to store row witht the hidden fields by id
    panelBtnDropState = false;    

    totalStory=0;
    totalPoint=0;
    totalDevPoint=0;
    totalQAPoint=0;

    panelFieldLabel = "";
    panelFieldValue = "";
    panelApiName;

    dragStart;
    dragOverOld=null;
    dragOld2; //dragOverOld but from original panel 

    connectedCallback() 
    { 
    
        // this.curSprintId = (this.curSprint==null?'na':this.curSprint.Id);
        // this.nextSprintId = (this.nextSprint==null?'na':this.nextSprint.Id);      
        if(this.panel.panelName==="Current_Sprint")
        {
            this.sprintOfPanel = this.curSprint;
        }else if(this.panel.panelName==="Next_Sprint")
        {
            this.sprintOfPanel = this.nextSprint;
        }
        
        //NK:06/111/2023:US-0014370
        this.allowRowDragInside = true;//(this.panel.panelName==="Backburner");

                 
        this.getRecordPanels();
        
        
    }
    // disconnectedCallback() {
    //     
    //      
    // }
    renderedCallback()
    {
        this.handleColumResize();
         
    }
    //NK:08/03/2024:US-0014902
    get panelNumInfo()
    {
        //return 'Story: '+this.totalStory +', Point: '+ this.totalPoint;
        return 'Story: '+this.totalStory +', Final Points: '+ this.totalPoint +"\nDev Points: " + this.totalDevPoint +", QA Points: "+ this.totalQAPoint;
    }
    get panelLabel()
    {
       // return this.panelFieldLabel +' : '+ this.panelFieldValue;
       return this.panel.panelLabel +(this.sprintOfPanel?" ("+this.sprintOfPanel.Name+")":"");
    }
    get availableFields() //for drop down selection
    {
        let listFields = [];
        for(let i=0;i<this.wm_panel_cols.length;i++)
        {
            let isChecked = this.panel.columns.includes(this.wm_panel_cols[i].value);
            listFields.push(
                {label:this.wm_panel_cols[i].label, value:this.wm_panel_cols[i].value,checked: isChecked}
            );
        }

        //console.log("this.wm_panel_cols222",JSON.stringify(this.wm_panel_cols));
        //console.log("listFields",JSON.stringify(listFields));

        return listFields;
    }
    //query data for this panel
    getRecordPanels()
    {
        this.parentShowHideSpinner(true,'Refreshing Table');
        this.textSearch = "";
        this.hasChanged = false;
        // console.log("panel: pageInfo: ",JSON.stringify(this.pageInfo));
        // this.listData = [];

        // apexGetRecordsPanel({listFields:this.panel.columns, fieldNameCond:this.panel.pType,fieldValCon:this.panel.pId,sortOrder:this.panel.sortOrder})
        apexGetRecordsPanel({jsonPageInfo: JSON.stringify(this.pageInfo), jsonPanel: JSON.stringify(this.panel),sprintId:(this.sprintOfPanel?this.sprintOfPanel.Id:"na") })//NK:22/11/2023:US-0014446 -added na to make sure no data return
     
        .then(result => {
            // console.log("-getRecordPanels-",result);
           
            // [{label: 'User Story Reference', fieldName: 'Name', type: 'text'}]
            // this.colHeader = [ this.rowBtnAttr,...result.listFieldCol ];
            this.colHeader = [ ...result.listFieldCol ];            
            this.colHeader.map(colH => {
                if(colH.fieldName===this.panel.sortOrder)
                {
                    colH.sorted = true;
                }
            });

            //resolve Lookup field to Name with link
           this.listRecords = result.listRecords.map(row => {
                this.mapHiddenRecord[row.Id] = row;

                for (const [key, value] of Object.entries(row)) {
                    //console.log(`${key}: ${value}`);

                    let oneField = this.colHeader.find(o => o.fieldName === key);
                    
                    //console.log("oneField", oneField);
                    
                    if(oneField && oneField.type==='url')
                    {
                        // let relationshipName = oneField.relationshipName;
                        // let objRefVal = row[relationshipName];
                        // let valUrl = `/lightning/r/${objRefVal.Id}/view`;                        
                        // let valName = objRefVal.Name;
                       
                        // row[oneField.fieldName+'__ref'] = valName;
                        // row[oneField.fieldName+'__tooltip'] = valName;                        
                        // row[oneField.fieldName] = valUrl;                     
                        
                    }else if(oneField && oneField.isPkl)
                    {
                        row[oneField.fieldName] = row[oneField.fieldName+'__label']; //use picklist label instead of value
                    }

                }
            return {...row };
          });
          
          this.listDataSource = [...this.generateListData()]; //populate a new list with record + header + field type condition

          this.totalStory = result.totalStory?result.totalStory:0;
          this.totalPoint = result.totalPoint?result.totalPoint:0;
          this.panelFieldLabel = result.panelFieldLabel;
          this.panelFieldValue = result.panelFieldValue;

          //NK:08/03/2024:US-0014902
          this.totalDevPoint = result.totalPointDev?result.totalPointDev:0;
          this.totalQAPoint = result.totalPointQA? result.totalPointQA:0;
          
          
          // console.log("listRecords new: ",this.listRecords);
           this.parentShowHideSpinner(false);
        })
        .catch(error => {
           this.parentShowHideSpinner(false);
            console.log("getRecordPanels error",error);
        });

        
    }
    get isSortAsc()
    {
        return this.panel.sortOrderDir==="asc";
    }
    get isSortDesc()
    {
        return this.panel.sortOrderDir==="desc";
    }
    listData;
    listDataBackup = [];
    listDataSource = []; //after getRecordPanels. the original before adding or remove
    get listDataTable()
    {
        return this.listData;
    }
    generateListData()
    {
        //[{Id: 'a3c19000000HpPqAAK', copado__User_Story_Title__c: 'Story 1', copado__Status__c:'Approved'}]
        this.listData = [];
        if(!this.listRecords) return [];

        //console.log("this.colHeader",this.colHeader);
        for(let i=0;i<this.listRecords.length;i++)
        {
            let row = this.listRecords[i];
            let listColVal = [];
            let listFieldHidden = [];
            for(let j=0;j<this.colHeader.length;j++)
            {
                //{label: 'Title', fieldName: 'copado__User_Story_Title__c', type: 'text'}
                //{"label":"Owner ID","fieldName":"OwnerId","type":"url","typeAttributes":{"label":{"fieldName":"OwnerId__ref"},"tooltip":{"fieldName":"OwnerId__tooltip"},"target":"_blank"},"relationshipName":"Owner"}
                //{"Id":"a3c19000000HpPqAAK","copado__User_Story_Title__c":"Story 1","copado__Status__c":"Draft","Total_Story_Points__c":3,
                //"OwnerId":"/lightning/r/0053u000002puEBAAY/view","copado__Team__c":"a3R19000000cYoREAU","copado__Status__c__label":"Draft","Owner":{"Name":"vvv v","Id":"0053u000002puEBAAY"},"OwnerId__ref":"vvv v","OwnerId__tooltip":"vvv v"}
                let field = this.colHeader[j];
                let isUrl = field.type==='url';
                let isNum = field.type==='number';

                let isText = (field.type==='text' || (!isUrl && !isNum && !field.isPkl)); //add more for default type as text

                let objCol = {val:row[field.fieldName],index:i+'-'+j,isText:isText,isNum:isNum,isPkl:field.isPkl,isUrl:isUrl};
                if(isUrl && objCol.val)
                {
                    let objRef = row[field.relationshipName];
                    objCol.val = objRef.Name;
                    objCol.url = `/lightning/r/${objRef.Id}/view`;
                    // objCol.
                }else if(field.isPkl && objCol.val)
                {
                    objCol.val = row[field.fieldName+"__label"]

                }else if(field.fieldName==="Name" && objCol.val)
                {
                    objCol.url = `/lightning/r/${row["Id"]}/view`;
                    objCol.isUrl = true;
                    objCol.isText = false;
                    
                }
                listColVal.push(objCol); 
            }
            //NK:08/03/2024:US-0014902: record:row            
            this.listData.push({Id:row.Id,listColVal:listColVal,record:row});
        }
        this.listDataBackup = this.listData;
        //console.log("listData",this.listData);

        return this.listDataBackup;
        
        
    } 
    @api updatePageInfo(pageInfo)
    {
        this.pageInfo = pageInfo;
    }
    //from parent
    @api fireRefresh()
    {
        this.getRecordPanels();
    }

     
    handleRowAction(event)
    {
        // console.log(JSON.stringify(event.target.dataset));   
        let data = event.target.dataset;
        this[NavigationMixin.GenerateUrl]({
            type: 'standard__recordPage',
            attributes: {
                recordId: data.rowid,
                objectApiName: 'copado__User_Story__c',
                actionName: data.action
            }
        }).then(generatedUrl => {
            window.open(generatedUrl);
        });

    }

    //...NK:25/11/2024:US-0016305
    showHideColSelection(event)
    {
    //    let pageNum = event.target.dataset.pagenum;
        let divDrop = this.template.querySelector(`[data-panelname="drop-panel"]`);
       
       //console.log("showHideColSelection",JSON.stringify(event.target.dataset));
        
       let curBtnState = this.panelBtnDropState; //check menu drop down already display?
       curBtnState = curBtnState==null?false:curBtnState;

    //    console.log("curBtnState",curBtnState);

       if(curBtnState===true)
       {
            divDrop.classList.remove('slds-is-open');
       }else
       {
            divDrop.classList.add('slds-is-open'); 
       }

       this.panelBtnDropState = !curBtnState;
       
       //save panel name on the parent
       if(this.panelBtnDropState)
       {
            this.callParent({"action":"show_rm_field","pname":this.panel.panelName});
       }
       
       event.stopPropagation();
    }

    
    handleColumnAddRemove(event)
    {
        //{"btn":"btnDropDownField","pname":"copado__Sprint__c"}

        //console.log("handleColumnAddRemove currentTarget",JSON.stringify(event.currentTarget.dataset));        
        
        let btnData = event.currentTarget.dataset;

        this.parentAddRemoveField(btnData.fname);
        this.getRecordPanels();

        event.preventDefault();
    }

    callParent(actionDetail)
    {
        let ev = new CustomEvent('panelmethod',{detail : actionDetail});
        this.dispatchEvent(ev);                    
    }

    parentShowHideSpinner(state,msg)
    {
        this.callParent({"action":"spinner","state":state,"msg":msg});
    }
    parentAddRemoveField(fname)
    {
        //this.callParent({"action":"add_rm_field","fname":fname,"pindex":this.panelIndex});
        //NK:22/03/2024:US-0014986
        this.callParent({"action":"add_rm_field","fname":fname,"pname":this.panel.panelName});
        
    }

    @api showDropZone()
    {
        //console.log("@@@child showDropZone1" );
        this.template.querySelector(`[data-divid="${this.panel.panelName}"]`).classList.add("dropZone");
        //console.log("@@@child showDropZone2" );
    }
    @api hideDropZone()
    {

        this.template.querySelector(`[data-divid="${this.panel.panelName}"]`).classList.remove("dropZone");
    
    }
    // --handle drag drop----------------------------
    handleTRChange(event)
    {
       //console.log("handleTRChange",JSON.stringify(event.currentTarget.dataset));
    } 
    handleTRDragStart(event)
    {
        //slds-drop-zone slds-drop-zone_drag
        //console.log("handleTRDragStart: allowRowDragInside: "+ this.allowRowDragInside,JSON.stringify(event.currentTarget.dataset));
        this.dropAtBbnTable = false;
        this.dragStart = event.currentTarget.dataset;
        this.dragOverOld = JSON.parse(JSON.stringify(event.currentTarget.dataset));

        this.callParent({"action":"dragstart","from_panel":this.panel.panelName,"data":this.dragStart});
    }
    handleTRDragOver(event)
    {
        if(!this.allowRowDragInside)
        {
            return false;
        }

        event.preventDefault();

        const dragData = event.currentTarget.dataset;

        if(!this.dragStart)this.dragStart={}; // drag from other panel 
        
        //console.log("handleTRDragOver ","currentTarget.dataset: "+ JSON.stringify(event.currentTarget.dataset), "dragOverOld: "+JSON.stringify(this.dragOverOld)," dragStart: "+JSON.stringify(this.dragStart));

        if(this.dragStart.index !== dragData.index && !this.dragOverOld) //only once
        {
            this.addRemoveBlink(dragData.id,true);          

            this.dragOverOld = JSON.parse(JSON.stringify(dragData));
            
        }else if(this.dragOverOld && this.dragOverOld.index !== dragData.index)
        {
            this.addRemoveBlink(this.dragOverOld.id,false);
            this.addRemoveBlink(dragData.id,true);

            this.dragOverOld = JSON.parse(JSON.stringify(dragData));
             
        }else if(this.dragOverOld && this.dragStart.index === dragData.index)
        {
            //console.log("dragStar6",JSON.stringify(this.dragData));
            this.addRemoveBlink(this.dragStart.id,false);
        }        
        
        return false;
    }
    handleTRDrop(event)
    {
        //event.stopPropagation();
        this.dropAtBbnTable = true;
        const dragData = event.currentTarget.dataset;

       //console.log("handleTRDrop",this.panel.panelName); 

        this.removeAnyBlink();

        //let dragOld2 = JSON.parse(JSON.stringify(this.dragOverOld));
        this.dragOverOld = null;

        //console.log("handleTRDrop",JSON.stringify(event.currentTarget.dataset));

        this.callParent({"el":"tr","action":"drop","to_panel":this.panel.panelName,"dropatrow":dragData});
    }

    handleDragEnd(event)
    {
        //console.log("handleDragEnd cur: ",JSON.stringify(event.currentTarget.dataset)," dstart: "+JSON.stringify(this.dragStart));                
        this.callParent({"el":"tr","action":"dragend","from_panel":this.panel.panelName});
    }

    handlePanelDragEnd(event)
    {
        //console.log("handlePanelDragEnd cur: ",JSON.stringify(event.currentTarget.dataset)," dstart: "+JSON.stringify(this.dragStart));        
        this.callParent({"el":"panel","action":"dragend","from_panel":this.panel.panelName});
    }

    handlePanelDragOver(event)
    {
        event.preventDefault();        
    }

    handlePanelDrop(event)
    {
        //event.stopPropagation();

       //console.log("PanelDrop cur: ",JSON.stringify(event.currentTarget.dataset)," dstart: "+JSON.stringify(this.dragStart));
        
       this.callParent({"el":"panel","action":"drop","to_panel":this.panel.panelName});
       
        
        if(this.dragOverOld)
        {
            //this.addRemoveBlink(this.dragOverOld.id,false);
            this.removeAnyBlink();
        }
        //console.log("handlePanelDrop");
        
    }
    addRemoveBlink(id,toAdd)
    { 
        if(toAdd)
        {
            this.template.querySelector(`[data-id="${id}"]`).classList.add("dragOverTR"); //dragOver blinking
        }else
        {
            this.template.querySelector(`[data-id="${id}"]`).classList.remove("dragOverTR");
        }     
    }

    @api removeAnyBlink()
    {
        this.template.querySelectorAll(`.dragOverTR`).forEach(tr => {
            tr.classList.remove("dragOverTR");
        });
    }
    //----------------------------

    handleSort(event)
    {  
        event.preventDefault();

        //console.log("handleSort2",JSON.stringify(event.currentTarget.dataset));
         
        //NK:25/11/2024:US-0016305
        if(this.hasChanged || this.listDataSource.length !== this.listDataBackup.length)
        {
            let msg = "Please apply the changes before sorting.";
            this.callParent({"action":"showMessage",params:{state:true,type:"warning",message:msg,detail:"",duration:4000}});     
            return;
        }

        //NK:06/111/2023:US-0014370 - disabled sorting to allow drag/drop in all panels
        let sortField = event.currentTarget.dataset.fname
        let sortDir = '';
        if(this.panel.sortOrderDir==="")
        {
            sortDir = "asc";
        }else if(this.panel.sortOrderDir==="asc")
        {
            sortDir = "desc";
        }else if(this.panel.sortOrderDir==="desc")
        {
            sortDir = "asc";
        }
        //console.log("handleSort2aa");

        this.callParent({"action":"sort","from_panel":this.panel.panelName,"sortOrder":sortField,"sortDir":sortDir});        
    }
    
    @api getListIds()
    {
        let list1 = [];
        for(let i=0;i<this.listDataBackup.length;i++)
        {
            list1.push(this.listDataBackup[i].Id);
        }
        return list1;
    }
    @api removeItem(itemId)
    {
        let index = this.listDataBackup.findIndex(item => item.Id === itemId);
        // console.log("removeItem: "+index+" itemId: "+itemId);
        this.listDataBackup.splice(index, 1);
        this.listData = [];
        this.listData = this.listDataBackup;

        if(!this.isBlank(this.textSearch))
        {
            this.doSearch(this.textSearch);
        }

    }

    @api addItem(item)
    {
        this.listDataBackup.push(item);
        this.listData = [];
        this.listData = this.listDataBackup;
    }
    //only from other sprint to backburner
    @api addItemToIndex(item, index)
    {
        this.listDataBackup.splice(index, 0, item);
        this.listData = [];
        this.listData = this.listDataBackup;

    }
    @api getItemByItemId(itemId)
    {
        let foundItem = this.listDataBackup.find(item => item.Id === itemId);

        return foundItem;//this.listDataBackup[index];
    }
    get isDraggable()
    {
        //default draggable, once being search then not draggable due to the search result is not the original list
        return true;//this.listData.length===this.listDataBackup.length; //only allow drag if the list is not being search
    }
    //when search display different result, then not allow drag (up/down) anymore
     @api isSearching()
     {
        return this.listData.length!=this.listDataBackup.length;
     }
     @api focusSearch()
     {
        this.template.querySelector(`[data-pid="search_in_panel"]`).focus();
     }

    //afte drag drop, move up/down BBurner
    //NK:28/03/2024:US-0015027    
    @api swapItem(indexA, indexB) 
    {
        this.swapArrayElements(this.listData, indexA, indexB);
        let listBk = this.listData;  
        this.listData = [];
        this.listData = listBk;       
        
        this.listDataBackup = this.listData; //save the new list as backup  
        
        this.hasChanged = false;
        for(let i=0;i<this.listRecords.length;i++)
        {
            if(this.listDataBackup[i].Id != this.listRecords[i].Id)
            {
                this.hasChanged = true;
                break;
            }
        }

        this.reCalculateNumberInfo();

        //console.log(" hasChanged ", this.hasChanged);

        // console.log("swapItem A",JSON.stringify(this.listData[indexA]));
        // console.log("swapItem B",JSON.stringify(this.listData[indexB]));
        // if(this.listData[indexA].Id != this.listRecords[indexA].Id)
        // {
        //     this.template.querySelector(`[data-id="${this.listData[indexA].Id}"]`).classList.add("hasMoved");            

        // }else if(this.listData[indexA].Id === this.listRecords[indexA].Id)
        // {
        //     this.template.querySelector(`[data-id="${this.listData[indexA].Id}"]`).classList.remove("hasMoved"); 
        // }

        // if(this.listData[indexB].Id != this.listRecords[indexB].Id)
        // {
        //     this.template.querySelector(`[data-id="${this.listData[indexB].Id}"]`).classList.add("hasMoved");

        // }else if(this.listData[indexB].Id === this.listRecords[indexB].Id)
        // {
        //     this.template.querySelector(`[data-id="${this.listData[indexB].Id}"]`).classList.remove("hasMoved"); 
        // }
        
        
    }
    textSearch=null;
    handleSearchInPanel(event)
    {
        //[{Id:"xxxxxxx",listColVal:[{val: 'US-0014580', index: '7-0', isText: true, isNum: false, isPkl: undefined, …},{},..]}]
        const isEnterKey = event.keyCode === 13;
        if (isEnterKey)
        {
            let key = event.target.value;
            this.textSearch = key;
           // console.log("key: ",key);
            this.doSearch(key);
        }
    }
    doSearch(key)
    {
        if(key.trim().length>0)
        {
            let newArray = this.listDataBackup.filter((element, index, array) => {
                //console.log("---listColVal",JSON.stringify(element.listColVal));
                let listColVal = element.listColVal;
                // let foundOne = false;
                let found = listColVal.findIndex(
                    (data) => (
                        (data.isText || data.isUrl || data.isNum) && (data.val+'').toLowerCase().includes(key.toLowerCase())
                        )
                    );   

                // console.log("found ",found);    
                return found != -1;
             });
             //console.log("newArray: ",newArray.length);

             this.listData = newArray;                  
        }else 
        {
            this.listData = this.listDataBackup;                
        }

        this.reCalculateNumberInfo();

    }
    handleSearchChange(event)
    {
        let val = event.target.value;
        if(val.trim().length<=0)
        {
            this.listData = this.listDataBackup; 
            this.textSearch = null;
            this.reCalculateNumberInfo();
        }
        //this.textSearch = val;
    }
    
    //NK:28/03/2024:US-0015027
    //stop swapping but insert the item and push a row down
    swapArrayElements(arr, index1, index2) {
        // const temp = arr[index1];
        // arr[index1] = arr[index2];
        // arr[index2] = temp;
        
        const element = arr[index1];
        arr.splice(index1, 1); // Remove the element from its original position
        arr.splice(index2, 0, element); // Insert the element at the new position
    }

    hasChanged = false;
    //only for moving the sprint
    @api manageListChanged()
    {
        this.hasChanged = this.compareLists(this.listDataSource,this.listDataBackup);
        this.reCalculateNumberInfo();
    }

    get showApplyBtn()
    {
        return this.hasChanged;
    }

    handleApply(event)
    {
        console.log("handleApply");
        if(this.panel.panelName==="Backburner")
        {
            this.callParent({"action":"update_ranks","to_panel":this.panel.panelName});
            
        }else if(this.panel.panelName==="Current_Sprint" || this.panel.panelName==="Next_Sprint")
        {
            this.callParent({"action":"update_sprint","to_panel":this.panel.panelName});
        } 
        
    }

    handleColumResize()
    {
        this.template.querySelectorAll('.slds-is-resizable').forEach(td => {
            let startX, startWidth;
            //console.log("td ",td);
            td.addEventListener('mousedown', (event) => {
                startX = event.clientX;
                startWidth = parseInt(document.defaultView.getComputedStyle(td).width, 10);
                document.addEventListener('mousemove', handleMouseMove);
                document.addEventListener('mouseup', handleMouseUp);
            });

            const handleMouseMove = (event) => {
                const width = startWidth + event.clientX - startX;
                td.style.width = `${width}px`;
            };

            const handleMouseUp = () => {
                document.removeEventListener('mousemove', handleMouseMove);
                document.removeEventListener('mouseup', handleMouseUp);
            };
           
        });           
    }

    
    //check if the list2 has more item than list1src
    compareLists(list1src, list2) {
        if (list1src.length < list2.length) //more item than the original list? then something need to save
        {
            return true;
        }
    
        for (let i = 0; i < list2.length; i++) 
        {
            let foundItem = list1src.find(item => item.Id === list2[i].Id) ;
            if (foundItem===undefined)return true;            
        }
        return false;
    }

    //NK:08/03/2024:US-0014902
    reCalculateNumberInfo()
    {      
        this.totalStory = this.listData.length;
        //{Id: 'a3c7A000000hygnQAA', listColVal: Array(5)} 
        let fieldIndex = this.colHeader.findIndex((data) => data.fieldName === 'Total_Story_Points__c');
        // console.log("data: "+ JSON.stringify(this.listData));
        // console.log("listRecords: "+ JSON.stringify(this.listRecords));
        
        this.totalPoint = 0;
        this.totalDevPoint = 0;
        this.totalQAPoint = 0;
        //console.log("---fieldIndex: "+ fieldIndex);
        //if(fieldIndex != -1)
        //{
            //this.totalPoint = 0;
            this.listData.forEach((item,index) => {
                if(fieldIndex !== -1)
                {
                    this.totalPoint += parseFloat(item.listColVal[fieldIndex].val);    
                }
                //NK:08/03/2024:US-0014902
                if(item.record && item.record.Story_Points_Dev__c)
                {
                    this.totalDevPoint += parseFloat(item.record.Story_Points_Dev__c);
                }
                if(item.record && item.record.Story_Points_Test__c)
                {
                    this.totalQAPoint += parseFloat(item.record.Story_Points_Test__c);
                }
            });
        //}
       
    }
    isBlank(value) 
    {
        return (value === undefined || value === null )|| (value !=null && value.trim() === '');
    }

    // 
    // handleDocumentClick = (event) => {
    //     // const path = event.composedPath();
    //     console.log("dropPane0000000 ");
    //     console.log("dropPane currentTarget ",event.currentTarget );
    //     console.log("this.panel.panelName: ",this.panel.panelName);
    //     const dropPanel = this.template.querySelector(`[data-apiname="${this.panel.panelName}"]`);
       
    //     console.log("dropPanel: ",dropPanel);
        
    //     if (dropPanel && !dropPanel.contains(event.target) && event.target !== dropPanel) {
    //         console.log("--kk0 ");
    //         dropPanel.classList.remove('slds-is-open');
    
    //         console.log("--kk1 ");
    //     }
    // }

    //NK:25/11/2024:US-0016305
    @api closeDropDown(event)
    {
        const dropPanel = this.template.querySelector(`[data-apiname="${this.panel.panelName}"]`);
        if (dropPanel && !dropPanel.contains(event.target) && event.target !== dropPanel) 
        {           
            dropPanel.classList.remove('slds-is-open');
            this.panelBtnDropState = false;
        }
    }
     
}